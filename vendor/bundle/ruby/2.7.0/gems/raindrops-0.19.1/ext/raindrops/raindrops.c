#include <ruby.h>
#include <unistd.h>
#include <sys/mman.h>
#include <assert.h>
#include <errno.h>
#include <stddef.h>
#include "raindrops_atomic.h"

#ifndef SIZET2NUM
#  define SIZET2NUM(x) ULONG2NUM(x)
#endif
#ifndef NUM2SIZET
#  define NUM2SIZET(x) NUM2ULONG(x)
#endif

/*
 * most modern CPUs have a cache-line size of 64 or 128.
 * We choose a bigger one by default since our structure is not
 * heavily used
 */
static size_t raindrop_size = 128;
static size_t rd_page_size;

#define PAGE_MASK               (~(rd_page_size - 1))
#define PAGE_ALIGN(addr)        (((addr) + rd_page_size - 1) & PAGE_MASK)

/* each raindrop is a counter */
struct raindrop {
	unsigned long counter;
} __attribute__((packed));

/* allow mmap-ed regions to store more than one raindrop */
struct raindrops {
	size_t size;
	size_t capa;
	pid_t pid;
	struct raindrop *drops;
};

/* called by GC */
static void rd_free(void *ptr)
{
	struct raindrops *r = ptr;

	if (r->drops != MAP_FAILED) {
		int rv = munmap(r->drops, raindrop_size * r->capa);
		if (rv != 0)
			rb_bug("munmap failed in gc: %s", strerror(errno));
	}

	xfree(ptr);
}

static size_t rd_memsize(const void *ptr)
{
	const struct raindrops *r = ptr;

	return r->drops == MAP_FAILED ? 0 : raindrop_size * r->capa;
}

static const rb_data_type_t rd_type = {
	"raindrops",
	{ NULL, rd_free, rd_memsize, /* reserved */ },
	/* parent, data, [ flags ] */
};

/* automatically called at creation (before initialize) */
static VALUE alloc(VALUE klass)
{
	struct raindrops *r;
	VALUE rv = TypedData_Make_Struct(klass, struct raindrops, &rd_type, r);

	r->drops = MAP_FAILED;
	return rv;
}

static struct raindrops *get(VALUE self)
{
	struct raindrops *r;

	TypedData_Get_Struct(self, struct raindrops, &rd_type, r);

	if (r->drops == MAP_FAILED)
		rb_raise(rb_eStandardError, "invalid or freed Raindrops");

	return r;
}

/*
 * call-seq:
 *	Raindrops.new(size)	-> raindrops object
 *
 * Initializes a Raindrops object to hold +size+ counters.  +size+ is
 * only a hint and the actual number of counters the object has is
 * dependent on the CPU model, number of cores, and page size of
 * the machine.  The actual size of the object will always be equal
 * or greater than the specified +size+.
 */
static VALUE init(VALUE self, VALUE size)
{
	struct raindrops *r = DATA_PTR(self);
	int tries = 1;
	size_t tmp;

	if (r->drops != MAP_FAILED)
		rb_raise(rb_eRuntimeError, "already initialized");

	r->size = NUM2SIZET(size);
	if (r->size < 1)
		rb_raise(rb_eArgError, "size must be >= 1");

	tmp = PAGE_ALIGN(raindrop_size * r->size);
	r->capa = tmp / raindrop_size;
	assert(PAGE_ALIGN(raindrop_size * r->capa) == tmp && "not aligned");

retry:
	r->drops = mmap(NULL, tmp,
	                PROT_READ|PROT_WRITE, MAP_ANON|MAP_SHARED, -1, 0);
	if (r->drops == MAP_FAILED) {
		int err = errno;

		if ((err == EAGAIN || err == ENOMEM) && tries-- > 0) {
			rb_gc();
			goto retry;
		}
		rb_sys_fail("mmap");
	}
	r->pid = getpid();

	return self;
}

/*
 * mremap() is currently broken with MAP_SHARED
 * https://bugzilla.kernel.org/show_bug.cgi?id=8691
 */
#if defined(HAVE_MREMAP) && !defined(MREMAP_WORKS_WITH_MAP_SHARED)
#  undef HAVE_MREMAP
#endif

