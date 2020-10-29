/* We do not modify RSTRING in this file, so RSTRING_MODIFIED is not needed */
#if defined(HAVE_RB_IO_T) && \
    defined(HAVE_TYPE_STRUCT_RFILE) && \
    defined(HAVE_ST_PATHV)
/* MRI 1.9 */
static void set_file_path(VALUE io, VALUE path)
{
	rb_io_t *fptr = RFILE(io)->fptr;
	fptr->pathv = rb_str_new4(path);
}
#elif defined(HAVE_TYPE_OPENFILE) && \
      defined(HAVE_TYPE_STRUCT_RFILE) && \
      defined(HAVE_ST_PATH)
/* MRI 1.8 */
#include "util.h"
static void set_file_path(VALUE io, VALUE path)
{
	OpenFile *fptr = RFILE(io)->fptr;
	fptr->path = ruby_strdup(RSTRING_PTR(path));
}
#else
/* Rubinius */
static void set_file_path(VALUE io, VALUE path)
{
	rb_iv_set(io, "@path", rb_str_new4(path));
}
#endif
