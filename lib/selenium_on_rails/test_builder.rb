# The actions available for SeleniumOnRails::TestBuilder tests.
module SeleniumOnRails::TestBuilderActions
  # Tell Selenium on Rails to clear the session and load any fixtures.  DO
  # NOT CALL THIS AGAINST NON-TEST DATABASES.
  # The supported +options+ are <code>:keep_session</code> and <code>:fixtures</code>
  #   setup
  #   setup :keep_session
  #   setup :fixtures => :all
  #   setup :keep_session, :fixtures => [:foo, :bar]
  def setup options = {}
    options = {options => nil} unless options.is_a? Hash

    opts = {:controller => 'selenium', :action => 'setup'}
    opts[:keep_session] = true if options.has_key? :keep_session

    if (f = options[:fixtures])
      f = [f] unless f.is_a? Array
      opts[:fixtures] = f.join ','
    end

    open opts
  end

  # Includes a partial.
  # The path is relative to the Selenium tests root. The starting _ and the file
  # extension doesn't have to be specified.
  #   #include test/selenium/_partial.*
  #   include_partial 'partial'
  #   #include test/selenium/suite/_partial.*
  #   include_partial 'suite/partial'
  #   #include test/selenium/suite/_partial.* and provide local assigns
  #   include_partial 'suite/partial', :foo => bar
  def include_partial path, local_assigns = {}
    partial = @view.render :partial => path, :locals => local_assigns
    @output << partial
  end

  # Open the page specified by +url+ and wait.  The +url+ may either by a
  # string, or arguments suitable for <code>ActionView::UrlHelper#url_for</code>.
  #   open '/'
  #   open :controller => 'customer', :action => 'list'
  def open url
    command 'open', url_arg(url)
  end

  # Click on the specified element.  Supports a <code>:wait => true</code>
  # option.
  def click element_locator, options={}
    command name_with_optional_wait('click', options), element_locator
  end

  # Type +value+ into the specified element.  Supports a <code>:wait =>
  # true</code> option, which is useful if typing into the field causes
  # another page to be loaded.
  def type input_locator, value, options={}
    command name_with_optional_wait('type', options), input_locator, value
  end

  # Select an option from a +select+ menu.  Supports a <code>:wait =>
  # true</code> option.
  def select drop_down_locator, option_specifier, options={}
    command(name_with_optional_wait('select', options), drop_down_locator,
            option_specifier)
  end

  # Select a popup window by name, and send further commands to it.  If
  # +window_id+ is +nil+, select the main window.
  def select_window window_id
    command 'selectWindow', window_id||'null'
  end

  # Simulate selecting the "Back" button.
  def go_back
    command 'goBack'
  end

  # Close the current window.
  def close
    command 'close'
  end

  # Wait for +milliseconds+.
  def pause milliseconds
    command 'pause', milliseconds
  end

  # Send an event to an element.
  #   fire_event 'password', 'focus'
  def fire_event element_locator, event_name
    command 'fireEvent', element_locator, event_name
  end

  # Wait for an input field to have the specified value.
  def wait_for_value input_locator, value
    command 'waitForValue', input_locator, value
  end

  # Store a value into a Selenium value.
  def store value_to_store, variable_name
    command 'store', value_to_store, variable_name
  end

  # Store the value of an input field into a Selenium variable.
  def store_value input_locator, variable_name
    command 'storeValue', input_locator, variable_name
  end

  # Store the text of an element into a Selenium variable.
  def store_text element_locator, variable_name
    command 'storeText', element_locator, variable_name
  end

  # Store the value of an attribute into a Selenium variable.
  def store_attribute element_locator, attribute_name, variable_name
    command('storeAttribute', "#{element_locator}@#{attribute_name}",
            variable_name)
  end

  # Tell Selenium to select "Cancel" the next time a confirmation dialog
  # appears.
  def choose_cancel_on_next_confirmation
    command 'chooseCancelOnNextConfirmation'
  end

  # Tell Selenium how to answer the next JavaScript prompt.
  def answer_on_next_prompt answer_string
    command 'answerOnNextPrompt', answer_string
  end

end


