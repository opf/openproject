require 'mkmf'
require 'rbconfig'

extension_name = 'oj'
dir_config(extension_name)

parts = RUBY_DESCRIPTION.split(' ')
type = parts[0]
type = type[4..-1] if type.start_with?('tcs-')
is_windows = RbConfig::CONFIG['host_os'] =~ /(mingw|mswin)/
platform = RUBY_PLATFORM
version = RUBY_VERSION.split('.')
puts ">>>>> Creating Makefile for #{type} version #{RUBY_VERSION} on #{platform} <<<<<"

dflags = {
  'RUBY_TYPE' => type,
  (type.upcase + '_RUBY') => nil,
  'RUBY_VERSION' => RUBY_VERSION,
  'RUBY_VERSION_MAJOR' => version[0],
  'RUBY_VERSION_MINOR' => version[1],
  'RUBY_VERSION_MICRO' => version[2],
  'IS_WINDOWS' => is_windows ? 1 : 0,
  'RSTRUCT_LEN_RETURNS_INTEGER_OBJECT' => ('ruby' == type && '2' == version[0] && '4' == version[1] && '1' >= version[2]) ? 1 : 0,
}

have_func('rb_time_timespec')
have_func('rb_ivar_count')
have_func('rb_ivar_foreach')
have_func('stpcpy')
have_func('rb_data_object_wrap')
have_func('pthread_mutex_init')

dflags['OJ_DEBUG'] = true unless ENV['OJ_DEBUG'].nil?

dflags.each do |k,v|
  if v.nil?
    $CPPFLAGS += " -D#{k}"
  else
    $CPPFLAGS += " -D#{k}=#{v}"
  end
end

$CPPFLAGS += ' -Wall'
#puts "*** $CPPFLAGS: #{$CPPFLAGS}"
# Adding the __attribute__ flag only works with gcc compilers and even then it
# does not work to check args with varargs so just remove the check.
CONFIG['warnflags'].slice!(/ -Wsuggest-attribute=format/)
CONFIG['warnflags'].slice!(/ -Wdeclaration-after-statement/)
CONFIG['warnflags'].slice!(/ -Wmissing-noreturn/)

create_makefile(File.join(extension_name, extension_name))

%x{make clean}
