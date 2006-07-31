# Renders Selenium test templates in a fashion analogous to +rxml+ and
# +rjs+ templates.
#
#   setup
#   open :controller => 'customer', :action => 'list'
#   assert_title 'Customers'
#
# See SeleniumOnRails::TestBuilder for a list of available commands.
class SeleniumOnRails::RSelenese < SeleniumOnRails::TestBuilder
  attr_accessor :view
  # Create a new RSelenese renderer bound to _view_.
  def initialize view
    super view
    @view = view
  end

  # Render _template_ using _local_assigns_.
  def render template, local_assigns
    title = (@view.assigns['page_title'] or local_assigns['page_title'])
    table(title) do
      test = self #to enable test.command
      eval template
    end
  end
end


ActionView::Base.register_template_handler "rsel", SeleniumOnRails::RSelenese