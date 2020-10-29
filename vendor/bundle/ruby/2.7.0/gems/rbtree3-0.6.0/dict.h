/*
 * Dictionary Abstract Data Type
 * Copyright (C) 1997 Kaz Kylheku <kaz@ashi.footprints.net>
 *
 * Free Software License:
 *
 * All rights are reserved by the author, with the following exceptions:
 * Permission is granted to freely reproduce and distribute this software,
 * possibly in exchange for a fee, provided that this copyright notice appears
 * intact. Permission is also granted to adapt this software to produce
 * derivative works, as long as the modified versions carry this copyright
 * notice and additional notices stating that the work has been modified.
 * This source code may be translated into executable form and incorporated
 * into proprietary software; there is no requirement for such software to
 * contain a copyright notice related to this source.
 *
 * $Id: dict.h,v 1.9 2005/10/06 05:16:35 kuma Exp $
 * $Name:  $
 */

/*
 * Modified for Ruby/RBTree by OZAWA Takuma.
 */

#ifndef DICT_H
#define DICT_H

#include <limits.h>

/*
 * Blurb for inclusion into C++ translation units
 */

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned long dictcount_t;
#define DICTCOUNT_T_MAX ULONG_MAX

/*
 * The dictionary is implemented as a red-black tree
 */

typedef enum { dnode_red, dnode_black } dnode_color_t;

typedef struct dnode_t {
    struct dnode_t *dict_left;
    struct dnode_t *dict_right;
    struct dnode_t *dict_parent;
    dnode_color_t dict_color;
    const void *dict_key;
    void *dict_data;
} dnode_t;

typedef int (*dict_comp_t)(const void *, const void *, void *);
typedef dnode_t *(*dnode_alloc_t)(void *);
typedef void (*dnode_free_t)(dnode_t *, void *);

typedef int (*dict_value_eql_t)(const void *, const void *);

typedef struct dict_t {
    dnode_t dict_nilnode;
    dictcount_t dict_nodecount;
    dict_comp_t dict_compare;
    dnode_alloc_t dict_allocnode;
    dnode_free_t dict_freenode;
    void *dict_context;
    int dict_dupes;
} dict_t;

typedef void (*dnode_process_t)(dict_t *, dnode_t *, void *);

typedef struct dict_load_t {
    dict_t *dict_dictptr;
    dnode_t dict_nilnode;
} dict_load_t;

extern dict_t *dict_create(dict_comp_t);
extern void dict_set_allocator(dict_t *, dnode_alloc_t, dnode_free_t, void *);
extern void dict_destroy(dict_t *);
extern void dict_free_nodes(dict_t *);
extern void dict_free(dict_t *);
extern dict_t *dict_init(dict_t *, dict_comp_t);
extern void dict_init_like(dict_t *, const dict_t *);
extern int dict_verify(dict_t *);
extern int dict_similar(const dict_t *, const dict_t *);
extern dnode_t *dict_lookup(dict_t *, const void *);
extern dnode_t *dict_lower_bound(dict_t *, const void *);
extern dnode_t *dict_upper_bound(dict_t *, const void *);
extern int dict_insert(dict_t *, dnode_t *, const void *);
extern dnode_t *dict_delete(dict_t *, dnode_t *);
extern int dict_alloc_insert(dict_t *, const void *, void *);
extern void dict_delete_free(dict_t *, dnode_t *);
extern dnode_t *dict_first(dict_t *);
extern dnode_t *dict_last(dict_t *);
extern dnode_t *dict_next(dict_t *, dnode_t *);
extern dnode_t *dict_prev(dict_t *, dnode_t *);
extern dictcount_t dict_count(dict_t *);
extern int dict_isempty(dict_t *);
extern int dict_isfull(dict_t *);
extern int dict_contains(dict_t *, dnode_t *);
extern void dict_allow_dupes(dict_t *);
extern int dnode_is_in_a_dict(dnode_t *);
extern dnode_t *dnode_create(void *);
extern dnode_t *dnode_init(dnode_t *, void *);
extern void dnode_destroy(dnode_t *);
extern void *dnode_get(dnode_t *);
extern const void *dnode_getkey(dnode_t *);
extern void dnode_put(dnode_t *, void *);
extern void dict_process(dict_t *, void *, dnode_process_t);
extern void dict_load_begin(dict_load_t *, dict_t *);
extern void dict_load_next(dict_load_t *, dnode_t *, const void *);
extern void dict_load_end(dict_load_t *);
extern void dict_merge(dict_t *, dict_t *);

int dict_equal(dict_t*, dict_t*, dict_value_eql_t);

#ifdef __cplusplus
}
#endif

#endif
