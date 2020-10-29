/* ref: rubinius b2811f260de16d1e972462e27852470364608de5 */
#define RSTRING_MODIFIED 1

#include "kgio.h"
#include "missing_accept4.h"
#include "sock_for_fd.h"
#include "my_fileno.h"
#include "nonblock.h"

static VALUE localhost;
static VALUE cClientSocket;
static VALUE cKgio_Socket;
static VALUE mSocketMethods;
static VALUE iv_kgio_addr;

#if defined(__linux__) && defined(KGIO_WITHOUT_GVL)
static int accept4_flags = SOCK_CLOEXEC;
#else /* ! linux */
static int accept4_flags = SOCK_CLOEXEC | SOCK_NONBLOCK;
#endif /* ! linux */

struct accept_args {
	int fd;
	int flags;
	struct sockaddr *addr;
	socklen_t *addrlen;
	VALUE accept_io;
	VALUE accepted_class;
};

/*
 * Sets the default class for newly accepted sockets.  This is
 * legacy behavior, kgio_accept and kgio_tryaccept now take optional
 * class arguments to override this value.
 */
static VALUE set_accepted(VALUE klass, VALUE aclass)
{
	VALUE tmp;

	if (NIL_P(aclass))
		aclass = cKgio_Socket;

	tmp = rb_funcall(aclass, rb_intern("included_modules"), 0);
	tmp = rb_funcall(tmp, rb_intern("include?"), 1, mSocketMethods);

	if (tmp != Qtrue)
		rb_raise(rb_eTypeError,
		         "class must include Kgio::SocketMethods");

	cClientSocket = aclass;

	return aclass;
}

/*
 * Returns the default class for newly accepted sockets when kgio_accept
 * or kgio_tryaccept are not passed arguments
 */
static VALUE get_accepted(VALUE klass)
{
	return cClientSocket;
}

/*
 * accept() wrapper that'll fall back on accept() if we were built on
 * a system with accept4() but run on a system without accept4()
 */
static VALUE xaccept(void *ptr)
{
	struct accept_args *a = ptr;
	int rv;

	rv = accept_fn(a->fd, a->addr, a->addrlen, a->flags);
	if (rv < 0 && errno == ENOSYS && accept_fn != my_accept4) {
		accept_fn = my_accept4;
		rv = accept_fn(a->fd, a->addr, a->addrlen, a->flags);
	}

	return (VALUE)rv;
}

#ifdef KGIO_WITHOUT_GVL
#  include <time.h>
#  include "blocking_io_region.h"
static int thread_accept(struct accept_args *a, int force_nonblock)
{
	if (force_nonblock)
		set_nonblocking(a->fd);
	return (int)rb_thread_io_blocking_region(xaccept, a, a->fd);
}

#else /* ! KGIO_WITHOUT_GVL */
#  include <rubysig.h>
static int thread_accept(struct accept_args *a, int force_nonblock)
{
	int rv;

	/* always use non-blocking accept() under 1.8 for green threads */
	set_nonblocking(a->fd);

	/* created sockets are always non-blocking under 1.8, too */
	a->flags |= SOCK_NONBLOCK;

	TRAP_BEG;
	rv = (int)xaccept(a);
	TRAP_END;
	return rv;
}
#endif /* ! KGIO_WITHOUT_GVL */

static void
prepare_accept(struct accept_args *a, VALUE self, int argc, const VALUE *argv)
{
	a->fd = my_fileno(self);
	a->accept_io = self;

	switch (argc) {
	case 2:
		a->flags = NUM2INT(argv[1]);
		a->accepted_class = NIL_P(argv[0]) ? cClientSocket : argv[0];
		return;
	case 0: /* default, legacy behavior */
		a->flags = accept4_flags;
		a->accepted_class = cClientSocket;
		return;
	case 1:
		a->flags = accept4_flags;
		a->accepted_class = NIL_P(argv[0]) ? cClientSocket : argv[0];
		return;
	}

	rb_raise(rb_eArgError, "wrong number of arguments (%d for 1)", argc);
}

static VALUE in_addr_set(VALUE io, struct sockaddr_storage *addr, socklen_t len)
{
	VALUE host;
	int host_len, rc;
	char *host_ptr;

	switch (addr->ss_family) {
	case AF_INET:
		host_len = (long)INET_ADDRSTRLEN;
		break;
	case AF_INET6:
		host_len = (long)INET6_ADDRSTRLEN;
		break;
	default:
		rb_raise(rb_eRuntimeError,
		         "unsupported address family: ss_family=%lu (socklen=%ld)",
			 (unsigned long)addr->ss_family, (long)len);
	}
	host = rb_str_new(NULL, host_len);
	host_ptr = RSTRING_PTR(host);
	rc = getnameinfo((struct sockaddr *)addr, len,
			 host_ptr, host_len, NULL, 0, NI_NUMERICHOST);
	if (rc != 0)
		rb_raise(rb_eRuntimeError, "getnameinfo: %s", gai_strerror(rc));
	rb_str_set_len(host, strlen(host_ptr));
	return rb_ivar_set(io, iv_kgio_addr, host);
}

