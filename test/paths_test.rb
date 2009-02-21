require File.dirname(__FILE__) + '/test_helper'
require 'mocha'
RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + "/")

class SeleniumOnRails::PathsTest < Test::Unit::TestCase
  
  include SeleniumOnRails::Paths
  
  def test_selenium_tests_path_when_config_has_not_selenium_tests_path
    SeleniumOnRailsConfig.expects(:get).with("selenium_tests_path").returns(nil)
    assert_equal "#{RAILS_ROOT}/test/selenium", selenium_tests_path
  end
  
  def test_selenium_tests_path_when_config_has_selenium_tests_path
    SeleniumOnRailsConfig.expects(:get).with("selenium_tests_path").returns("path").at_least_once
    assert_equal "path", selenium_tests_path
  end
  
  def test_fixtures_path_when_config_has_not_fixtures_path
    SeleniumOnRailsConfig.expects(:get).with("fixtures_path").returns(nil)
    assert_equal "#{RAILS_ROOT}/test/fixtures", fixtures_path
  end
  
  def test_fixtures_path_when_config_has_fixtures_path
    SeleniumOnRailsConfig.expects(:get).with("fixtures_path").returns("path").at_least_once
    assert_equal "path", fixtures_path
  end
  
  def test_view_path
    assert_equal File.expand_path("#{RAILS_ROOT}/../lib/views/my_view"), view_path('my_view')
  end
  
  def test_layout_path
    assert_equal "layout.rhtml", layout_path
  end
  
end