/* ref: rubinius b2811f260de16d1e972462e27852470364608de5 */
#define RSTRING_MODIFIED 1
#include "kgio.h"
#include "my_fileno.h"
#include "nonblock.h"
static VALUE sym_wait_readable;

#ifdef USE_MSG_DONTWAIT
static const int peek_flags = MSG_DONTWAIT|MSG_PEEK;

/* we don't need these variants, we call kgio_autopush_recv directly */
static inline void kgio_autopush_read(VALUE io) { }

#else
static const int peek_flags = MSG_PEEK;
static inline void kgio_autopush_read(VALUE io) { kgio_autopush_recv(io); }
#endif

struct rd_args {
	VALUE io;
	VALUE buf;
	char *ptr;
	long len;
	int fd;
};

NORETURN(static void my_eof_error(void));

static void my_eof_error(void)
{
	kgio_raise_empty_bt(rb_eEOFError, "end of file reached");
}

static void prepare_read(struct rd_args *a, int argc, VALUE *argv, VALUE io)
{
	VALUE length;

	a->io = io;
	a->fd = my_fileno(io);
	rb_scan_args(argc, argv, "11", &length, &a->buf);
	a->len = NUM2LONG(length);
	if (NIL_P(a->buf)) {
		a->buf = rb_str_new(NULL, a->len);
	} else {
		StringValue(a->buf);
		rb_str_modify(a->buf);
		rb_str_resize(a->buf, a->len);
	}
	a->ptr = RSTRING_PTR(a->buf);
}

static int read_check(struct rd_args *a, long n, const char *msg, int io_wait)
{
	if (n < 0) {
		if (errno == EINTR) {
			a->fd = my_fileno(a->io);
			return -1;
		}
		rb_str_set_len(a->buf, 0);
		if (errno == EAGAIN) {
			if (io_wait) {
				(void)kgio_call_wait_readable(a->io);

				/* buf may be modified in other thread/fiber */
				rb_str_modify(a->buf);
				rb_str_resize(a->buf, a->len);
				a->ptr = RSTRING_PTR(a->buf);
				return -1;
			} else {
				a->buf = sym_wait_readable;
				return 0;
			}
		}
		kgio_rd_sys_fail(msg);
	}
	rb_str_set_len(a->buf, n);
	if (n == 0)
		a->buf = Qnil;
	return 0;
}

static VALUE my_read(int io_wait, int argc, VALUE *argv, VALUE io)
{
	struct rd_args a;
	long n;

	prepare_read(&a, argc, argv, io);
	kgio_autopush_read(io);

	if (a.len > 0) {
		set_nonblocking(a.fd);
retry:
		n = (long)read(a.fd, a.ptr, a.len);
		if (read_check(&a, n, "read", io_wait) != 0)
			goto retry;
	}
	return a.buf;
}

/*
 * call-seq:
 *
 *	io.kgio_read(maxlen)           ->  buffer
 *	io.kgio_read(maxlen, buffer)   ->  buffer
 *
 * Reads at most maxlen bytes from the stream socket.  Returns with a
 * newly allocated buffer, or may reuse an existing buffer if supplied.
 *
 * This may block and call any method defined to +kgio_wait_readable+
 * for the class.
 *
 * Returns nil on EOF.
 *
 * This behaves like read(2) and IO#readpartial, NOT fread(3) or
 * IO#read which possess read-in-full behavior.
 */
static VALUE kgio_read(int argc, VALUE *argv, VALUE io)
{
	return my_read(1, argc, argv, io);
}

/*
 * Same as Kgio::PipeMethods#kgio_read, except EOFError is raised
 * on EOF without a backtrace.  This method is intended as a
 * drop-in replacement for places where IO#readpartial is used, and
 * may be aliased as such.
 */
static VALUE kgio_read_bang(int argc, VALUE *argv, VALUE io)
{
	VALUE rv = my_read(1, argc, argv, io);

	if (NIL_P(rv)) my_eof_error();
	return rv;
}

/*
 * call-seq:
 *
 *	io.kgio_tryread(maxlen)           ->  buffer
 *	io.kgio_tryread(maxlen, buffer)   ->  buffer
 *
 * Reads at most maxlen bytes from the stream socket.  Returns with a
 * newly allocated buffer, or may reuse an existing buffer if supplied.
 *
 * Returns nil on EOF.
 *
 * Returns :wait_readable if EAGAIN is encountered.
 */
static VALUE kgio_tryread(int argc, VALUE *argv, VALUE io)
{
	return my_read(0, argc, argv, io);
}

#ifdef USE_MSG_DONTWAIT
static VALUE my_recv(int io_wait, int argc, VALUE *argv, VALUE io)
{
	struct rd_args a;
	long n;

	prepare_read(&a, argc, argv, io);
	kgio_autopush_recv(io);

	if (a.len > 0) {
retry:
		n = (long)recv(a.fd, a.ptr, a.len, MSG_DONTWAIT);
		if (read_check(&a, n, "recv", io_wait) != 0)
			goto retry;
	}
	return a.buf;
}

/*
 * This method may be optimized on some systems (e.g. GNU/Linux) to use
 * MSG_DONTWAIT to avoid explicitly setting the O_NONBLOCK flag via fcntl.
 * Otherwise this is the same as Kgio::PipeMethods#kgio_read
 */
static VALUE kgio_recv(int argc, VALUE *argv, VALUE io)
{
	return my_recv(1, argc, argv, io);
}

/*
 * Same as Kgio::SocketMethods#kgio_read, except EOFError is raised
 * on EOF without a backtrace
 */
