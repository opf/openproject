/*
 * Generic C functions and macros go here, there are no dependencies
 * on Unicorn internal structures or the Ruby C API in here.
 */

#ifndef UH_util_h
#define UH_util_h

#include <unistd.h>
#include <assert.h>

#define MIN(a,b) (a < b ? a : b)
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

#ifndef SIZEOF_OFF_T
#  define SIZEOF_OFF_T 4
#  warning SIZEOF_OFF_T not defined, guessing 4.  Did you run extconf.rb?
#endif

#if SIZEOF_OFF_T == 4
#  define UH_OFF_T_MAX 0x7fffffff
#elif SIZEOF_OFF_T == 8
#  if SIZEOF_LONG == 4
#    define UH_OFF_T_MAX 0x7fffffffffffffffLL
#  else
#    define UH_OFF_T_MAX 0x7fffffffffffffff
#  endif
#else
#  error off_t size unknown for this platform!
#endif /* SIZEOF_OFF_T check */

/*
 * ragel enforces fpc as a const, and merely casting can make picky
 * compilers unhappy, so we have this little helper do our dirty work
 */
static inline void *deconst(const void *in)
{
  union { const void *in; void *out; } tmp;

  tmp.in = in;

  return tmp.out;
}

/*
 * capitalizes all lower-case ASCII characters and converts dashes
 * to underscores for HTTP headers.  Locale-agnostic.
 */
static void snake_upcase_char(char *c)
{
  if (*c >= 'a' && *c <= 'z')
    *c &= ~0x20;
  else if (*c == '-')
    *c = '_';
}

/* Downcases a single ASCII character.  Locale-agnostic. */
static void downcase_char(char *c)
{
  if (*c >= 'A' && *c <= 'Z')
    *c |= 0x20;
}

static int hexchar2int(int xdigit)
{
  if (xdigit >= 'A' && xdigit <= 'F')
    return xdigit - 'A' + 10;
  if (xdigit >= 'a' && xdigit <= 'f')
    return xdigit - 'a' + 10;

  /* Ragel already does runtime range checking for us in Unicorn: */
  assert(xdigit >= '0' && xdigit <= '9' && "invalid digit character");

  return xdigit - '0';
}

/*
 * multiplies +i+ by +base+ and increments the result by the parsed
 * integer value of +xdigit+.  +xdigit+ is a character byte
 * representing a number the range of 0..(base-1)
 * returns the new value of +i+ on success
 * returns -1 on errors (including overflow)
 */
static off_t step_incr(off_t i, int xdigit, const int base)
{
  static const off_t max = UH_OFF_T_MAX;
  const off_t next_max = (max - (max % base)) / base;
  off_t offset = hexchar2int(xdigit);

  if (offset > (base - 1))
    return -1;
  if (i > next_max)
    return -1;
  i *= base;

  if ((offset > (base - 1)) || ((max - i) < offset))
    return -1;

  return i + offset;
}

/*
 * parses a non-negative length according to base-10 and
 * returns it as an off_t value.  Returns -1 on errors
 * (including overflow).
 */
static off_t parse_length(const char *value, size_t length)
{
  off_t rv;

  for (rv = 0; length-- && rv >= 0; ++value) {
    if (*value >= '0' && *value <= '9')
      rv = step_incr(rv, *value, 10);
    else
      return -1;
  }

  return rv;
}

#define CONST_MEM_EQ(const_p, buf, len) \
  ((sizeof(const_p) - 1) == len && !memcmp(const_p, buf, sizeof(const_p) - 1))

#endif /* UH_util_h */
