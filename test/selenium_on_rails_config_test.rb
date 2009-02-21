require File.dirname(__FILE__) + '/test_helper'
require 'mocha'

class SeleniumOnRailsConfig
  def self.reset_config
    @@configs = nil
  end
end

class SeleniumOnRailsConfigTest < Test::Unit::TestCase
  
  def setup
    SeleniumOnRailsConfig.reset_config
    @selenium_file = File.join(RAILS_ROOT, 'config', 'selenium.yml')
    @selenium_content = File.read(File.dirname(__FILE__) + '/fixtures/selenium.yml')
  end

  def test_get_selenium_yaml
    File.expects(:exist?).with(@selenium_file).returns(true)
    IO.expects(:read).with(@selenium_file).returns(@selenium_content)
    assert_equal ["test_cache"], SeleniumOnRailsConfig.get(:environments)
    assert_equal({"firefox"=>"script/openfirefox"}, SeleniumOnRailsConfig.get(:browsers))
  end
  
end