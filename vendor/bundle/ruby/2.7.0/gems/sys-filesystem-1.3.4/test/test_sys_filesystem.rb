$LOAD_PATH.unshift File.dirname(File.expand_path(__FILE__))
   
if File::ALT_SEPARATOR
  require 'test_sys_filesystem_windows'
else
  require 'test_sys_filesystem_unix'
end