# The checks available for SeleniumOnRails::TestBuilder tests.
#
# For each check there exist an +assert+ and a +verify+ version.
# <code>assert</code>s stop the execution of the test, whereas
# <code>verify</code>s don't.
module SeleniumOnRails::TestBuilderChecks
  # Assert that the browser is at the specified location.
  #   assert_location '/'
  #   assert_location :controller => 'customer', :action => 'list'
  def assert_location relative_location
    command 'assertLocation', url_arg(relative_location)
  end
  # Verify that the browser is at the specified location.
  #   verify_location '/'
  #   verify_location :controller => 'customer', :action => 'list'
  def verify_location relative_location
    command 'verifyLocation', url_arg(relative_location)
  end

  # Assert that the current page's title matches the pattern.
  def assert_title title_pattern
    command 'assertTitle', title_pattern
  end
  # Verify that the current page's title matches the pattern.
  def verify_title title_pattern
    command 'verifyTitle', title_pattern
  end

  # Assert the specified input field's value matches the pattern.
  def assert_value input_locator, value_pattern
    command 'assertValue', input_locator, value_pattern
  end
  # Verify the specified input field's value matches the pattern.
  def verify_value input_locator, value_pattern
    command 'verifyValue', input_locator, value_pattern
  end

  # Assert that a specific +option+ is chosen in a +select+ field.
  def assert_selected select_locator, option_specifier
    command 'assertSelected', select_locator, option_specifier
  end
  # Verify that a specific +option+ is chosen in a +select+ field.
  def verify_selected select_locator, option_specifier
    command 'verifySelected', select_locator, option_specifier
  end

  # Assert that a +select+ field has the specified option labels.
  def assert_select_options select_locator, *option_label_list
    ls = option_label_list.map {|l| l.gsub(/[\\,]/) {|s| "\\#{s}" } }.join(',')
    command 'assertSelectOptions', select_locator, ls
  end
  # Verify that a +select+ field has the specified option labels.
  def verify_select_options select_locator, *option_label_list
    ls = option_label_list.map {|l| l.gsub(/[\\,]/) {|s| "\\#{s}" } }.join(',')
    command 'verifySelectOptions', select_locator, ls
  end

  # Assert that an element contains the specified text.
  def assert_text element_locator, text_pattern
    command 'assertText', element_locator, text_pattern
  end
  # Verify that an element contains the specified text.
  def verify_text element_locator, text_pattern
    command 'verifyText', element_locator, text_pattern
  end

  # Assert that an attribute contains the specified text.
  def assert_attribute element_locator, attribute_name, value_pattern
    command('assertAttribute', "#{element_locator}@#{attribute_name}",
            value_pattern)
  end
  # Verify that an attribute contains the specified text.
  def verify_attribute element_locator, attribute_name, value_pattern
    command('verifyAttribute', "#{element_locator}@#{attribute_name}",
            value_pattern)
  end

  # Assert that the specified text is present somewhere on the page.
  def assert_text_present text
    command 'assertTextPresent', text
  end
  # Verify that the specified text is present somewhere on the page.
  def verify_text_present text
    command 'verifyTextPresent', text
  end

  # Assert that the specified text is not present anywhere on the page.
  def assert_text_not_present text
    command 'assertTextNotPresent', text
  end
  # Verify that the specified text is not present anywhere on the page.
  def verify_text_not_present text
    command 'verifyTextNotPresent', text
  end

  # Assert that the specified element appears on the page.
  def assert_element_present element_locator
    command 'assertElementPresent', element_locator
  end
  # Verify that the specified element appears on the page.
  def verify_element_present element_locator
    command 'verifyElementPresent', element_locator
  end

  # Assert that the specified element does not appear on the page.
  def assert_element_not_present element_locator
    command 'assertElementNotPresent', element_locator
  end
  # Verify that the specified element does not appear on the page.
  def verify_element_not_present element_locator
    command 'verifyElementNotPresent', element_locator
  end

  # Assert that the specified table cell contains the specified value.
  def assert_table table_locator, row, column, value_pattern
    command 'assertTable', "#{table_locator}.#{row}.#{column}", value_pattern
  end
  # Verify that the specified table cell contains the specified value.
  def verify_table table_locator, row, column, value_pattern
    command 'verifyTable', "#{table_locator}.#{row}.#{column}", value_pattern
  end

  # Assert that the specified element is visible.  Checks the
  # +visibility+ and +display+ properties of the
  # element and its parents.
  def assert_visible element_locator
    command 'assertVisible', element_locator
  end
  # Verify that the specified element is visible.  Checks the
  # +visibility+ and +display+ properties of the
  # element and its parents.
  def verify_visible element_locator
    command 'verifyVisible', element_locator
  end

  # Assert that the specified element is not visible (or is entirely
  # missing).
  def assert_not_visible element_locator
    command 'assertNotVisible', element_locator
  end
  # Verify that the specified element is not visible (or is entirely
  # missing).
  def verify_not_visible element_locator
    command 'verifyNotVisible', element_locator
  end

  # Assert that the specified element can be edited.
  def assert_editable input_locator
    command 'assertEditable', input_locator
  end
  # Verify that the specified element can be edited.
  def verify_editable input_locator
    command 'verifyEditable', input_locator
  end

  # Assert that the specified element cannot be edited.
  def assert_not_editable input_locator
    command 'assertNotEditable', input_locator
  end
  # Verify that the specified element cannot be edited.
  def verify_not_editable input_locator
    command 'verifyNotEditable', input_locator
  end

  # Assert the message of the next alert matches the pattern.
  def assert_alert message_pattern
    command 'assertAlert', message_pattern
  end
  # Verify the message of the next alert matches the pattern.
  def verify_alert message_pattern
    command 'verifyAlert', message_pattern
  end

  # Assert the message of the next confirmation matches the pattern.
  def assert_confirmation message_pattern
    command 'assertConfirmation', message_pattern
  end
  # Verify the message of the next confirmation matches the pattern.
  def verify_confirmation message_pattern
    command 'verifyConfirmation', message_pattern
  end

  # Assert the message of the next prompt matches the pattern.
  def assert_prompt message_pattern
    command 'assertPrompt', message_pattern
  end
  # Verify the message of the next prompt matches the pattern.
  def verify_prompt message_pattern
    command 'verifyPrompt', message_pattern
  end

