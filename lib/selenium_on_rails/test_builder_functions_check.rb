#----------------------------------------------------------------------------
# The test_builder_actions.rb and test_builder_accessors.rb files do not
# necessarily contain all the functions which are available in Selenium.
# Here we use the iedoc.xml file to find functions which might need to be
# added to the test_builder_actions.rb file.  Ultimately it would be great not
# to need to do this process manually, however, this is a temporary step
# toward improving function parity.

iedoc_file = File.read "../../selenium-core/iedoc.xml"
test_builder_actions_file = File.read "./test_builder_actions.rb"
test_builder_accessors_file = File.read "./test_builder_accessors.rb"

# Don't include any deprecated functions
deprecated_functions = %W{dragdrop}

iedoc_functions = iedoc_file.scan(/function *name *= *["']([a-zA-Z]+)["']/)\
                            .sort.collect{|x| x[0]} - deprecated_functions

for function_name in iedoc_functions

  function_name.gsub!(/[A-Z]/) { |s| "_" + s.downcase }
  
  if test_builder_actions_file.match(/def *#{function_name}/) ||
      test_builder_accessors_file.match(/(?:def *|tt>)#{function_name}/)
    puts "OK: " + function_name
  else
    puts "---> MISSING: " + function_name
  end
end

