require 'mkmf'

$CFLAGS << ' -Wall -funroll-loops -fvisibility=hidden'
$CFLAGS << ' -Wextra -O0 -ggdb3' if ENV['DEBUG']

create_makefile("escape_utils/escape_utils")