end


# Builds Selenium test table using a high-level Ruby interface. Normally
# invoked through SeleniumOnRails::RSelenese.
#
# See SeleniumOnRails::TestBuilderActions for the available actions and
# SeleniumOnRails::TestBuilderChecks for the available checks.
#
# For more information on the commands supported by TestBuilder, see the
# Selenium Commands Documentation at
# http://www.openqa.org/selenium/seleniumReference.html.
class SeleniumOnRails::TestBuilder
  include SeleniumOnRails::TestBuilderActions
  include SeleniumOnRails::TestBuilderChecks

  # Convert _str_ to a Selenium command name.
  def self.selenize(str)
    str.camelize.gsub(/^[A-Z]/) {|s| s.downcase }
  end

  # Create a new TestBuilder for _view_.
  def initialize view
    @view = view
    @output = ''
    @xml = Builder::XmlMarkup.new :indent => 2, :target => @output
  end

  # Add a new table of tests, and return the HTML.
  def table title
    @xml.table do
      @xml.tr do @xml.th(title, :colspan => 3) end
      yield self
    end
  end

  # Add a new test command using _cmd_, _target_ and _value_.
  def command cmd, target=nil, value=nil
    @xml.tr do
      _tdata cmd
      _tdata target
      _tdata value
    end
  end

  protected

  # If _url_ is a string, return unchanged.  Otherwise, pass it to
  # ActionView#UrlHelper#url_for.
  def url_arg url
    if url.instance_of?(String) then url else @view.url_for(url) end
  end

  # If _options_ contains :wait, append +AndWait+ to _name_.
  def name_with_optional_wait name, options
    if options[:wait] then "#{name}AndWait" else name end
  end

  private

  # Output a single TD element.
  def _tdata value
    if value
      @xml.td(value.to_s)
    else
      @xml.td do @xml.target! << '&nbsp;' end
    end
  end
end