static VALUE kgio_recv_bang(int argc, VALUE *argv, VALUE io)
{
	VALUE rv = my_recv(1, argc, argv, io);

	if (NIL_P(rv)) my_eof_error();
	return rv;
}

/*
 * This method may be optimized on some systems (e.g. GNU/Linux) to use
 * MSG_DONTWAIT to avoid explicitly setting the O_NONBLOCK flag via fcntl.
 * Otherwise this is the same as Kgio::PipeMethods#kgio_tryread
 */
static VALUE kgio_tryrecv(int argc, VALUE *argv, VALUE io)
{
	return my_recv(0, argc, argv, io);
}
#else /* ! USE_MSG_DONTWAIT */
#  define kgio_recv kgio_read
#  define kgio_recv_bang kgio_read_bang
#  define kgio_tryrecv kgio_tryread
#endif /* USE_MSG_DONTWAIT */

static VALUE my_peek(int io_wait, int argc, VALUE *argv, VALUE io)
{
	struct rd_args a;
	long n;

	prepare_read(&a, argc, argv, io);
	kgio_autopush_recv(io);

	if (a.len > 0) {
		if (peek_flags == MSG_PEEK)
			set_nonblocking(a.fd);
retry:
		n = (long)recv(a.fd, a.ptr, a.len, peek_flags);
		if (read_check(&a, n, "recv(MSG_PEEK)", io_wait) != 0)
			goto retry;
	}
	return a.buf;
}

/*
 * call-seq:
 *
 *	socket.kgio_trypeek(maxlen)           ->  buffer
 *	socket.kgio_trypeek(maxlen, buffer)   ->  buffer
 *
 * Like kgio_tryread, except it uses MSG_PEEK so it does not drain the
 * socket buffer.  A subsequent read of any type (including another peek)
 * will return the same data.
 */
static VALUE kgio_trypeek(int argc, VALUE *argv, VALUE io)
{
	return my_peek(0, argc, argv, io);
}

/*
 * call-seq:
 *
 *	socket.kgio_peek(maxlen)           ->  buffer
 *	socket.kgio_peek(maxlen, buffer)   ->  buffer
 *
 * Like kgio_read, except it uses MSG_PEEK so it does not drain the
 * socket buffer.  A subsequent read of any type (including another peek)
 * will return the same data.
 */
static VALUE kgio_peek(int argc, VALUE *argv, VALUE io)
{
	return my_peek(1, argc, argv, io);
}

/*
 * call-seq:
 *
 *	Kgio.trypeek(socket, maxlen)           ->  buffer
 *	Kgio.trypeek(socket, maxlen, buffer)   ->  buffer
 *
 * Like Kgio.tryread, except it uses MSG_PEEK so it does not drain the
 * socket buffer.  This can only be used on sockets and not pipe objects.
 * Maybe used in place of SocketMethods#kgio_trypeek for non-Kgio objects
 */
static VALUE s_trypeek(int argc, VALUE *argv, VALUE mod)
{
	if (argc <= 1)
		rb_raise(rb_eArgError, "wrong number of arguments");
	return my_peek(0, argc - 1, &argv[1], argv[0]);
}

/*
 * call-seq:
 *
 *	Kgio.tryread(io, maxlen)           ->  buffer
 *	Kgio.tryread(io, maxlen, buffer)   ->  buffer
 *
 * Returns nil on EOF.
 * Returns :wait_readable if EAGAIN is encountered.
 *
 * Maybe used in place of PipeMethods#kgio_tryread for non-Kgio objects
 */
static VALUE s_tryread(int argc, VALUE *argv, VALUE mod)
{
	if (argc <= 1)
		rb_raise(rb_eArgError, "wrong number of arguments");
	return my_read(0, argc - 1, &argv[1], argv[0]);
}

void init_kgio_read(void)
{
	VALUE mPipeMethods, mSocketMethods;
	VALUE mKgio = rb_define_module("Kgio");

	sym_wait_readable = ID2SYM(rb_intern("wait_readable"));

	rb_define_singleton_method(mKgio, "tryread", s_tryread, -1);
	rb_define_singleton_method(mKgio, "trypeek", s_trypeek, -1);

	/*
	 * Document-module: Kgio::PipeMethods
	 *
	 * This module may be used used to create classes that respond to
	 * various Kgio methods for reading and writing.  This is included
	 * in Kgio::Pipe by default.
	 */
	mPipeMethods = rb_define_module_under(mKgio, "PipeMethods");
	rb_define_method(mPipeMethods, "kgio_read", kgio_read, -1);
	rb_define_method(mPipeMethods, "kgio_read!", kgio_read_bang, -1);
	rb_define_method(mPipeMethods, "kgio_tryread", kgio_tryread, -1);

	/*
	 * Document-module: Kgio::SocketMethods
	 *
	 * This method behaves like Kgio::PipeMethods, but contains
	 * optimizations for sockets on certain operating systems
	 * (e.g. GNU/Linux).
	 */
	mSocketMethods = rb_define_module_under(mKgio, "SocketMethods");
	rb_define_method(mSocketMethods, "kgio_read", kgio_recv, -1);
	rb_define_method(mSocketMethods, "kgio_read!", kgio_recv_bang, -1);
	rb_define_method(mSocketMethods, "kgio_tryread", kgio_tryrecv, -1);
	rb_define_method(mSocketMethods, "kgio_trypeek", kgio_trypeek, -1);
	rb_define_method(mSocketMethods, "kgio_peek", kgio_peek, -1);
}
