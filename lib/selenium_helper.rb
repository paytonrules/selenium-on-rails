require 'selenium_on_rails/suite_renderer'
require 'selenium_on_rails/fixture_loader'

module SeleniumHelper
  include SeleniumOnRails::SuiteRenderer
  include SeleniumOnRails::FixtureLoader

  def test_case_name filename
    File.basename(filename).sub(/\..*/,'').humanize
  end

end
