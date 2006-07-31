module SeleniumOnRails::Paths
  def selenium_path
    @@selenium_path ||= find_selenium_path
    @@selenium_path
  end
  
  def selenium_tests_path
    File.expand_path(File.join(RAILS_ROOT, 'test/selenium'))
  end
  
  def view_path view
    File.expand_path(File.dirname(__FILE__) + '/../views/' + view)
  end

  # Returns the path to the layout template. The path is relative in relation
  # to the app/views/ directory since Rails doesn't support absolute paths
  # to layout templates.
  def layout_path
    rails_root = Pathname.new File.expand_path(File.join(RAILS_ROOT, 'app/views'))
    view_path = Pathname.new view_path('layout')
    view_path.relative_path_from(rails_root).to_s
  end
  
  def fixtures_path
    File.expand_path File.join(RAILS_ROOT, 'test/fixtures')
  end
  
  private
    def find_selenium_path
      # with checked out selenium
      vendor_selenium = File.expand_path(File.join(RAILS_ROOT, 'vendor/selenium/javascript'))
      return vendor_selenium if File.directory? vendor_selenium
      
      # installed selenium gem	
      gems = Gem.source_index.find_name 'selenium', nil
      raise "could not find selenium gem" if gems.empty?
      File.join gems[0].full_gem_path, 'javascript'
    end
     
end