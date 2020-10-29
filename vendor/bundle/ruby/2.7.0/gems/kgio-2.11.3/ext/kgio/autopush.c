/*
 * We use a very basic strategy to use TCP_CORK semantics optimally
 * in most TCP servers:  On corked sockets, we will uncork on recv()
 * if there was a previous send().  Otherwise we do not fiddle
 * with TCP_CORK at all.
 *
 * Under Linux, we can rely on TCP_CORK being inherited in an
 * accept()-ed client socket so we can avoid syscalls for each
 * accept()-ed client if we know the accept() socket corks.
 *
 * This module does NOTHING for client TCP sockets, we only deal
 * with accept()-ed sockets right now.
 */

#include "kgio.h"
#include "my_fileno.h"
#include <netinet/tcp.h>

/*
 * As of FreeBSD 4.5, TCP_NOPUSH == TCP_CORK
 * ref: http://dotat.at/writing/nopush.html
 * We won't care for older FreeBSD since nobody runs Ruby on them...
 */
#ifdef TCP_CORK
#  define KGIO_NOPUSH TCP_CORK
#elif defined(TCP_NOPUSH)
#  define KGIO_NOPUSH TCP_NOPUSH
#endif

#ifdef KGIO_NOPUSH
static ID id_autopush_state;
static int enabled = 1;

enum autopush_state {
	AUTOPUSH_STATE_ACCEPTOR_IGNORE = -1,
	AUTOPUSH_STATE_IGNORE = 0,
	AUTOPUSH_STATE_WRITER = 1,
	AUTOPUSH_STATE_WRITTEN = 2,
	AUTOPUSH_STATE_ACCEPTOR = 3
};

#if defined(R_CAST) && \
    defined(HAVE_TYPE_STRUCT_RFILE) && \
    defined(HAVE_TYPE_STRUCT_ROBJECT) && \
    ((SIZEOF_STRUCT_RFILE + SIZEOF_INT) <= (SIZEOF_STRUCT_ROBJECT))

struct AutopushSocket {
	struct RFile rfile;
	enum autopush_state autopush_state;
};

static enum autopush_state state_get(VALUE io)
{
	return ((struct AutopushSocket *)(io))->autopush_state;
}

static void state_set(VALUE io, enum autopush_state state)
{
	((struct AutopushSocket *)(io))->autopush_state = state;
}
#else
static enum autopush_state state_get(VALUE io)
{
	VALUE val;

	if (rb_ivar_defined(io, id_autopush_state) == Qfalse)
		return AUTOPUSH_STATE_IGNORE;
	val = rb_ivar_get(io, id_autopush_state);

	return (enum autopush_state)NUM2INT(val);
}

static void state_set(VALUE io, enum autopush_state state)
{
	rb_ivar_set(io, id_autopush_state, INT2NUM(state));
}
#endif /* IVAR fallback */

static enum autopush_state detect_acceptor_state(VALUE io);
static void push_pending_data(VALUE io);

/*
 * call-seq:
 *	Kgio.autopush? -> true or false
 *
 * Returns whether or not autopush is enabled.
 *
 * Only available on systems with TCP_CORK (Linux) or
 * TCP_NOPUSH (FreeBSD, and maybe other *BSDs).
 */
