/* we do not modify RSTRING pointers here */
#include "kgio.h"
#include "my_fileno.h"
#include "nonblock.h"
static VALUE sym_wait_writable;

struct wr_args {
	VALUE io;
	VALUE buf;
	const char *ptr;
	long len;
	int fd;
	int flags;
};

static void prepare_write(struct wr_args *a, VALUE io, VALUE str)
{
	a->buf = (TYPE(str) == T_STRING) ? str : rb_obj_as_string(str);
	a->ptr = RSTRING_PTR(a->buf);
	a->len = RSTRING_LEN(a->buf);
	a->io = io;
	a->fd = my_fileno(io);
}

static int write_check(struct wr_args *a, long n, const char *msg, int io_wait)
{
	if (a->len == n) {
done:
		a->buf = Qnil;
	} else if (n < 0) {
		if (errno == EINTR) {
			a->fd = my_fileno(a->io);
			return -1;
		}
		if (errno == EAGAIN) {
			long written = RSTRING_LEN(a->buf) - a->len;

			if (io_wait) {
				(void)kgio_call_wait_writable(a->io);

				/* buf may be modified in other thread/fiber */
				a->len = RSTRING_LEN(a->buf) - written;
				if (a->len <= 0)
					goto done;
				a->ptr = RSTRING_PTR(a->buf) + written;
				return -1;
			} else if (written > 0) {
				a->buf = MY_STR_SUBSEQ(a->buf, written, a->len);
			} else {
				a->buf = sym_wait_writable;
			}
			return 0;
		}
		kgio_wr_sys_fail(msg);
	} else {
		assert(n >= 0 && n < a->len && "write/send syscall broken?");
		a->ptr += n;
		a->len -= n;
		return -1;
	}
	return 0;
}

static VALUE my_write(VALUE io, VALUE str, int io_wait)
{
	struct wr_args a;
	long n;

	prepare_write(&a, io, str);
	set_nonblocking(a.fd);
retry:
	n = (long)write(a.fd, a.ptr, a.len);
	if (write_check(&a, n, "write", io_wait) != 0)
		goto retry;
	if (TYPE(a.buf) != T_SYMBOL)
		kgio_autopush_write(io);
	return a.buf;
}

/*
 * call-seq:
 *
 *	io.kgio_write(str)	-> nil
 *
 * Returns nil when the write completes.
 *
 * This may block and call any method defined to +kgio_wait_writable+
 * for the class.
 */
static VALUE kgio_write(VALUE io, VALUE str)
{
	return my_write(io, str, 1);
}

/*
 * call-seq:
 *
 *	io.kgio_trywrite(str)	-> nil, String or :wait_writable
 *
 * Returns nil if the write was completed in full.
 *
 * Returns a String containing the unwritten portion if EAGAIN
 * was encountered, but some portion was successfully written.
 *
 * Returns :wait_writable if EAGAIN is encountered and nothing
 * was written.
 */
static VALUE kgio_trywrite(VALUE io, VALUE str)
{
	return my_write(io, str, 0);
}

#ifdef USE_MSG_DONTWAIT
/*
 * This method behaves like Kgio::PipeMethods#kgio_write, except
 * it will use send(2) with the MSG_DONTWAIT flag on sockets to
 * avoid unnecessary calls to fcntl(2).
 */
static VALUE my_send(VALUE io, VALUE str, int io_wait)
{
	struct wr_args a;
	long n;

	prepare_write(&a, io, str);
retry:
	n = (long)send(a.fd, a.ptr, a.len, MSG_DONTWAIT);
	if (write_check(&a, n, "send", io_wait) != 0)
		goto retry;
	if (TYPE(a.buf) != T_SYMBOL)
		kgio_autopush_send(io);
	return a.buf;
}

/*
 * This method may be optimized on some systems (e.g. GNU/Linux) to use
 * MSG_DONTWAIT to avoid explicitly setting the O_NONBLOCK flag via fcntl.
 * Otherwise this is the same as Kgio::PipeMethods#kgio_write
 */
static VALUE kgio_send(VALUE io, VALUE str)
{
	return my_send(io, str, 1);
}

