/*
 * we're currently too lazy to use rb_ensure to free an allocation, so we
 * the abuse rb_str_* API for a temporary buffer
 */
#define RSTRING_MODIFIED 1

#include "kgio.h"
#include "my_fileno.h"
#include "nonblock.h"
#ifdef HAVE_WRITEV
#  include <sys/uio.h>
#  define USE_WRITEV 1
#else
#  define USE_WRITEV 0
static ssize_t assert_writev(int fd, void* iov, int len)
{
	assert(0 && "you should not try to call writev");
	return -1;
}
#  define writev assert_writev
#endif

#ifndef HAVE_RB_ARY_SUBSEQ
static inline VALUE my_ary_subseq(VALUE ary, long idx, long len)
{
       VALUE args[2] = { LONG2FIX(idx), LONG2FIX(len) };

       return rb_ary_aref(2, args, ary);
}
#define MY_ARY_SUBSEQ(ary,idx,len) my_ary_subseq((ary),(idx),(len))
#else
#define MY_ARY_SUBSEQ(ary,idx,len) rb_ary_subseq((ary),(idx),(len))
#endif

static VALUE sym_wait_writable;

#ifndef HAVE_WRITEV
#define iovec my_iovec
struct my_iovec {
	void  *iov_base;
	size_t iov_len;
};
#endif

/* tests for choosing following constants were done on Linux 3.0 x86_64
 * (Ubuntu 12.04) Core i3 i3-2330M slowed to 1600MHz
 * testing script https://gist.github.com/2850641
 * fill free to make more thorough testing and choose better value
 */

/* test shows that its meaningless to set WRITEV_MEMLIMIT more that 1M
 * even when tcp_wmem set to relatively high value (2M) (in fact, it becomes
 * even slower). 512K performs a bit better in average case. */
#define WRITEV_MEMLIMIT (512*1024)
/* same test shows that custom_writev is faster than glibc writev when
 * average string is smaller than ~500 bytes and slower when average strings
 * is greater then ~600 bytes. 512 bytes were choosen cause current compilers
 * turns x/512 into x>>9 */
#define WRITEV_IMPL_THRESHOLD 512

static int iov_max = 1024; /* this could be overriden in init */

struct wrv_args {
	VALUE io;
	VALUE buf;
	VALUE vec_buf; /* FIXME: this requires RSTRING_MODIFY for rbx */
	struct iovec *vec;
	int iov_cnt;
	size_t batch_len;
	int something_written;
	int fd;
};

static ssize_t custom_writev(int fd, const struct iovec *vec, int iov_cnt, size_t total_len)
{
	int i;
	ssize_t result;
	char *buf, *curbuf;
	const struct iovec *curvec = vec;

	/* we do not want to use ruby's xmalloc because
	 * it can fire GC, and we'll free buffer shortly anyway */
	curbuf = buf = malloc(total_len);
	if (buf == NULL) return -1;

	for (i = 0; i < iov_cnt; i++, curvec++) {
		memcpy(curbuf, curvec->iov_base, curvec->iov_len);
		curbuf += curvec->iov_len;
	}

	result = write(fd, buf, total_len);

	/* free() may alter errno */
	i = errno;
	free(buf);
	errno = i;

	return result;
}

static void prepare_writev(struct wrv_args *a, VALUE io, VALUE ary)
{
	a->io = io;
	a->fd = my_fileno(io);
	a->something_written = 0;

	if (TYPE(ary) == T_ARRAY)
		/* rb_ary_subseq will not copy array unless it modified */
		a->buf = MY_ARY_SUBSEQ(ary, 0, RARRAY_LEN(ary));
	else
		a->buf = rb_Array(ary);

	a->vec_buf = rb_str_new(0, 0);
	a->vec = NULL;
}

#ifndef RARRAY_LENINT
static inline int rarray_int(VALUE val)
{
	long num = RARRAY_LEN(val);

	if ((long)(int)num != num)
		rb_raise(rb_eRangeError, "%ld cannot to be an int", num);

	return (int)num;
}
#define RARRAY_LENINT(n) rarray_int(n)
#endif

static void fill_iovec(struct wrv_args *a)
{
	int i;
	struct iovec *curvec;

	a->iov_cnt = RARRAY_LENINT(a->buf);
	a->batch_len = 0;
	if (a->iov_cnt == 0) return;
	if (a->iov_cnt > iov_max) a->iov_cnt = iov_max;
	rb_str_resize(a->vec_buf, sizeof(struct iovec) * a->iov_cnt);
	curvec = a->vec = (struct iovec*)RSTRING_PTR(a->vec_buf);

	for (i=0; i < a->iov_cnt; i++, curvec++) {
		VALUE str = rb_ary_entry(a->buf, i);
		long str_len, next_len;

		if (TYPE(str) != T_STRING) {
			str = rb_obj_as_string(str);
			rb_ary_store(a->buf, i, str);
		}

		str_len = RSTRING_LEN(str);

		/* lets limit total memory to write,
		 * but always take first string */
		next_len = a->batch_len + str_len;
		if (i && next_len > WRITEV_MEMLIMIT) {
			a->iov_cnt = i;
			break;
		}
		a->batch_len = next_len;

		curvec->iov_base = RSTRING_PTR(str);
		curvec->iov_len = str_len;
	}
}

