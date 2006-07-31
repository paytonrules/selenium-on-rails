if ['development', 'test'].include? RAILS_ENV
  $LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/lib/controllers")

  require File.join(File.dirname(__FILE__), 'routes.rb')

else
  #erase all traces
  $LOAD_PATH.delete lib_path
end

