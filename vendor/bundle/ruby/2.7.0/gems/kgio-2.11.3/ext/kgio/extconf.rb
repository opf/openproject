require 'mkmf'
$CPPFLAGS << ' -D_GNU_SOURCE'
$CPPFLAGS << ' -DPOSIX_C_SOURCE=1'
$CPPFLAGS += '-D_POSIX_C_SOURCE=200112L'
unless have_macro('CLOCK_MONOTONIC', 'time.h')
  have_func('CLOCK_MONOTONIC', 'time.h')
end
have_type('clockid_t', 'time.h')
have_library('rt', 'clock_gettime', 'time.h')

# taken from ext/socket/extconf.rb in ruby/trunk:
# OpenSolaris:
have_library("nsl", "t_open")
have_library("socket", "socket")

have_func("poll", "poll.h")
have_func("getaddrinfo", %w(sys/types.h sys/socket.h netdb.h)) or
  abort "getaddrinfo required"
have_func("getnameinfo", %w(sys/types.h sys/socket.h netdb.h)) or
  abort "getnameinfo required"
have_type("struct sockaddr_storage", %w(sys/types.h sys/socket.h)) or
  abort "struct sockaddr_storage required"
have_func('accept4', %w(sys/socket.h))
have_header("sys/select.h")

have_func("writev", "sys/uio.h")

if have_header('ruby/io.h')
  rubyio = %w(ruby.h ruby/io.h)
  have_struct_member("rb_io_t", "fd", rubyio)
  have_struct_member("rb_io_t", "mode", rubyio)
  have_struct_member("rb_io_t", "pathv", rubyio)
else
  rubyio = %w(ruby.h rubyio.h)
  rb_io_t = have_type("OpenFile", rubyio) ? "OpenFile" : "rb_io_t"
  have_struct_member(rb_io_t, "f", rubyio)
  have_struct_member(rb_io_t, "f2", rubyio)
  have_struct_member(rb_io_t, "mode", rubyio)
  have_struct_member(rb_io_t, "path", rubyio)
  have_func('rb_fdopen')
end
have_type("struct RFile", rubyio) and check_sizeof("struct RFile", rubyio)
have_type("struct RObject") and check_sizeof("struct RObject")
check_sizeof("int")
have_func('rb_io_ascii8bit_binmode')
have_func('rb_update_max_fd')
have_func('rb_fd_fix_cloexec')
have_func('rb_cloexec_open')
have_header('ruby/thread.h')
have_func('rb_thread_call_without_gvl', %w{ruby/thread.h})
have_func('rb_thread_blocking_region')
have_func('rb_thread_io_blocking_region')
have_func('rb_str_set_len')
have_func("rb_hash_clear", "ruby.h") # Ruby 2.0+
have_func('rb_time_interval')
have_func('rb_wait_for_single_fd')
have_func('rb_str_subseq')
have_func('rb_ary_subseq')

create_makefile('kgio_ext')