#ifdef HAVE_MREMAP
#ifndef MREMAP_MAYMOVE
#  warn MREMAP_MAYMOVE undefined
#  define MREMAP_MAYMOVE 0
#endif
static void resize(struct raindrops *r, size_t new_rd_size)
{
	size_t old_size = raindrop_size * r->capa;
	size_t new_size = PAGE_ALIGN(raindrop_size * new_rd_size);
	void *old_address = r->drops;
	void *rv;

	if (r->pid != getpid())
		rb_raise(rb_eRuntimeError, "cannot mremap() from child");

	rv = mremap(old_address, old_size, new_size, MREMAP_MAYMOVE);
	if (rv == MAP_FAILED) {
		int err = errno;

		if (err == EAGAIN || err == ENOMEM) {
			rb_gc();
			rv = mremap(old_address, old_size, new_size, 0);
		}
		if (rv == MAP_FAILED)
			rb_sys_fail("mremap");
	}
	r->drops = rv;
	r->size = new_rd_size;
	r->capa = new_size / raindrop_size;
	assert(r->capa >= r->size && "bad sizing");
}
#else /* ! HAVE_MREMAP */
/*
 * we cannot use munmap + mmap to reallocate the buffer since it may
 * already be shared by other processes, so we just fail
 */
static void resize(struct raindrops *r, size_t new_rd_size)
{
	rb_raise(rb_eRangeError, "mremap(2) is not available");
}
#endif /* ! HAVE_MREMAP */

/*
 * call-seq:
 *	rd.size = new_size
 *
 * Increases or decreases the current capacity of our Raindrop.
 * Raises RangeError if +new_size+ is too big or small for the
 * current backing store
 */
static VALUE setsize(VALUE self, VALUE new_size)
{
	size_t new_rd_size = NUM2SIZET(new_size);
	struct raindrops *r = get(self);

	if (new_rd_size <= r->capa)
		r->size = new_rd_size;
	else
		resize(r, new_rd_size);

	return new_size;
}

/*
 * call-seq:
 *	rd.capa		-> Integer
 *
 * Returns the number of slots allocated (but not necessarily used) by
 * the Raindrops object.
 */
static VALUE capa(VALUE self)
{
	return SIZET2NUM(get(self)->capa);
}

/*
 * call-seq:
 *	rd.dup		-> rd_copy
 *
 * Duplicates and snapshots the current state of a Raindrops object.
 */
static VALUE init_copy(VALUE dest, VALUE source)
{
	struct raindrops *dst = DATA_PTR(dest);
	struct raindrops *src = get(source);

	init(dest, SIZET2NUM(src->size));
	memcpy(dst->drops, src->drops, raindrop_size * src->size);

	return dest;
}

static unsigned long *addr_of(VALUE self, VALUE index)
{
	struct raindrops *r = get(self);
	unsigned long off = FIX2ULONG(index) * raindrop_size;

	if (off >= raindrop_size * r->size)
		rb_raise(rb_eArgError, "offset overrun");

	return (unsigned long *)((unsigned long)r->drops + off);
}

static unsigned long incr_decr_arg(int argc, const VALUE *argv)
{
	if (argc > 2 || argc < 1)
		rb_raise(rb_eArgError,
		         "wrong number of arguments (%d for 1+)", argc);

	return argc == 2 ? NUM2ULONG(argv[1]) : 1;
}

/*
 * call-seq:
 *	rd.incr(index[, number])	-> result
 *
 * Increments the value referred to by the +index+ by +number+.
 * +number+ defaults to +1+ if unspecified.
 */
static VALUE incr(int argc, VALUE *argv, VALUE self)
{
	unsigned long nr = incr_decr_arg(argc, argv);

	return ULONG2NUM(__sync_add_and_fetch(addr_of(self, argv[0]), nr));
}

/*
 * call-seq:
 *	rd.decr(index[, number])	-> result
 *
 * Decrements the value referred to by the +index+ by +number+.
 * +number+ defaults to +1+ if unspecified.
 */
static VALUE decr(int argc, VALUE *argv, VALUE self)
{
	unsigned long nr = incr_decr_arg(argc, argv);

	return ULONG2NUM(__sync_sub_and_fetch(addr_of(self, argv[0]), nr));
}

/*
 * call-seq:
 *	rd.to_ary	-> Array
 *
 * converts the Raindrops structure to an Array
 */
static VALUE to_ary(VALUE self)
{
	struct raindrops *r = get(self);
	VALUE rv = rb_ary_new2(r->size);
	size_t i;
	unsigned long base = (unsigned long)r->drops;

	for (i = 0; i < r->size; i++) {
		rb_ary_push(rv, ULONG2NUM(*((unsigned long *)base)));
		base += raindrop_size;
	}

	return rv;
}

/*
 * call-seq:
 *	rd.size		-> Integer
 *
 * Returns the number of counters a Raindrops object can hold.  Due to
 * page alignment, this is always equal or greater than the number of
 * requested slots passed to Raindrops.new
 */
static VALUE size(VALUE self)
{
	return SIZET2NUM(get(self)->size);
}

/*
 * call-seq:
 *	rd[index] = value
 *
 * Assigns +value+ to the slot designated by +index+
 */
static VALUE aset(VALUE self, VALUE index, VALUE value)
{
	unsigned long *addr = addr_of(self, index);

	*addr = NUM2ULONG(value);

	return value;
}

