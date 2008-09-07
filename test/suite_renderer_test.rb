require File.dirname(__FILE__) + '/test_helper'

class SuiteRendererTest < Test::Unit::TestCase
  def setup
    @controller = SeleniumController.new
    ActionController::Routing::Routes.draw
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.layout_override =<<END
<html><head><title>test layout</title></head><body>
@content_for_layout
</body></html>
END
  end
  
  def test_empty_suite
    get :test_file, :testname => 'empty_suite'
    
    assert_response :success
    expected =<<END
<html><head><title>test layout</title></head><body>
<script type="text/javascript">
<!--
function openSuite(selector) {
  var suite = selector.options[selector.selectedIndex].value;
  if(suite == "header") return;
  if(top.location.href != location.href) //inside a frame
    top.location =  "/selenium/TestRunner.html?test=tests" + suite
  else
    window.location = "/selenium/tests" + suite
}
//-->
</script>
<select onchange="openSuite(this)">
  <option value="header">Suites:</option>
  <option value="">..</option>
</select>

<table>
  <tr><th>Empty suite</th></tr>
</table>
</body></html>
END
    assert_text_equal expected, @response.body
  end

  
  def test_root_suite
    _test_root_suite ''
  end
  
  def test_test_suite_html
    #TestSuite.html is the default name the Selenium Runner tries to run
    _test_root_suite 'TestSuite.html'
  end
  
  def _test_root_suite testname
    get :test_file, :testname => testname
    assert_response :success
    
    assert_tag :tag => "title", :content => "test layout"
    assert_tag :tag => "script", :attributes => {:type => "text/javascript"}
    assert_tag :tag => "select", :attributes => {:onchange => "openSuite(this)"}, 
               :descendant => {:tag => "option", :attributes => {:value => "header"}, :content => "Suites:"},
               :descendant => {:tag => "option", :attributes => {:value => "/partials"}, :content => "Partials"},
               :descendant => {:tag => "option", :attributes => {:value => "/suite_one"}, :content => "Suite one"},
               :descendant => {:tag => "option", :attributes => {:value => "/suite_two"}, :content => "Suite two"},
               :descendant => {:tag => "option", :attributes => {:value => "/suite_one/subsuite"}, :content => "Suite one.Subsuite"}
               
    assert_tag :tag => "table",
              :descendant => {:tag => "th", :content => "All test cases"},
              :descendant => {:tag => "td", :content => "Html"},
              :descendant => {:tag => "td", :content => "Own layout"},
              :descendant => {:tag => "td", :content => "Rhtml"},
              :descendant => {:tag => "td", :content => "Rselenese"},
              :descendant => {:tag => "td", :content => "Selenese"},
              :descendant => {:tag => "td", :content => "Partials.All partials"},
              :descendant => {:tag => "td", :content => "Suite one.Suite one testcase1"},
              :descendant => {:tag => "td", :content => "Suite one.Suite one testcase2"},
              :descendant => {:tag => "td", :content => "Suite one.Subsuite.Suite one subsuite testcase"},
              :descendant => {:tag => "td", :content => "Suite two.Suite two testcase"}
  end

  def test_suite_one
    get :test_file, :testname => 'suite_one'
    assert_response :success
    expected =<<END
<html><head><title>test layout</title></head><body>

<script type="text/javascript">
<!--
function openSuite(selector) {
  var suite = selector.options[selector.selectedIndex].value;
  if(suite == "header") return;
  if(top.location.href != location.href) //inside a frame
    top.location =  "/selenium/TestRunner.html?test=tests" + suite
  else
    window.location = "/selenium/tests" + suite
}
//-->
</script>
<select onchange="openSuite(this)">
  <option value="header">Suites:</option>
  
  <option value="">..</option>
  
  <option value="/suite_one/subsuite">Subsuite</option>
  
</select>

<table>
  <tr><th>Suite one</th></tr>
  
  <tr><td><a href="/selenium/tests/suite_one/suite_one_testcase1.sel">Suite one testcase1</a></td></tr>
  
  <tr><td><a href="/selenium/tests/suite_one/suite_one_testcase2.sel">Suite one testcase2</a></td></tr>
  
  <tr><td><a href="/selenium/tests/suite_one/subsuite/suite_one_subsuite_testcase.sel">Subsuite.Suite one subsuite testcase</a></td></tr>
  
</table>
</body></html>
END
    assert_text_equal expected, @response.body
  end
  
  def test_sub_suite
    get :test_file, :testname => 'suite_one/subsuite'
    assert_response :success
    expected =<<END
<html><head><title>test layout</title></head><body>

<script type="text/javascript">
<!--
function openSuite(selector) {
  var suite = selector.options[selector.selectedIndex].value;
  if(suite == "header") return;
  if(top.location.href != location.href) //inside a frame
    top.location =  "/selenium/TestRunner.html?test=tests" + suite
  else
    window.location = "/selenium/tests" + suite
}
//-->
</script>
<select onchange="openSuite(this)">
  <option value="header">Suites:</option>
  
  <option value="/suite_one">..</option>
  
</select>

<table>
  <tr><th>Subsuite</th></tr>
  
  <tr><td><a href="/selenium/tests/suite_one/subsuite/suite_one_subsuite_testcase.sel">Suite one subsuite testcase</a></td></tr>
  
</table>
</body></html>
END

    assert_text_equal expected, @response.body
  end
  
  def test_missing_tests_directory
    def @controller.selenium_tests_path
      File.join(File.dirname(__FILE__), 'invalid')
    end
    get :test_file, :testname => ''
    assert_response 404
    assert_equal "Did not find the Selenium tests path (#{File.join(File.dirname(__FILE__), 'invalid')}). Run script/generate selenium",  @response.body
  end
  
end
