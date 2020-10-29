#include "kgio.h"
#if defined(USE_KGIO_POLL)
#include "my_fileno.h"
#include <time.h>
#include "broken_system_compat.h"
#include <poll.h>
#include <errno.h>
#ifdef HAVE_RUBY_ST_H
#  include <ruby/st.h>
#else
#  include <st.h>
#endif

static VALUE sym_wait_readable, sym_wait_writable;

#ifdef HAVE_RB_HASH_CLEAR /* Ruby >= 2.0 */
#  define my_hash_clear(h) (void)rb_hash_clear(h)
#else /* !HAVE_RB_HASH_CLEAR - Ruby <= 1.9.3 */
static ID id_clear;

static void my_hash_clear(VALUE h)
{
	rb_funcall(h, id_clear, 0);
}
#endif /* HAVE_RB_HASH_CLEAR */

struct poll_args {
	struct pollfd *fds;
	nfds_t nfds;
	int timeout;
	VALUE ios;
	st_table *fd_to_io;
	struct timespec start;
};

static int interrupted(void)
{
	switch (errno) {
	case EINTR:
#ifdef ERESTART
	case ERESTART:
#endif
		return 1;
	}
	return 0;
}

static int retryable(struct poll_args *a)
{
	struct timespec ts;

	if (a->timeout < 0)
		return 1;

	clock_gettime(hopefully_CLOCK_MONOTONIC, &ts);

	ts.tv_sec -= a->start.tv_sec;
	ts.tv_nsec -= a->start.tv_nsec;
	if (ts.tv_nsec < 0) {
		ts.tv_sec--;
		ts.tv_nsec += 1000000000;
	}
	a->timeout -= ts.tv_sec * 1000;
	a->timeout -= ts.tv_nsec / 1000000;
	if (a->timeout < 0)
		a->timeout = 0;
	return 1;
}

static int num2timeout(VALUE timeout)
{
	switch (TYPE(timeout)) {
	case T_NIL: return -1;
	case T_FIXNUM: return FIX2INT(timeout);
	case T_BIGNUM: return NUM2INT(timeout);
	}
        rb_raise(rb_eTypeError, "timeout must be integer or nil");
        return 0;
}

static VALUE poll_free(VALUE args)
{
	struct poll_args *a = (struct poll_args *)args;

	if (a->fds)
		xfree(a->fds);
	if (a->fd_to_io)
		st_free_table(a->fd_to_io);

	return Qnil;
}

static short value2events(VALUE event)
{
	if (event == sym_wait_readable) return POLLIN;
	if (event == sym_wait_writable) return POLLOUT;
	if (TYPE(event) == T_FIXNUM) return (short)FIX2INT(event);
	rb_raise(rb_eArgError, "unrecognized event");
}

static int io_to_pollfd_i(VALUE key, VALUE value, VALUE args)
{
	struct poll_args *a = (struct poll_args *)args;
	struct pollfd *pollfd = &a->fds[a->nfds++];

	pollfd->fd = my_fileno(key);
	pollfd->events = value2events(value);
	st_insert(a->fd_to_io, (st_data_t)pollfd->fd, (st_data_t)key);
	return ST_CONTINUE;
}

static void hash2pollfds(struct poll_args *a)
{
	a->nfds = 0;
	a->fds = xmalloc(sizeof(struct pollfd) * RHASH_SIZE(a->ios));
	a->fd_to_io = st_init_numtable();
	rb_hash_foreach(a->ios, io_to_pollfd_i, (VALUE)a);
}

static void * nogvl_poll(void *ptr)
{
	struct poll_args *a = ptr;
	long n;

	if (a->timeout > 0)
		clock_gettime(hopefully_CLOCK_MONOTONIC, &a->start);

	n = poll(a->fds, a->nfds, a->timeout);
	return (void *)n;
}

