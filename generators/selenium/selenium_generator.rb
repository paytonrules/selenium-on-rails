class SeleniumGenerator < Rails::Generator::Base
  def initialize runtime_args, runtime_options = {}
    super
    usage if @args.empty?
  end

  def banner
    "Usage: #{$0} #{spec.name} testname [options]"
  end

  def manifest
    record do |m|
      path = 'test/selenium'
      path = File.join(path, suite_path) unless suite_path.empty?
      m.directory path

      template = (File.extname(filename) == '.rhtml' ? 'rhtml.rhtml' : 'selenese.rhtml')
      m.template template, File.join(path, filename)
    end
  end

  def filename
    name = File.basename args[0]
    name =  "#{name}.sel" unless ['.sel', '.rhtml'].include? File.extname(name)
    name
  end

  def suite_path
    sp = File.dirname args[0]
    sp = '' if sp == '.'
    sp
  end

  def testcase_link
    l = "http://localhost:3000/selenium/tests/"
    l = "#{l}#{suite_path}/" unless suite_path.empty?
    l + filename
  end

  def suite_link
    l = "http://localhost:3000/selenium"
    l = "#{l}/TestRunner.html?test=tests/#{suite_path}" unless suite_path.empty?
    l
  end
end