#if defined(__linux__)
#  define post_accept kgio_autopush_accept
#else
#  define post_accept(a,b) for(;0;)
#endif

static VALUE
my_accept(struct accept_args *a, int force_nonblock)
{
	int client_fd;
	VALUE client_io;
	int retried = 0;

retry:
	client_fd = thread_accept(a, force_nonblock);
	if (client_fd < 0) {
		switch (errno) {
		case EAGAIN:
			if (force_nonblock)
				return Qnil;
			a->fd = my_fileno(a->accept_io);
			errno = EAGAIN;
			(void)rb_io_wait_readable(a->fd);
			/* fall-through to EINTR case */
#ifdef ECONNABORTED
		case ECONNABORTED:
#endif /* ECONNABORTED */
#ifdef EPROTO
		case EPROTO:
#endif /* EPROTO */
		case EINTR:
			/* raise IOError if closed during sleep */
			a->fd = my_fileno(a->accept_io);
			goto retry;
		case ENOMEM:
		case EMFILE:
		case ENFILE:
#ifdef ENOBUFS
		case ENOBUFS:
#endif /* ENOBUFS */
			if (!retried) {
				retried = 1;
				errno = 0;
				rb_gc();
				goto retry;
			}
		default:
			rb_sys_fail("accept");
		}
	}
	client_io = sock_for_fd(a->accepted_class, client_fd);
	post_accept(a->accept_io, client_io);

	if (a->addr)
		in_addr_set(client_io,
		            (struct sockaddr_storage *)a->addr, *a->addrlen);
	else
		rb_ivar_set(client_io, iv_kgio_addr, localhost);
	return client_io;
}

/*
 * call-seq:
 *
 *	io.kgio_addr! => refreshes the given sock address
 */
static VALUE addr_bang(VALUE io)
{
	int fd = my_fileno(io);
	struct sockaddr_storage addr;
	socklen_t len = sizeof(struct sockaddr_storage);

	if (getpeername(fd, (struct sockaddr *)&addr, &len) != 0)
		rb_sys_fail("getpeername");

	if (addr.ss_family == AF_UNIX)
		return rb_ivar_set(io, iv_kgio_addr, localhost);

	return in_addr_set(io, &addr, len);
}

/*
 * call-seq:
 *
 *	server = Kgio::TCPServer.new('0.0.0.0', 80)
 *	server.kgio_tryaccept -> Kgio::Socket or nil
 *	server.kgio_tryaccept(klass = MySocket) -> MySocket or nil
 *	server.kgio_tryaccept(nil, flags) -> Kgio::Socket or nil
 *
 * Initiates a non-blocking accept and returns a generic Kgio::Socket
 * object with the kgio_addr attribute set to the IP address of the
 * connected client on success.
 *
 * Returns nil on EAGAIN, and raises on other errors.
 *
 * An optional +klass+ argument may be specified to override the
 * Kgio::Socket-class on a successful return value.
 *
 * An optional +flags+ argument may also be specified.
 * +flags+ is a bitmask that may contain any combination of:
 *
 * - Kgio::SOCK_CLOEXEC - close-on-exec flag (enabled by default)
 * - Kgio::SOCK_NONBLOCK - non-blocking flag (unimportant)
 */
static VALUE tcp_tryaccept(int argc, VALUE *argv, VALUE self)
{
	struct sockaddr_storage addr;
	socklen_t addrlen = sizeof(struct sockaddr_storage);
	struct accept_args a;

	a.addr = (struct sockaddr *)&addr;
	a.addrlen = &addrlen;
	prepare_accept(&a, self, argc, argv);
	return my_accept(&a, 1);
}

/*
 * call-seq:
 *
 *	server = Kgio::TCPServer.new('0.0.0.0', 80)
 *	server.kgio_accept -> Kgio::Socket or nil
 *	server.kgio_tryaccept -> Kgio::Socket or nil
 *	server.kgio_tryaccept(klass = MySocket) -> MySocket or nil
 *
 * Initiates a blocking accept and returns a generic Kgio::Socket
 * object with the kgio_addr attribute set to the IP address of
 * the client on success.
 *
 * On Ruby implementations using native threads, this can use a blocking
 * accept(2) (or accept4(2)) system call to avoid thundering herds.
 *
 * An optional +klass+ argument may be specified to override the
 * Kgio::Socket-class on a successful return value.
 *
 * An optional +flags+ argument may also be specified.
 * +flags+ is a bitmask that may contain any combination of:
 *
 * - Kgio::SOCK_CLOEXEC - close-on-exec flag (enabled by default)
 * - Kgio::SOCK_NONBLOCK - non-blocking flag (unimportant)
 */
