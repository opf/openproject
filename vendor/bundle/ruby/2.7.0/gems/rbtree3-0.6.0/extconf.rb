require 'mkmf'

if $DEBUG
  if CONFIG['GCC'] == 'yes'
    $CFLAGS << ' -std=c89 -pedantic -Wno-long-long'
  end
  $defs << ' -Dinline=__inline'
else
  $defs << '-DNDEBUG'
end

have_func('rb_exec_recursive', 'ruby.h')
create_makefile('rbtree')
