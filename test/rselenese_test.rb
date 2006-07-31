require File.dirname(__FILE__) + '/test_helper'

class RSeleneseTest < Test::Unit::TestCase
  include ERB::Util
  
  def rselenese name, input, partial = nil, type = nil
    view = TestView.new
    view.override_partial partial, type do
      view.assigns['page_title'] = name
      view.render_template 'rsel', input
    end
  end

  def assert_rselenese expected, name, input, partial = nil, type = nil
    assert_text_equal(expected, rselenese(name, input, partial, type))
  end

  def test_empty
    expected = <<END
<table>
<tr><th colspan="3">Empty</th></tr>
</table>
END
    input = ''
    assert_rselenese expected, 'Empty', input
  end

  def assert_generates_command expected, name, *args
    expected = expected.map {|v| h(v) }
    expected << '&nbsp;' while expected.length < 3
    expected = expected.map {|v| "<td>#{v}</td>" }.join
    expected_html = <<END
<table>
<tr><th colspan="3">Selenese Commands</th></tr>
<tr>#{expected}</tr>
</table>
END
    args_str  = args.map {|a| a.inspect }.join(',')
    input = "#{name}(#{args_str})"
    assert_rselenese expected_html, 'Selenese Commands', input
  end

  def test_element_locators
    assert_generates_command %w{click aCheckbox}, :click, 'aCheckbox'
    assert_generates_command %w{click document.foo}, :click, 'document.foo'
    assert_generates_command %w{click //a}, :click, '//a'
  end

  ARG_VALUE_MAP = {
    # We can't test url_for style arguments here, because we don't have
    # a valid controller to interpret them.  See RendererTest.
    :url => '/relative/url',
    :element => 'foo',          # Also: '//foo', 'document.foo', others.
    :string => '1234',
    :option => 'J* Smith',      # Also: many other formats.
    :pattern => 'glob:J* Smith' # Also: many other formats.
  }

  # Call _command_ with _args_ and make sure it produces a good table.
  # Specify _can_wait_ to test a version of the command with
  # <code>:wait</code>.
  # If the command is an _assert_ command it is also checked to make sure that
  # the corresponding _verify_ command works.
  def assert_command_works command, can_wait, *args
    values = args.map {|a| ARG_VALUE_MAP[a] }
    name = SeleniumOnRails::TestBuilder.selenize(command.to_s)
    assert_generates_command [name]+values, command, *values
    if can_wait
      assert_generates_command(["#{name}AndWait"]+values,
                               command, *(values+[{:wait => true}]))
    end
    if command.to_s.starts_with? 'assert'
      assert_command_works command.to_s.sub('assert', 'verify'), can_wait, *args
    end
  end

  def test_simple_commands
    assert_command_works :open,            false, :url
    assert_command_works :type,            true,  :element, :string
    assert_command_works :select,          true,  :element, :option
    assert_command_works :select_window,   false, :string
    assert_command_works :go_back,         false
    assert_command_works :close,           false
    assert_command_works :pause,           false, :string
    assert_command_works :fire_event,      false, :element, :string
    assert_command_works :wait_for_value,  false, :element, :string
    assert_command_works :store,           false, :string, :string
    assert_command_works :store_value,     false, :element, :string
    assert_command_works :store_text,      false, :element, :string
    assert_command_works :choose_cancel_on_next_confirmation, false
    assert_command_works :answer_on_next_prompt, false, :string
    assert_command_works :assert_location, false, :url
    assert_command_works :assert_title,    false, :string
    assert_command_works :assert_value,    false, :element, :pattern
    assert_command_works :assert_selected, false, :element, :option
    assert_command_works :assert_text,     false, :element, :pattern
    assert_command_works :assert_text_present, false, :string
    assert_command_works :assert_text_not_present, false, :string
    assert_command_works :assert_element_present, false, :element
    assert_command_works :assert_element_not_present, false, :element
    assert_command_works :assert_visible,  false, :element
    assert_command_works :assert_not_visible, false, :element
    assert_command_works :assert_editable, false, :element
    assert_command_works :assert_not_editable, false, :element
    assert_command_works :assert_alert,    false, :pattern
    assert_command_works :assert_confirmation, false, :pattern
    assert_command_works :assert_prompt,   false, :pattern
  end

  def test_select_window_should_support_nil
    assert_generates_command %w{selectWindow null}, :select_window, nil
  end

  def test_command_store_attribute
    assert_generates_command(%w{storeAttribute foo@bar baz},
                             :store_attribute, 'foo', 'bar', 'baz')
  end

  def test_command_assert_select_options
    # Use double-quoted strings so we can keep track of escape sequences
    # without remembering Ruby-specific rules.
    assert_generates_command(['assertSelectOptions','sel',"foo,bar\\,\\\\baz"],
                             :assert_select_options, 'sel', 'foo', "bar,\\baz")
  end

  def test_command_assert_attribute
    assert_generates_command(%w{assertAttribute foo@bar baz},
                             :assert_attribute, 'foo', 'bar', 'baz')
  end

  def test_command_assert_table
    assert_generates_command(%w{assertTable foo.2.3 bar},
                             :assert_table, 'foo', 2, 3, 'bar')
  end
  
  def test_partial_support
    expected = <<END
<table>
<tr><th colspan="3">Partial support</th></tr>
<tr><td>type</td><td>partial</td><td>RSelenese partial</td></tr>
</table>
END
    input = "include_partial 'override'"
    partial = "type 'partial', 'RSelenese partial'"
    assert_rselenese expected, 'Partial support', input, partial, 'rsel'
  end
  
  def test_partial_support_with_local_assigns
    expected = <<END_EXPECTED
<table>
<tr><th colspan="3">Partial support with local variables</th></tr>
<tr><td>type</td><td>partial</td><td>RSelenese partial</td></tr>
<tr><td>type</td><td>local</td><td>par</td></tr>
<tr><td>type</td><td>local</td><td>tial</td></tr>
</table>
END_EXPECTED
    input = "include_partial 'override', :locator => 'local', :input => ['par', 'tial']"
    partial = <<END_PARTIAL
type 'partial', 'RSelenese partial'
input.each do |i|
  type locator, i
end
END_PARTIAL
    assert_rselenese expected, 'Partial support with local variables', input, partial, 'rsel'
  end

end