static VALUE tcp_accept(int argc, VALUE *argv, VALUE self)
{
	struct sockaddr_storage addr;
	socklen_t addrlen = sizeof(struct sockaddr_storage);
	struct accept_args a;

	a.addr = (struct sockaddr *)&addr;
	a.addrlen = &addrlen;
	prepare_accept(&a, self, argc, argv);
	return my_accept(&a, 0);
}

/*
 * call-seq:
 *
 *	server = Kgio::UNIXServer.new("/path/to/unix/socket")
 *	server.kgio_tryaccept -> Kgio::Socket or nil
 *	server.kgio_tryaccept(klass = MySocket) -> MySocket or nil
 *	server.kgio_tryaccept(nil, flags) -> Kgio::Socket or nil
 *
 * Initiates a non-blocking accept and returns a generic Kgio::Socket
 * object with the kgio_addr attribute set (to the value of
 * Kgio::LOCALHOST) on success.
 *
 * An optional +klass+ argument may be specified to override the
 * Kgio::Socket-class on a successful return value.
 *
 * An optional +flags+ argument may also be specified.
 * +flags+ is a bitmask that may contain any combination of:
 *
 * - Kgio::SOCK_CLOEXEC - close-on-exec flag (enabled by default)
 * - Kgio::SOCK_NONBLOCK - non-blocking flag (unimportant)
 */
static VALUE unix_tryaccept(int argc, VALUE *argv, VALUE self)
{
	struct accept_args a;

	a.addr = NULL;
	a.addrlen = NULL;
	prepare_accept(&a, self, argc, argv);
	return my_accept(&a, 1);
}

/*
 * call-seq:
 *
 *	server = Kgio::UNIXServer.new("/path/to/unix/socket")
 *	server.kgio_accept -> Kgio::Socket or nil
 *	server.kgio_accept(klass = MySocket) -> MySocket or nil
 *	server.kgio_accept(nil, flags) -> Kgio::Socket or nil
 *
 * Initiates a blocking accept and returns a generic Kgio::Socket
 * object with the kgio_addr attribute set (to the value of
 * Kgio::LOCALHOST) on success.
 *
 * On Ruby implementations using native threads, this can use a blocking
 * accept(2) (or accept4(2)) system call to avoid thundering herds.
 *
 * An optional +klass+ argument may be specified to override the
 * Kgio::Socket-class on a successful return value.
 *
 * An optional +flags+ argument may also be specified.
 * +flags+ is a bitmask that may contain any combination of:
 *
 * - Kgio::SOCK_CLOEXEC - close-on-exec flag (enabled by default)
 * - Kgio::SOCK_NONBLOCK - non-blocking flag (unimportant)
 */
static VALUE unix_accept(int argc, VALUE *argv, VALUE self)
{
	struct accept_args a;

	a.addr = NULL;
	a.addrlen = NULL;
	prepare_accept(&a, self, argc, argv);
	return my_accept(&a, 0);
}

/*
 * call-seq:
 *
 *	Kgio.accept_cloexec? -> true or false
 *
 * Returns true if newly accepted Kgio::Sockets are created with the
 * FD_CLOEXEC file descriptor flag, false if not.
 *
 * Deprecated, use the per-socket flags for kgio_*accept instead.
 */
static VALUE get_cloexec(VALUE mod)
{
	return (accept4_flags & SOCK_CLOEXEC) == SOCK_CLOEXEC ? Qtrue : Qfalse;
}

/*
 *
 * call-seq:
 *
 *	Kgio.accept_nonblock? -> true or false
 *
 * Returns true if newly accepted Kgio::Sockets are created with the
 * O_NONBLOCK file status flag, false if not.
 *
 * Deprecated, use the per-socket flags for kgio_*accept instead.
 */
