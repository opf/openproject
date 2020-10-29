/*
 * use wrappers around libatomic-ops for folks that don't have GCC
 * or a new enough version of GCC
 */
#ifndef HAVE_GCC_ATOMIC_BUILTINS
#include <atomic_ops.h>

static inline unsigned long
__sync_add_and_fetch(unsigned long *dst, unsigned long incr)
{
        AO_t tmp = AO_fetch_and_add((AO_t *)dst, (AO_t)incr);

        return (unsigned long)tmp + incr;
}

static inline unsigned long
__sync_sub_and_fetch(unsigned long *dst, unsigned long incr)
{
        AO_t tmp = AO_fetch_and_add((AO_t *)dst, (AO_t)(-(long)incr));

        return (unsigned long)tmp - incr;
}
#endif /* HAVE_GCC_ATOMIC_BUILTINS */