static VALUE s_get_autopush(VALUE self)
{
	return enabled ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *	Kgio.autopush = true
 *	Kgio.autopush = false
 *
 * Enables or disables autopush for sockets created with kgio_accept
 * and kgio_tryaccept methods.  Autopush relies on TCP_CORK/TCP_NOPUSH
 * being enabled on the listen socket.
 *
 * Only available on systems with TCP_CORK (Linux) or
 * TCP_NOPUSH (FreeBSD, and maybe other *BSDs).
 *
 * Please do not use this (or kgio at all) in new code.  Under Linux,
 * use MSG_MORE, instead, as it requires fewer syscalls.  Users of
 * other systems are encouraged to add MSG_MORE support to their
 * favorite OS.
 */
static VALUE s_set_autopush(VALUE self, VALUE val)
{
	enabled = RTEST(val);

	return val;
}

/*
 * call-seq:
 *
 *	io.kgio_autopush?  -> true or false
 *
 * Returns the current autopush state of the Kgio::SocketMethods-enabled
 * socket.
 *
 * Only available on systems with TCP_CORK (Linux) or
 * TCP_NOPUSH (FreeBSD, and maybe other *BSDs).
 */
static VALUE autopush_get(VALUE io)
{
	return state_get(io) <= 0 ? Qfalse : Qtrue;
}

/*
 * call-seq:
 *
 *	io.kgio_autopush = true
 *	io.kgio_autopush = false
 *
 * Enables or disables autopush on any given Kgio::SocketMethods-capable
 * IO object.  This does NOT enable or disable TCP_NOPUSH/TCP_CORK right
 * away, that must be done with IO.setsockopt
 *
 * Only available on systems with TCP_CORK (Linux) or
 * TCP_NOPUSH (FreeBSD, and maybe other *BSDs).
 */
static VALUE autopush_set(VALUE io, VALUE vbool)
{
	if (RTEST(vbool))
		state_set(io, AUTOPUSH_STATE_WRITER);
	else
		state_set(io, AUTOPUSH_STATE_IGNORE);
	return vbool;
}

void init_kgio_autopush(void)
{
	VALUE mKgio = rb_define_module("Kgio");
	VALUE tmp;

	rb_define_singleton_method(mKgio, "autopush?", s_get_autopush, 0);
	rb_define_singleton_method(mKgio, "autopush=", s_set_autopush, 1);

	tmp = rb_define_module_under(mKgio, "SocketMethods");
	rb_define_method(tmp, "kgio_autopush=", autopush_set, 1);
	rb_define_method(tmp, "kgio_autopush?", autopush_get, 0);

	id_autopush_state = rb_intern("@kgio_autopush_state");
}

/*
 * called after a successful write, just mark that we've put something
 * in the skb and will need to uncork on the next write.
 */
void kgio_autopush_send(VALUE io)
{
	if (state_get(io) == AUTOPUSH_STATE_WRITER)
		state_set(io, AUTOPUSH_STATE_WRITTEN);
}

/* called on successful accept() */
void kgio_autopush_accept(VALUE accept_io, VALUE client_io)
{
	enum autopush_state acceptor_state;

	if (!enabled)
		return;
	acceptor_state = state_get(accept_io);
	if (acceptor_state == AUTOPUSH_STATE_IGNORE)
		acceptor_state = detect_acceptor_state(accept_io);
	if (acceptor_state == AUTOPUSH_STATE_ACCEPTOR)
		state_set(client_io, AUTOPUSH_STATE_WRITER);
	else
		state_set(client_io, AUTOPUSH_STATE_IGNORE);
}

void kgio_autopush_recv(VALUE io)
{
	if (enabled && (state_get(io) == AUTOPUSH_STATE_WRITTEN)) {
		push_pending_data(io);
		state_set(io, AUTOPUSH_STATE_WRITER);
	}
}

static enum autopush_state detect_acceptor_state(VALUE io)
{
	int corked = 0;
	int fd = my_fileno(io);
	socklen_t optlen = sizeof(int);
	enum autopush_state state;

	if (getsockopt(fd, IPPROTO_TCP, KGIO_NOPUSH, &corked, &optlen) != 0) {
		if (errno != EOPNOTSUPP)
			rb_sys_fail("getsockopt(TCP_CORK/TCP_NOPUSH)");
		errno = 0;
		state = AUTOPUSH_STATE_ACCEPTOR_IGNORE;
	} else if (corked) {
		state = AUTOPUSH_STATE_ACCEPTOR;
	} else {
		state = AUTOPUSH_STATE_ACCEPTOR_IGNORE;
	}
	state_set(io, state);

	return state;
}

/*
 * checks to see if we've written anything since the last recv()
 * If we have, uncork the socket and immediately recork it.
 */
static void push_pending_data(VALUE io)
{
	int optval = 0;
	const socklen_t optlen = sizeof(int);
	const int fd = my_fileno(io);

	if (setsockopt(fd, IPPROTO_TCP, KGIO_NOPUSH, &optval, optlen) != 0)
		rb_sys_fail("setsockopt(TCP_CORK/TCP_NOPUSH, 0)");
	/* immediately recork */
	optval = 1;
	if (setsockopt(fd, IPPROTO_TCP, KGIO_NOPUSH, &optval, optlen) != 0)
		rb_sys_fail("setsockopt(TCP_CORK/TCP_NOPUSH, 1)");
}
#else /* !KGIO_NOPUSH */
void kgio_autopush_recv(VALUE io){}
void kgio_autopush_send(VALUE io){}
void init_kgio_autopush(void)
{
}
#endif /* ! KGIO_NOPUSH */
