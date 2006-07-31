require File.dirname(__FILE__) + '/paths'
require File.dirname(__FILE__) + '/../selenium_on_rails_config'
require 'net/http'


def c(var, default = nil) SeleniumOnRailsConfig.get var, default end
def c_b(var, default = nil) SeleniumOnRailsConfig.get(var, default) { yield } end

BROWSERS =              c :browsers, {}
REUSE_EXISTING_SERVER = c :reuse_existing_server, true
START_SERVER =          c :start_server, false  #TODO can't get it to work reliably on Windows, perhaps it's just on my computer, but I leave it off by default for now
PORTS =                 c(:port_start, 3000)..c(:port_end, 3005)
TEST_RUNNER_URL =       c :test_runner_url, '/selenium/TestRunner.html'
MAX_BROWSER_DURATION =  c :max_browser_duration, 2*60
SERVER_COMMAND =      c_b :server_command do
  server_path = File.expand_path(File.dirname(__FILE__) + '/../../../../../script/server')
  if RUBY_PLATFORM =~ /mswin/
    "ruby #{server_path} -p %d -e test > NUL 2>&1"
  else
    # don't use redirects to /dev/nul since it makes the fork return wrong pid
    # see UnixSubProcess
    "#{server_path} -p %d -e test"
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
        @server = start_subprocess(format(SERVER_COMMAND, @port))
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
        return unless defined? @server
        puts
        @server.stop 'server'
      end
    
      def start_browser browser, path
        puts
        puts "Starting #{browser}"
        log = log_file browser
        command = "\"#{path}\" \"http://localhost:#{@port}#{TEST_RUNNER_URL}?auto=true&resultsUrl=postResults/#{log}\""
        @browser = start_subprocess command    
        log_path log
      end
      
      def stop_browser
        @browser.stop 'browser'
      end
      
      def start_subprocess command
        if RUBY_PLATFORM =~ /mswin/
          SeleniumOnRails::AcceptanceTestRunner::Win32SubProcess.new command
        elsif RUBY_PLATFORM =~ /darwin/i && command =~ /safari/i
          SeleniumOnRails::AcceptanceTestRunner::SafariSubProcess.new command
        else
          SeleniumOnRails::AcceptanceTestRunner::UnixSubProcess.new command
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
        
  end
end

class SeleniumOnRails::AcceptanceTestRunner::SubProcess
  def stop what
    begin
      puts "Stopping #{what} (pid=#{@pid}) ..."
      Process.kill 9, @pid
    rescue Errno::EPERM #such as the process is already closed (tabbed browser)
    end
  end
end

class SeleniumOnRails::AcceptanceTestRunner::Win32SubProcess < SeleniumOnRails::AcceptanceTestRunner::SubProcess
  def initialize command
    require 'win32/open3' #win32-open3 http://raa.ruby-lang.org/project/win32-open3/

    puts command
    input, output, error, @pid = Open4.popen4 command, 't', true
  end
end

class SeleniumOnRails::AcceptanceTestRunner::UnixSubProcess < SeleniumOnRails::AcceptanceTestRunner::SubProcess
  def initialize command
    puts command
    @pid = fork do
      # Since we can't use shell redirects without screwing 
      # up the pid, we'll reopen stdin and stdout instead
      # to get the same effect.
      [STDOUT,STDERR].each {|f| f.reopen '/dev/null', 'w' }
      exec command
    end
  end
end

# A separate sub process for Safari since it cannot open an URL passed to it
# as command-line argument. 'open' is the way to open URLs on Mac OS X. The 
# drawback is that it doesn't provide the process id so it's not easy to close
# the process.
# The path to Safari should look like this: /Applications/Safari.app
class SeleniumOnRails::AcceptanceTestRunner::SafariSubProcess
  def initialize command
    command = "open -a #{command}"
    puts command
    fork { exec command }
  end
  
  def stop what
    close_safari = c_b :close_safari do
      puts "Set 'close_safari' to true in config.yml if you want Safari (with all its tabs!) to be closed automatically."
      false
    end
    if close_safari
      puts 'Stopping Safari'
      fork { exec 'killall Safari' }
    end
  end
end
  
