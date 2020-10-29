#ifndef MISSING_ANCIENT_RUBY_H
#define MISSING_ANCIENT_RUBY_H

#ifndef HAVE_RB_STR_SET_LEN
static void my_str_set_len(VALUE str, long len)
{
	RSTRING(str)->len = len;
	RSTRING(str)->ptr[len] = '\0';
}
#define rb_str_set_len(str,len) my_str_set_len((str),(len))
#endif /* ! HAVE_RB_STR_SET_LEN */

#ifndef RSTRING_PTR
#  define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif /* !defined(RSTRING_PTR) */
#ifndef RSTRING_LEN
#  define RSTRING_LEN(s) (RSTRING(s)->len)
#endif /* !defined(RSTRING_LEN) */

#ifndef RARRAY_LEN
#  define RARRAY_LEN(s) (RARRAY(s)->len)
#endif /* !defined(RARRAY_LEN) */

#endif /* MISSING_ANCIENT_RUBY_H */