/*
 * call-seq:
 *	rd[index]	-> value
 *
 * Returns the value of the slot designated by +index+
 */
static VALUE aref(VALUE self, VALUE index)
{
	return  ULONG2NUM(*addr_of(self, index));
}

#ifdef __linux__
void Init_raindrops_linux_inet_diag(void);
#endif
#ifdef HAVE_TYPE_STRUCT_TCP_INFO
void Init_raindrops_tcp_info(void);
#endif

#ifndef _SC_NPROCESSORS_CONF
#  if defined _SC_NPROCESSORS_ONLN
#    define _SC_NPROCESSORS_CONF _SC_NPROCESSORS_ONLN
#  elif defined _SC_NPROC_ONLN
#    define _SC_NPROCESSORS_CONF _SC_NPROC_ONLN
#  elif defined _SC_CRAY_NCPU
#    define _SC_NPROCESSORS_CONF _SC_CRAY_NCPU
#  endif
#endif

/*
 * call-seq:
 *	rd.evaporate!	-> nil
 *
 * Releases mmap()-ed memory allocated for the Raindrops object back
 * to the OS.  The Ruby garbage collector will also release memory
 * automatically when it is not needed, but this forces release
 * under high memory pressure.
 */
static VALUE evaporate_bang(VALUE self)
{
	struct raindrops *r = get(self);
	void *addr = r->drops;

	r->drops = MAP_FAILED;
	if (munmap(addr, raindrop_size * r->capa) != 0)
		rb_sys_fail("munmap");
	return Qnil;
}

void Init_raindrops_ext(void)
{
	VALUE cRaindrops = rb_define_class("Raindrops", rb_cObject);
	long tmp = 2;

#ifdef _SC_NPROCESSORS_CONF
	tmp = sysconf(_SC_NPROCESSORS_CONF);
#endif
	/* no point in padding on single CPU machines */
	if (tmp == 1)
		raindrop_size = sizeof(unsigned long);
#ifdef _SC_LEVEL1_DCACHE_LINESIZE
	if (tmp != 1) {
		tmp = sysconf(_SC_LEVEL1_DCACHE_LINESIZE);
		if (tmp > 0)
			raindrop_size = (size_t)tmp;
	}
#endif
#if defined(_SC_PAGE_SIZE)
	rd_page_size = (size_t)sysconf(_SC_PAGE_SIZE);
#elif defined(_SC_PAGESIZE)
	rd_page_size = (size_t)sysconf(_SC_PAGESIZE);
#elif defined(HAVE_GETPAGESIZE)
	rd_page_size = (size_t)getpagesize();
#elif defined(PAGE_SIZE)
	rd_page_size = (size_t)PAGE_SIZE;
#elif defined(PAGESIZE)
	rd_page_size = (size_t)PAGESIZE;
#else
#  error unable to detect page size for mmap()
#endif
	if ((rd_page_size == (size_t)-1) || (rd_page_size < raindrop_size))
		rb_raise(rb_eRuntimeError,
			 "system page size invalid: %llu",
			 (unsigned long long)rd_page_size);

	/*
	 * The size of one page of memory for a mmap()-ed Raindrops region.
	 * Typically 4096 bytes under Linux.
	 */
	rb_define_const(cRaindrops, "PAGE_SIZE", SIZET2NUM(rd_page_size));

	/*
	 * The size (in bytes) of a slot in a Raindrops object.
	 * This is the size of a word on single CPU systems and
	 * the size of the L1 cache line size if detectable.
	 *
	 * Defaults to 128 bytes if undetectable.
	 */
	rb_define_const(cRaindrops, "SIZE", SIZET2NUM(raindrop_size));

	/*
	 * The maximum value a raindrop counter can hold
	 */
	rb_define_const(cRaindrops, "MAX", ULONG2NUM((unsigned long)-1));

	rb_define_alloc_func(cRaindrops, alloc);

	rb_define_method(cRaindrops, "initialize", init, 1);
	rb_define_method(cRaindrops, "incr", incr, -1);
	rb_define_method(cRaindrops, "decr", decr, -1);
	rb_define_method(cRaindrops, "to_ary", to_ary, 0);
	rb_define_method(cRaindrops, "[]", aref, 1);
	rb_define_method(cRaindrops, "[]=", aset, 2);
	rb_define_method(cRaindrops, "size", size, 0);
	rb_define_method(cRaindrops, "size=", setsize, 1);
	rb_define_method(cRaindrops, "capa", capa, 0);
	rb_define_method(cRaindrops, "initialize_copy", init_copy, 1);
	rb_define_method(cRaindrops, "evaporate!", evaporate_bang, 0);

#ifdef __linux__
	Init_raindrops_linux_inet_diag();
#endif
#ifdef HAVE_TYPE_STRUCT_TCP_INFO
	Init_raindrops_tcp_info();
#endif
}
