# -*- encoding: binary -*-
require 'mkmf'

unless RUBY_VERSION < '3.1'
  warn "Unicorn was only tested against MRI up to 3.0.\n" \
       "It might not properly work with #{RUBY_VERSION}"
end

have_macro("SIZEOF_OFF_T", "ruby.h") or check_sizeof("off_t", "sys/types.h")
have_macro("SIZEOF_SIZE_T", "ruby.h") or check_sizeof("size_t", "sys/types.h")
have_macro("SIZEOF_LONG", "ruby.h") or check_sizeof("long", "sys/types.h")
have_func("rb_str_set_len", "ruby.h") or abort 'Ruby 1.9.3+ required'
have_func("rb_hash_clear", "ruby.h") # Ruby 2.0+
have_func("gmtime_r", "time.h")

message('checking if String#-@ (str_uminus) dedupes... ')
begin
  a = -(%w(t e s t).join)
  b = -(%w(t e s t).join)
  if a.equal?(b)
    $CPPFLAGS += ' -DSTR_UMINUS_DEDUPE=1 '
    message("yes\n")
  else
    $CPPFLAGS += ' -DSTR_UMINUS_DEDUPE=0 '
    message("no, needs Ruby 2.5+\n")
  end
rescue NoMethodError
  $CPPFLAGS += ' -DSTR_UMINUS_DEDUPE=0 '
  message("no, String#-@ not available\n")
end

message('checking if Hash#[]= (rb_hash_aset) dedupes... ')
h = {}
x = {}
r = rand.to_s
h[%W(#{r}).join('')] = :foo
x[%W(#{r}).join('')] = :foo
if x.keys[0].equal?(h.keys[0])
  $CPPFLAGS += ' -DHASH_ASET_DEDUPE=1 '
  message("yes\n")
else
  $CPPFLAGS += ' -DHASH_ASET_DEDUPE=0 '
  message("no, needs Ruby 2.6+\n")
end

create_makefile("unicorn_http")
