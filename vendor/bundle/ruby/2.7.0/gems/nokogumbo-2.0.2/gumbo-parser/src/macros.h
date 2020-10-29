#ifndef MACROS_H
#define MACROS_H

#if (!defined(__STDC_VERSION__) || !(__STDC_VERSION__ >= 199901L)) \
    && !defined(_WIN32) && !defined(__cplusplus)
# error C99 compiler required
#endif

#if defined(_WIN32)
# define inline __inline
# define __func__ __FUNCTION__
#endif

// Calculate the number of elements in an array.
// The extra division on the third line is a trick to help prevent
// passing a pointer to the first element of an array instead of a
// reference to the array itself.
#define ARRAY_COUNT(x) ( \
    (sizeof(x) / sizeof((x)[0])) \
    / ((size_t)(!(sizeof(x) % sizeof((x)[0])))) \
)

#ifdef NDEBUG
    #define UNUSED_IF_NDEBUG(x) (void)(x)
#else
    #define UNUSED_IF_NDEBUG(x)
#endif

#ifdef __GNUC__
    #define GNUC_AT_LEAST(major, minor) ( \
        (__GNUC__ > major) \
        || ((__GNUC__ == major) && (__GNUC_MINOR__ >= minor)) )
#else
    #define GNUC_AT_LEAST(major, minor) 0
#endif

#ifdef __has_attribute
    #define HAS_ATTRIBUTE(x) __has_attribute(x)
#else
    #define HAS_ATTRIBUTE(x) 0
#endif

#if GNUC_AT_LEAST(3, 0) || HAS_ATTRIBUTE(unused) || defined(__TINYC__)
    #define UNUSED __attribute__((__unused__))
#else
    #define UNUSED
#endif

#if GNUC_AT_LEAST(3, 0)
    #define MALLOC __attribute__((__malloc__))
    #define PRINTF(x) __attribute__((__format__(__printf__, (x), (x + 1))))
    #define PURE __attribute__((__pure__))
    #define CONST_FN __attribute__((__const__))
#else
    #define MALLOC
    #define PRINTF(x)
    #define PURE
    #define CONST_FN
#endif

#define UNUSED_ARG(x) unused__ ## x UNUSED

#if GNUC_AT_LEAST(3, 0) && defined(__OPTIMIZE__)
    #define likely(x) __builtin_expect(!!(x), 1)
    #define unlikely(x) __builtin_expect(!!(x), 0)
#else
    #define likely(x) (x)
    #define unlikely(x) (x)
#endif

#if GNUC_AT_LEAST(3, 3) || HAS_ATTRIBUTE(nonnull)
    #define NONNULL_ARGS __attribute__((__nonnull__))
#else
    #define NONNULL_ARGS
#endif

#if GNUC_AT_LEAST(3, 4) || HAS_ATTRIBUTE(warn_unused_result)
    #define WARN_UNUSED_RESULT __attribute__((__warn_unused_result__))
#else
    #define WARN_UNUSED_RESULT
#endif

#if GNUC_AT_LEAST(5, 0) || HAS_ATTRIBUTE(returns_nonnull)
    #define RETURNS_NONNULL __attribute__((__returns_nonnull__))
#else
    #define RETURNS_NONNULL
#endif

#define XMALLOC MALLOC RETURNS_NONNULL

#endif // ndef MACROS_H
