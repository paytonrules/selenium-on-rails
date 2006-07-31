require File.dirname(__FILE__) + '/paths'
require File.dirname(__FILE__) + '/../selenium_on_rails_config'
require 'net/http'


def c(var, default = nil) SeleniumOnRailsConfig.get var, default end
def c_b(var, default = nil) SeleniumOnRailsConfig.get(var, default) { yield } end

BROWSERS =              c :browsers, {}
REUSE_EXISTING_SERVER = c :reuse_existing_server, true
START_SERVER =          c :start_server, false  #TODO can't get it to work reliably, perhaps it's just on my computer, but I leave it off by default for now
PORTS =                 c(:port_start, 3000)..c(:port_end, 3005)
TEST_RUNNER_URL =       c :test_runner_url, '/selenium/TestRunner.html'
MAX_BROWSER_DURATION =  c :max_browser_duration, 2*60
SERVER_COMMAND =      c_b :server_command do
  server_path = File.expand_path(File.dirname(__FILE__) + '/../../../../../script/server')
  if RUBY_PLATFORM =~ /mswin/
    "ruby #{server_path} -p %d -e test > NUL 2>&1"
  else
    "#{server_path} -p %d -e test > /dev/nul 2>&1"
  end
end

module SeleniumOnRails
  class AcceptanceTestRunner
    include SeleniumOnRails::Paths
  
    def run
      raise 'no browser specified, edit/create config.yml' if BROWSERS.empty?
      start_server
      begin
        BROWSERS.each_pair do |browser, path|
          log_file = start_browser browser, path
          wait_for_completion log_file
          stop_browser
          print_result log_file
          File.delete log_file
        end
      rescue
        stop_server
        raise
      end
      stop_server
    end
    
    private
      def start_server
        PORTS.each do |p|
          @port = p
          case server_check
            when :success
              return if REUSE_EXISTING_SERVER
              next
            when Fixnum
              next
            when :no_response
              next unless START_SERVER
              do_start_server
              return
          end
        end
        raise START_SERVER ? 'failed to start server': 'failed to find existing server, run script/server -e test'
      end
      
      def do_start_server
        puts 'Starting server'
        @server_pid = start_subprocess(format(SERVER_COMMAND, @port))
        while true
          print '.'
          r = server_check
          if r == :success
            puts
            return
          end
          raise "server returned error: #{r}" if r.instance_of? Fixnum
          sleep 3
        end
      end
    
      def server_check
        begin
          res = Net::HTTP.get_response 'localhost', TEST_RUNNER_URL, @port
          return :success if (200..399).include? res.code.to_i
          return res.code.to_i
        rescue Errno::ECONNREFUSED
          return :no_response
        end
      end
    
      def stop_server
        return unless defined? @server_pid
        puts
        puts "Stopping server... (pid=#{@server_pid})"
        Process.kill 9, @server_pid
      end
    
      def start_browser browser, path
        puts
        puts "Starting #{browser}"
        log = log_file browser
        command = "\"#{path}\" \"http://localhost:#{@port}#{TEST_RUNNER_URL}?auto=true&resultsUrl=postResults/#{log}\""
        @browser_pid = start_subprocess command    
        log_path log
      end
    
      def stop_browser
        begin
          puts "Stopping browser (pid=#{@browser_pid}) ..."
          Process.kill 9, @browser_pid
        rescue Errno::EPERM #such as the process is already closed (tabbed browser)
        end
      end
    
      def log_file browser
        (0..100).each do |i|
          name = browser + (i==0 ? '' : "(#{i})") + '.yml'
          return name unless File.exist?(log_path(name))
        end
        raise 'there are way too many files in the log directory...'
      end
    
      def wait_for_completion log_file
        duration = 0
        while true
          raise 'browser takes too long' if duration > MAX_BROWSER_DURATION
          print '.'
          break if File.exist? log_file
          sleep 5
          duration += 5
        end
        puts
      end
    
      def print_result log_file
        result = YAML::load_file log_file
        puts "Finished in #{result['totalTime']} seconds."
        puts
        puts "#{result['numTestPasses']} tests passed, #{result['numTestFailures']} tests failed"
      end
    
      def start_subprocess command
        puts command
        input, output, error, pid = Open4.popen4 command, 't', true
        return pid
      end
    
  end
end

if RUBY_PLATFORM =~ /mswin/
  
  require 'win32/open3' #win32-open3 http://raa.ruby-lang.org/project/win32-open3/
  
  class SeleniumOnRails::AcceptanceTestRunner
    def start_subprocess command
      puts command
      input, output, error, pid = Open4.popen4 command, 't', true
      return pid
    end
  end
  
else
  
  class SeleniumOnRails::AcceptanceTestRunner
    def start_subprocess(command)
      puts command
      fork { exec command }
    end
  end
  
end
