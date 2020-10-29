require 'mkmf'

$CFLAGS += ' -fvisibility=hidden'

dir_config('rinku')
create_makefile('rinku')