static VALUE get_nonblock(VALUE mod)
{
	return (accept4_flags & SOCK_NONBLOCK)==SOCK_NONBLOCK ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *
 *	Kgio.accept_cloexec = true
 *	Kgio.accept_cloexec = false
 *
 * Sets whether or not Kgio::Socket objects created by
 * TCPServer#kgio_accept,
 * TCPServer#kgio_tryaccept,
 * UNIXServer#kgio_accept,
 * and UNIXServer#kgio_tryaccept
 * default to being created with the FD_CLOEXEC file descriptor flag.
 *
 * This is on by default, as there is little reason to deal to enable
 * it for client sockets on a socket server.
 *
 * Deprecated, use the per-socket flags for kgio_*accept instead.
 */
static VALUE set_cloexec(VALUE mod, VALUE boolean)
{
	switch (TYPE(boolean)) {
	case T_TRUE:
		accept4_flags |= SOCK_CLOEXEC;
		return boolean;
	case T_FALSE:
		accept4_flags &= ~SOCK_CLOEXEC;
		return boolean;
	}
	rb_raise(rb_eTypeError, "not true or false");
	return Qnil;
}

/*
 * call-seq:
 *
 *	Kgio.accept_nonblock = true
 *	Kgio.accept_nonblock = false
 *
 * Sets whether or not Kgio::Socket objects created by
 * TCPServer#kgio_accept,
 * TCPServer#kgio_tryaccept,
 * UNIXServer#kgio_accept,
 * and UNIXServer#kgio_tryaccept
 * are created with the O_NONBLOCK file status flag.
 *
 * This defaults to +false+ for GNU/Linux where MSG_DONTWAIT is
 * available (and on newer GNU/Linux, accept4() may also set
 * the non-blocking flag.  This defaults to +true+ on non-GNU/Linux
 * systems.
 *
 * This is always true on Ruby implementations using user-space threads.
 *
 * Deprecated, use the per-socket flags for kgio_*accept instead.
 */
static VALUE set_nonblock(VALUE mod, VALUE boolean)
{
	switch (TYPE(boolean)) {
	case T_TRUE:
		accept4_flags |= SOCK_NONBLOCK;
		return boolean;
	case T_FALSE:
		accept4_flags &= ~SOCK_NONBLOCK;
		return boolean;
	}
	rb_raise(rb_eTypeError, "not true or false");
	return Qnil;
}

void init_kgio_accept(void)
{
	VALUE cUNIXServer, cTCPServer;
	VALUE mKgio = rb_define_module("Kgio");

	/*
	 * Maps to the SOCK_NONBLOCK constant in Linux for setting
	 * the non-blocking flag on newly accepted sockets.  This is
	 * usually unnecessary as sockets are made non-blocking
	 * whenever non-blocking methods are used.
	 */
	rb_define_const(mKgio, "SOCK_NONBLOCK", INT2NUM(SOCK_NONBLOCK));

	/*
	 * Maps to the SOCK_CLOEXEC constant in Linux for setting
	 * the close-on-exec flag on newly accepted descriptors.  This
	 * is enabled by default, and there is usually no reason to
	 * disable close-on-exec for accepted sockets.
	 */
	rb_define_const(mKgio, "SOCK_CLOEXEC", INT2NUM(SOCK_CLOEXEC));

	localhost = rb_const_get(mKgio, rb_intern("LOCALHOST"));
	cKgio_Socket = rb_const_get(mKgio, rb_intern("Socket"));
	cClientSocket = cKgio_Socket;
	mSocketMethods = rb_const_get(mKgio, rb_intern("SocketMethods"));

	rb_define_method(mSocketMethods, "kgio_addr!", addr_bang, 0);

	rb_define_singleton_method(mKgio, "accept_cloexec?", get_cloexec, 0);
	rb_define_singleton_method(mKgio, "accept_cloexec=", set_cloexec, 1);
	rb_define_singleton_method(mKgio, "accept_nonblock?", get_nonblock, 0);
	rb_define_singleton_method(mKgio, "accept_nonblock=", set_nonblock, 1);
	rb_define_singleton_method(mKgio, "accept_class=", set_accepted, 1);
	rb_define_singleton_method(mKgio, "accept_class", get_accepted, 0);

	/*
	 * Document-class: Kgio::UNIXServer
	 *
	 * Kgio::UNIXServer should be used in place of the plain UNIXServer
	 * when kgio_accept and kgio_tryaccept methods are needed.
	 */
	cUNIXServer = rb_const_get(rb_cObject, rb_intern("UNIXServer"));
	cUNIXServer = rb_define_class_under(mKgio, "UNIXServer", cUNIXServer);
	rb_define_method(cUNIXServer, "kgio_tryaccept", unix_tryaccept, -1);
	rb_define_method(cUNIXServer, "kgio_accept", unix_accept, -1);

	/*
	 * Document-class: Kgio::TCPServer
	 *
	 * Kgio::TCPServer should be used in place of the plain TCPServer
	 * when kgio_accept and kgio_tryaccept methods are needed.
	 */
	cTCPServer = rb_const_get(rb_cObject, rb_intern("TCPServer"));
	cTCPServer = rb_define_class_under(mKgio, "TCPServer", cTCPServer);

	rb_define_method(cTCPServer, "kgio_tryaccept", tcp_tryaccept, -1);
	rb_define_method(cTCPServer, "kgio_accept", tcp_accept, -1);
	init_sock_for_fd();
	iv_kgio_addr = rb_intern("@kgio_addr");
}