static long trim_writev_buffer(struct wrv_args *a, ssize_t n)
{
	long i;
	long ary_len = RARRAY_LEN(a->buf);

	if (n == (ssize_t)a->batch_len) {
		i = a->iov_cnt;
		n = 0;
	} else {
		for (i = 0; n && i < ary_len; i++) {
			VALUE entry = rb_ary_entry(a->buf, i);
			n -= (ssize_t)RSTRING_LEN(entry);
			if (n < 0) break;
		}
	}

	/* all done */
	if (i == ary_len) {
		assert(n == 0 && "writev system call is broken");
		a->buf = Qnil;
		return 0;
	}

	/* partially done, remove fully-written buffers */
	if (i > 0)
		a->buf = MY_ARY_SUBSEQ(a->buf, i, ary_len - i);

	/* setup+replace partially written buffer */
	if (n < 0) {
		VALUE str = rb_ary_entry(a->buf, 0);
		long str_len = RSTRING_LEN(str);
		str = MY_STR_SUBSEQ(str, str_len + n, -n);
		rb_ary_store(a->buf, 0, str);
	}
	return RARRAY_LEN(a->buf);
}

static long
writev_check(struct wrv_args *a, ssize_t n, const char *msg, int io_wait)
{
	if (n >= 0) {
		if (n > 0) a->something_written = 1;
		return trim_writev_buffer(a, n);
	} else if (n < 0) {
		if (errno == EINTR) {
			a->fd = my_fileno(a->io);
			return -1;
		}
		if (errno == EAGAIN) {
			if (io_wait) {
				(void)kgio_call_wait_writable(a->io);
				return -1;
			} else if (!a->something_written) {
				a->buf = sym_wait_writable;
			}
			return 0;
		}
		kgio_wr_sys_fail(msg);
	}
	return 0;
}

static VALUE my_writev(VALUE io, VALUE ary, int io_wait)
{
	struct wrv_args a;
	ssize_t n;

	prepare_writev(&a, io, ary);
	set_nonblocking(a.fd);

	do {
		fill_iovec(&a);
		if (a.iov_cnt == 0)
			n = 0;
		else if (a.iov_cnt == 1)
			n = write(a.fd, a.vec[0].iov_base, a.vec[0].iov_len);
		/* for big strings use library function */
		else if (USE_WRITEV &&
		        ((long)(a.batch_len/WRITEV_IMPL_THRESHOLD) > a.iov_cnt))
			n = writev(a.fd, a.vec, a.iov_cnt);
		else
			n = custom_writev(a.fd, a.vec, a.iov_cnt, a.batch_len);
	} while (writev_check(&a, n, "writev", io_wait) != 0);
	rb_str_resize(a.vec_buf, 0);

	if (TYPE(a.buf) != T_SYMBOL)
		kgio_autopush_write(io);
	return a.buf;
}

/*
 * call-seq:
 *
 *	io.kgio_writev(array)	-> nil
 *
 * Returns nil when the write completes.
 *
 * This may block and call any method defined to +kgio_wait_writable+
 * for the class.
 *
 * Note: it uses +Array()+ semantic for converting argument, so that
 * it will succeed if you pass something else.
 */
static VALUE kgio_writev(VALUE io, VALUE ary)
{
	return my_writev(io, ary, 1);
}

/*
 * call-seq:
 *
 *	io.kgio_trywritev(array)	-> nil, Array or :wait_writable
 *
 * Returns nil if the write was completed in full.
 *
 * Returns an Array of strings containing the unwritten portion
 * if EAGAIN was encountered, but some portion was successfully written.
 *
 * Returns :wait_writable if EAGAIN is encountered and nothing
 * was written.
 *
 * Note: it uses +Array()+ semantic for converting argument, so that
 * it will succeed if you pass something else.
 */
static VALUE kgio_trywritev(VALUE io, VALUE ary)
{
	return my_writev(io, ary, 0);
}

/*
 * call-seq:
 *
 *	Kgio.trywritev(io, array)    -> nil, Array or :wait_writable
 *
 * Returns nil if the write was completed in full.
 *
 * Returns a Array of strings containing the unwritten portion if EAGAIN
 * was encountered, but some portion was successfully written.
 *
 * Returns :wait_writable if EAGAIN is encountered and nothing
 * was written.
 *
 * Maybe used in place of PipeMethods#kgio_trywritev for non-Kgio objects
 */
static VALUE s_trywritev(VALUE mod, VALUE io, VALUE ary)
{
	return kgio_trywritev(io, ary);
}

void init_kgio_writev(void)
{
#ifdef IOV_MAX
	int sys_iov_max = IOV_MAX;
#else
	int sys_iov_max = (int)sysconf(_SC_IOV_MAX);
#endif

	VALUE mPipeMethods, mSocketMethods;
	VALUE mKgio = rb_define_module("Kgio");

	if (sys_iov_max < iov_max)
		iov_max = sys_iov_max;

	sym_wait_writable = ID2SYM(rb_intern("wait_writable"));

	rb_define_singleton_method(mKgio, "trywritev", s_trywritev, 2);

	mPipeMethods = rb_define_module_under(mKgio, "PipeMethods");
	rb_define_method(mPipeMethods, "kgio_writev", kgio_writev, 1);
	rb_define_method(mPipeMethods, "kgio_trywritev", kgio_trywritev, 1);

	mSocketMethods = rb_define_module_under(mKgio, "SocketMethods");
	rb_define_method(mSocketMethods, "kgio_writev", kgio_writev, 1);
	rb_define_method(mSocketMethods, "kgio_trywritev", kgio_trywritev, 1);
}