static VALUE poll_result(int nr, struct poll_args *a)
{
	struct pollfd *fds = a->fds;
	VALUE io;
	int rc;

	if ((nfds_t)nr != a->nfds)
		my_hash_clear(a->ios);
	for (; nr > 0; fds++) {
		if (fds->revents == 0)
			continue;
		--nr;
		rc = st_lookup(a->fd_to_io, (st_data_t)fds->fd, &io);
		assert(rc == 1 && "fd => IO mapping failed");
		rb_hash_aset(a->ios, io, INT2FIX((int)fds->revents));
	}
	return a->ios;
}

static VALUE do_poll(VALUE args)
{
	struct poll_args *a = (struct poll_args *)args;
	long nr;

	Check_Type(a->ios, T_HASH);

retry:
	hash2pollfds(a);
	nr = (long)KGIO_WITHOUT_GVL(nogvl_poll, a, RUBY_UBF_IO, NULL);
	if (nr < 0) {
		if (interrupted()) {
			if (retryable(a)) {
				poll_free(args);
				goto retry;
			}
			return Qnil;
		}
		rb_sys_fail("poll");
	}
	if (nr == 0) return Qnil;

	return poll_result((int)nr, a);
}

/*
 * call-seq:
 *
 *	Kgio.poll({ $stdin => :wait_readable }, 100)  -> hash or nil
 *	Kgio.poll({ $stdin => Kgio::POLLIN }, 100)  -> hash or nil
 *
 * Accepts an input hash with IO objects to wait for as the key and
 * the events to wait for as its value.  The events may either be
 * +:wait_readable+ or +:wait_writable+ symbols or a Fixnum mask of
 * Kgio::POLL* constants:
 *
 *	Kgio::POLLIN      - there is data to read
 *	Kgio::POLLPRI     - there is urgent data to read
 *	Kgio::POLLOUT     - writing will not block
 *	Kgio::POLLRDHUP   - peer has shutdown writes (Linux 2.6.17+ only)
 *
 * Timeout is specified in Integer milliseconds just like the underlying
 * poll(2), not in seconds like IO.select.  A nil timeout means to wait
 * forever.  It must be an Integer or nil.
 *
 * Kgio.poll modifies and returns its input hash on success with the
 * IO-like object as the key and an Integer mask of events as the hash
 * value.  It can return any of the events specified in the input
 * above, along with the following events:
 *
 *	Kgio::POLLERR     - error condition occurred on the descriptor
 *	Kgio::POLLHUP     - hang up
 *	Kgio::POLLNVAL    - invalid request (bad file descriptor)
 *
 * This method is only available under Ruby 1.9 or any other
 * implementations that uses native threads and rb_thread_blocking_region()
 */
static VALUE s_poll(int argc, VALUE *argv, VALUE self)
{
	VALUE timeout;
	struct poll_args a;

	rb_scan_args(argc, argv, "11", &a.ios, &timeout);
	a.timeout = num2timeout(timeout);
	a.fds = NULL;
	a.fd_to_io = NULL;

	return rb_ensure(do_poll, (VALUE)&a, poll_free, (VALUE)&a);
}

void init_kgio_poll(void)
{
	VALUE mKgio = rb_define_module("Kgio");

	if (check_clock() < 0)
		return;
	rb_define_singleton_method(mKgio, "poll", s_poll, -1);

	sym_wait_readable = ID2SYM(rb_intern("wait_readable"));
	sym_wait_writable = ID2SYM(rb_intern("wait_writable"));
#ifndef HAVE_RB_HASH_CLEAR
	id_clear = rb_intern("clear");
#endif

#define c(x) rb_define_const(mKgio,#x,INT2NUM((int)x))

/* standard types */

	c(POLLIN);
	c(POLLPRI);
	c(POLLOUT);

#ifdef POLLRDHUP
	c(POLLRDHUP);
#endif

/* outputs */
	c(POLLERR);
	c(POLLHUP);
	c(POLLNVAL);
}
#else /* ! USE_KGIO_POLL */
void init_kgio_poll(void)
{
}
#endif /* ! USE_KGIO_POLL */
