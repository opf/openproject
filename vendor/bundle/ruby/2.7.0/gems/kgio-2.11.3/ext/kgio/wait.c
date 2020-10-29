#include "kgio.h"
#include "my_fileno.h"
static ID id_wait_rd, id_wait_wr;

#if defined(HAVE_RB_TIME_INTERVAL) && defined(HAVE_RB_WAIT_FOR_SINGLE_FD)
static int kgio_timedwait(VALUE self, VALUE timeout, int write_p)
{
	struct timeval tv = rb_time_interval(timeout);
	int events = write_p ? RB_WAITFD_OUT : RB_WAITFD_IN;

	return rb_wait_for_single_fd(my_fileno(self), events, &tv);
}
#else  /* ! (HAVE_RB_TIME_INTERVAL && HAVE_RB_WAIT_FOR_SINGLE_FD) */
static int kgio_timedwait(VALUE self, VALUE timeout, int write_p)
{
	VALUE argv[4];
	VALUE set = rb_ary_new3(1, self);

	argv[0] = write_p ? Qnil : set;
	argv[1] = write_p ? set : Qnil;
	argv[2] = Qnil;
	argv[3] = timeout;

	set = rb_funcall2(rb_cIO, rb_intern("select"), 4, argv);
	return NIL_P(set) ? 0 : 1;
}
#endif /* ! (HAVE_RB_TIME_INTERVAL && HAVE_RB_WAIT_FOR_SINGLE_FD) */

static int kgio_wait(int argc, VALUE *argv, VALUE self, int write_p)
{
	int fd;
	VALUE timeout;

	if (rb_scan_args(argc, argv, "01", &timeout) == 1 && !NIL_P(timeout))
		return kgio_timedwait(self, timeout, write_p);

	fd = my_fileno(self);
	errno = EAGAIN;
	write_p ? rb_io_wait_writable(fd) : rb_io_wait_readable(fd);
	return 1;
}

/*
 * call-seq:
 *
 *	io.kgio_wait_readable           -> IO
 *	io.kgio_wait_readable(timeout)  -> IO or nil
 *
 * Blocks the running Thread indefinitely until the IO object is readable
 * or if +timeout+ expires.  If +timeout+ is specified and expires, +nil+
 * is returned.
 *
 * This method is automatically called (without timeout argument) by default
 * whenever kgio_read needs to block on input.
 *
 * Users of alternative threading/fiber libraries are
 * encouraged to override this method in their subclasses or modules to
 * work with their threading/blocking methods.
 */
static VALUE kgio_wait_readable(int argc, VALUE *argv, VALUE self)
{
	int r = kgio_wait(argc, argv, self, 0);

	if (r < 0) rb_sys_fail("kgio_wait_readable");
	return r == 0 ? Qnil : self;
}

/*
 * call-seq:
 *
 *	io.kgio_wait_writable           -> IO
 *	io.kgio_wait_writable(timeout)  -> IO or nil
 *
 * Blocks the running Thread indefinitely until the IO object is writable
 * or if +timeout+ expires.  If +timeout+ is specified and expires, +nil+
 * is returned.
 *
 * This method is automatically called (without timeout argument) by default
 * whenever kgio_write needs to block on output.
 *
 * Users of alternative threading/fiber libraries are
 * encouraged to override this method in their subclasses or modules to
 * work with their threading/blocking methods.
 */
static VALUE kgio_wait_writable(int argc, VALUE *argv, VALUE self)
{
	int r = kgio_wait(argc, argv, self, 1);

	if (r < 0) rb_sys_fail("kgio_wait_writable");
	return r == 0 ? Qnil : self;
}

VALUE kgio_call_wait_writable(VALUE io)
{
	return rb_funcall(io, id_wait_wr, 0);
}

VALUE kgio_call_wait_readable(VALUE io)
{
	return rb_funcall(io, id_wait_rd, 0);
}

void init_kgio_wait(void)
{
	VALUE mKgio = rb_define_module("Kgio");

	/*
	 * Document-module: Kgio::DefaultWaiters
	 *
	 * This module contains default kgio_wait_readable and
	 * kgio_wait_writable methods that block indefinitely (in a
	 * thread-safe manner) until an IO object is read or writable.
	 * This module is included in the Kgio::PipeMethods and
	 * Kgio::SocketMethods modules used by all bundled IO-derived
	 * objects.
	 */
	VALUE mWaiters = rb_define_module_under(mKgio, "DefaultWaiters");

	id_wait_rd = rb_intern("kgio_wait_readable");
	id_wait_wr = rb_intern("kgio_wait_writable");

	rb_define_method(mWaiters, "kgio_wait_readable",
	                 kgio_wait_readable, -1);
	rb_define_method(mWaiters, "kgio_wait_writable",
	                 kgio_wait_writable, -1);
}
