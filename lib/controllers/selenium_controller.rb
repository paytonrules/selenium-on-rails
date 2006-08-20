class SeleniumController < ActionController::Base
  include SeleniumOnRails::FixtureLoader
  include SeleniumOnRails::Renderer

  def setup
    unless params.has_key? :keep_session
      reset_session
      @session_wiped = true
    end
    @cleared_tables = clear_tables params[:clear_tables].to_s
    @loaded_fixtures = load_fixtures params[:fixtures].to_s
    render :file => view_path('setup.rhtml'), :layout => layout_path
  end

  def test_file
    params[:testname] = '' if params[:testname].to_s == 'TestSuite.html'
    filename = File.join selenium_tests_path, params[:testname]
    if File.directory? filename
      @suite_path = filename
      render :file => view_path('test_suite.rhtml'), :layout => layout_path
    elsif File.readable? filename
      render_test_case filename
    else
      if File.directory? selenium_tests_path
        render :text => 'Not found', :status => 404
      else
        render :text => "Did not find the Selenium tests path (#{selenium_tests_path}). Run script/generate selenium", :status => 404
      end
    end
  end

  def support_file
    if params[:filename].empty?
      redirect_to :filename => 'TestRunner.html', :test => 'tests'
      return
    end

    filename = File.join selenium_path, params[:filename]
    if File.file? filename
      send_file filename, :type => 'text/html', :disposition => 'inline', :stream => false
    else
      render :text => 'Not found', :status => 404
    end
  end

  def record
    @result = {}
    for p in ['result', 'numTestFailures', 'numTestPasses', 'numCommandFailures', 'numCommandPasses', 'numCommandErrors', 'totalTime']
      @result[p] = params[p]
    end
    File.open(log_path(params[:logFile] || 'default.yml'), 'w') {|f| YAML.dump(@result, f)}
    
    render :file => view_path('record.rhtml'), :layout => layout_path
  end
end
