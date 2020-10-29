#include "kgio.h"
#include <sys/utsname.h>
#include <stdio.h>
/* true if TCP Fast Open is usable */
unsigned kgio_tfo;
static VALUE eErrno_EPIPE, eErrno_ECONNRESET;
static ID id_set_backtrace;

static void tfo_maybe(void)
{
	VALUE mKgio = rb_define_module("Kgio");

	/* Deal with the case where system headers have not caught up */
	if (KGIO_TFO_MAYBE) {
		/* Ensure Linux 3.7 or later for TCP_FASTOPEN */
		struct utsname buf;
		unsigned maj, min;

		if (uname(&buf) != 0)
			rb_sys_fail("uname");
		if (sscanf(buf.release, "%u.%u", &maj, &min) != 2)
			return;
		if (maj < 3 || (maj == 3 && min < 7))
			return;
	}

	/*
	 * KGIO_TFO_MAYBE will be false if a distro backports TFO
	 * to a pre-3.7 kernel, but includes the necessary constants
	 * in system headers
	 */
#if defined(MSG_FASTOPEN) && defined(TCP_FASTOPEN)
	rb_define_const(mKgio, "TCP_FASTOPEN", INT2NUM(TCP_FASTOPEN));
	rb_define_const(mKgio, "MSG_FASTOPEN", INT2NUM(MSG_FASTOPEN));
	kgio_tfo = 1;
#endif
}

void kgio_raise_empty_bt(VALUE err, const char *msg)
{
	VALUE exc = rb_exc_new2(err, msg);
	VALUE bt = rb_ary_new();

	rb_funcall(exc, id_set_backtrace, 1, bt);
	rb_exc_raise(exc);
}

void kgio_wr_sys_fail(const char *msg)
{
	switch (errno) {
	case EPIPE:
		errno = 0;
		kgio_raise_empty_bt(eErrno_EPIPE, msg);
	case ECONNRESET:
		errno = 0;
		kgio_raise_empty_bt(eErrno_ECONNRESET, msg);
	}
	rb_sys_fail(msg);
}

void kgio_rd_sys_fail(const char *msg)
{
	if (errno == ECONNRESET) {
		errno = 0;
		kgio_raise_empty_bt(eErrno_ECONNRESET, msg);
	}
	rb_sys_fail(msg);
}

void Init_kgio_ext(void)
{
	VALUE mKgio = rb_define_module("Kgio");
	VALUE mPipeMethods = rb_define_module_under(mKgio, "PipeMethods");
	VALUE mSocketMethods = rb_define_module_under(mKgio, "SocketMethods");
	VALUE mWaiters = rb_define_module_under(mKgio, "DefaultWaiters");

	id_set_backtrace = rb_intern("set_backtrace");
	eErrno_EPIPE = rb_const_get(rb_mErrno, rb_intern("EPIPE"));
	eErrno_ECONNRESET = rb_const_get(rb_mErrno, rb_intern("ECONNRESET"));

	/*
	 * Returns the client IP address of the socket as a string
	 * (e.g. "127.0.0.1" or "::1").
	 * This is always the value of the Kgio::LOCALHOST constant
	 * for UNIX domain sockets.
	 */
	rb_define_attr(mSocketMethods, "kgio_addr", 1, 1);
	rb_include_module(mPipeMethods, mWaiters);
	rb_include_module(mSocketMethods, mWaiters);

	tfo_maybe();
	init_kgio_wait();
	init_kgio_read();
	init_kgio_write();
	init_kgio_writev();
	init_kgio_connect();
	init_kgio_accept();
	init_kgio_autopush();
	init_kgio_poll();
	init_kgio_tryopen();
}
