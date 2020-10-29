/*
 * this header includes functions to support broken systems
 * without clock_gettime() or CLOCK_MONOTONIC
 */

#ifndef HAVE_TYPE_CLOCKID_T
typedef int clockid_t;
#endif

#ifndef HAVE_CLOCK_GETTIME
#  ifndef CLOCK_REALTIME
#    define CLOCK_REALTIME 0 /* whatever */
#  endif
static int fake_clock_gettime(clockid_t clk_id, struct timespec *res)
{
	struct timeval tv;
	int r = gettimeofday(&tv, NULL);

	assert(0 == r && "gettimeofday() broke!?");
	res->tv_sec = tv.tv_sec;
	res->tv_nsec = tv.tv_usec * 1000;

	return r;
}
#  define clock_gettime fake_clock_gettime
#endif /* broken systems w/o clock_gettime() */

/*
 * UGH
 * CLOCK_MONOTONIC is not guaranteed to be a macro, either
 */
#ifndef CLOCK_MONOTONIC
#  if (!defined(_POSIX_MONOTONIC_CLOCK) || !defined(HAVE_CLOCK_MONOTONIC))
#    define CLOCK_MONOTONIC CLOCK_REALTIME
#  endif
#endif

/*
 * Availability of a monotonic clock needs to be detected at runtime
 * since we could've been built on a different system than we're run
 * under.
 */
static clockid_t hopefully_CLOCK_MONOTONIC;

static int check_clock(void)
{
	struct timespec now;

	hopefully_CLOCK_MONOTONIC = CLOCK_MONOTONIC;

	/* we can't check this reliably at compile time */
	if (clock_gettime(CLOCK_MONOTONIC, &now) == 0)
		return 1;

	if (clock_gettime(CLOCK_REALTIME, &now) == 0) {
		hopefully_CLOCK_MONOTONIC = CLOCK_REALTIME;
		rb_warn("CLOCK_MONOTONIC not available, "
			"falling back to CLOCK_REALTIME");
		return 2;
	}
	return -1;
}