/*
 * This method may be optimized on some systems (e.g. GNU/Linux) to use
 * MSG_DONTWAIT to avoid explicitly setting the O_NONBLOCK flag via fcntl.
 * Otherwise this is the same as Kgio::PipeMethods#kgio_trywrite
 */
static VALUE kgio_trysend(VALUE io, VALUE str)
{
	return my_send(io, str, 0);
}
#else /* ! USE_MSG_DONTWAIT */
#  define kgio_send kgio_write
#  define kgio_trysend kgio_trywrite
#endif /* ! USE_MSG_DONTWAIT */

#if defined(KGIO_WITHOUT_GVL)
#  include "blocking_io_region.h"
#ifdef MSG_DONTWAIT /* Linux only */
#  define MY_MSG_DONTWAIT (MSG_DONTWAIT)
#else
#  define MY_MSG_DONTWAIT (0)
#endif

static VALUE nogvl_send(void *ptr)
{
	struct wr_args *a = ptr;

	return (VALUE)send(a->fd, a->ptr, a->len, a->flags);
}
/*
 * call-seq:
 *
 *	io.kgio_syssend(str, flags) -> nil, String or :wait_writable
 *
 * Returns nil if the write was completed in full.
 *
 * Returns a String containing the unwritten portion if EAGAIN
 * was encountered, but some portion was successfully written.
 *
 * Returns :wait_writable if EAGAIN is encountered and nothing
 * was written.
 *
 * This method is only available on Ruby 1.9.3 or later.
 */
static VALUE kgio_syssend(VALUE io, VALUE str, VALUE flags)
{
	struct wr_args a;
	long n;

	a.flags = NUM2INT(flags);
	prepare_write(&a, io, str);
	if (a.flags & MY_MSG_DONTWAIT) {
		do {
			n = (long)send(a.fd, a.ptr, a.len, a.flags);
		} while (write_check(&a, n, "send", 0) != 0);
	} else {
		do {
			n = (long)rb_thread_io_blocking_region(
						nogvl_send, &a, a.fd);
		} while (write_check(&a, n, "send", 0) != 0);
	}
	return a.buf;
}
#endif /* HAVE_RB_THREAD_IO_BLOCKING_REGION */

/*
 * call-seq:
 *
 *	Kgio.trywrite(io, str)    -> nil, String or :wait_writable
 *
 * Returns nil if the write was completed in full.
 *
 * Returns a String containing the unwritten portion if EAGAIN
 * was encountered, but some portion was successfully written.
 *
 * Returns :wait_writable if EAGAIN is encountered and nothing
 * was written.
 *
 * Maybe used in place of PipeMethods#kgio_trywrite for non-Kgio objects
 */
static VALUE s_trywrite(VALUE mod, VALUE io, VALUE str)
{
	return my_write(io, str, 0);
}

void init_kgio_write(void)
{
	VALUE mPipeMethods, mSocketMethods;
	VALUE mKgio = rb_define_module("Kgio");

	sym_wait_writable = ID2SYM(rb_intern("wait_writable"));

	rb_define_singleton_method(mKgio, "trywrite", s_trywrite, 2);

	/*
	 * Document-module: Kgio::PipeMethods
	 *
	 * This module may be used used to create classes that respond to
	 * various Kgio methods for reading and writing.  This is included
	 * in Kgio::Pipe by default.
	 */
	mPipeMethods = rb_define_module_under(mKgio, "PipeMethods");
	rb_define_method(mPipeMethods, "kgio_write", kgio_write, 1);
	rb_define_method(mPipeMethods, "kgio_trywrite", kgio_trywrite, 1);

	/*
	 * Document-module: Kgio::SocketMethods
	 *
	 * This method behaves like Kgio::PipeMethods, but contains
	 * optimizations for sockets on certain operating systems
	 * (e.g. GNU/Linux).
	 */
	mSocketMethods = rb_define_module_under(mKgio, "SocketMethods");
	rb_define_method(mSocketMethods, "kgio_write", kgio_send, 1);
	rb_define_method(mSocketMethods, "kgio_trywrite", kgio_trysend, 1);

#if defined(KGIO_WITHOUT_GVL)
	rb_define_method(mSocketMethods, "kgio_syssend", kgio_syssend, 2);
#endif
}
