require 'mkmf'

# warnings save lives
$CFLAGS << " -Wall " if RbConfig::CONFIG['GCC'] != ""

if RUBY_PLATFORM =~ /(mswin|mingw|cygwin|bccwin)/
  File.open('Makefile','w'){|f| f.puts "default: \ninstall: " }
else
  create_makefile('posix_spawn_ext')
end

