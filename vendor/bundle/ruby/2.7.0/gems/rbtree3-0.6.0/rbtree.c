/*
 * MIT License
 * Copyright (c) 2002-2004, 2007, 2009 OZAWA Takuma
 */
#include <ruby.h>
#ifdef HAVE_RUBY_VERSION_H
#include <ruby/version.h>
#else
#include <version.h>
#endif
#ifdef HAVE_RUBY_ST_H
#include <ruby/st.h>
#else
#include <st.h>
#endif
#include <stdarg.h>
#include "dict.h"

#define RBTREE_PROC_DEFAULT FL_USER2
#define HASH_PROC_DEFAULT   FL_USER2

#ifndef RETURN_ENUMERATOR
#define RETURN_ENUMERATOR(obj, argc, argv) ((void)0)
#endif

#ifndef RHASH_SET_IFNONE
#define RHASH_SET_IFNONE(h, ifnone) (RHASH_IFNONE(h) = ifnone)
#endif

#ifndef RB_BLOCK_CALL_FUNC_ARGLIST
#define RB_BLOCK_CALL_FUNC_ARGLIST(yielded_arg, callback_arg) \
    VALUE yielded_arg, VALUE callback_arg
#endif

#if !defined(RUBY_API_VERSION_CODE) || (RUBY_API_VERSION_CODE < 20700)
#define HAVE_TAINT
#endif

VALUE RBTree;
VALUE MultiRBTree;

static ID id_bound;
static ID id_cmp;
static ID id_call;
static ID id_default;

typedef struct {
    dict_t* dict;
    VALUE ifnone;
    int iter_lev;
} rbtree_t;

#define RBTREE(rbtree) ((rbtree_t*)DATA_PTR(rbtree))
#define DICT(rbtree) RBTREE(rbtree)->dict
#define IFNONE(rbtree) RBTREE(rbtree)->ifnone
#define ITER_LEV(rbtree) RBTREE(rbtree)->iter_lev
#define COMPARE(rbtree) DICT(rbtree)->dict_compare
#define CONTEXT(rbtree) DICT(rbtree)->dict_context

#define TO_KEY(arg) ((const void*)arg)
#define TO_VAL(arg) ((void*)arg)
#define GET_KEY(dnode) ((VALUE)dnode_getkey(dnode))
#define GET_VAL(dnode) ((VALUE)dnode_get(dnode))
#define ASSOC(dnode) rb_assoc_new(GET_KEY(dnode), GET_VAL(dnode))

/*********************************************************************/

static int
cmpint(VALUE i, VALUE a, VALUE b)
{
    return rb_cmpint(i, a, b);
}

static void
rbtree_free(rbtree_t* rbtree)
{
    dict_free_nodes(rbtree->dict);
    dict_destroy(rbtree->dict);
    xfree(rbtree);
}

static void
rbtree_mark(rbtree_t* rbtree)
{
    if (rbtree == NULL) return;

    if (rbtree->dict != NULL) {
        dict_t* dict = rbtree->dict;
        dnode_t* node;
        for (node = dict_first(dict);
             node != NULL;
             node = dict_next(dict, node)) {

            rb_gc_mark(GET_KEY(node));
            rb_gc_mark(GET_VAL(node));
        }
        rb_gc_mark((VALUE)dict->dict_context);
    }
    rb_gc_mark(rbtree->ifnone);
}

static dnode_t*
rbtree_alloc_node(void* context)
{
    return ALLOC(dnode_t);
}

static void
rbtree_free_node(dnode_t* node, void* context)
{
    xfree(node);
}

NORETURN(static void rbtree_argc_error());
static void
rbtree_argc_error()
{
    rb_raise(rb_eArgError, "wrong number of arguments");
}

static int
rbtree_cmp(const void* key1, const void* key2, void* context)
{
    VALUE ret;
    if (TYPE(key1) == T_STRING && TYPE(key2) == T_STRING)
        return rb_str_cmp((VALUE)key1, (VALUE)key2);
    ret = rb_funcall((VALUE)key1, id_cmp, 1, (VALUE)key2);
    return cmpint(ret, (VALUE)key1, (VALUE)key2);
}

static int
rbtree_user_cmp(const void* key1, const void* key2, void* cmp_proc)
{
    VALUE ret = rb_funcall((VALUE)cmp_proc, id_call, 2,
                           (VALUE)key1, (VALUE)key2);
    return cmpint(ret, (VALUE)key1, (VALUE)key2);
}

static void
rbtree_modify(VALUE self)
{
    if (ITER_LEV(self) > 0)
        rb_raise(rb_eTypeError, "can't modify rbtree in iteration");
    if (OBJ_FROZEN(self))
        rb_error_frozen("rbtree");
#ifdef HAVE_TAINT
    if (!OBJ_TAINTED(self) && rb_safe_level() >= 4)
        rb_raise(rb_eSecurityError, "Insecure: can't modify rbtree");
#endif
}

static VALUE
rbtree_alloc(VALUE klass)
{
    dict_t* dict;
    rbtree_t* rbtree_ptr;
    VALUE rbtree = Data_Make_Struct(klass, rbtree_t, rbtree_mark, rbtree_free,
                                    rbtree_ptr);

    dict = dict_create(rbtree_cmp);
    dict_set_allocator(dict, rbtree_alloc_node, rbtree_free_node,
                       (void*)Qnil);
    if (klass == MultiRBTree)
        dict_allow_dupes(dict);

    rbtree_ptr->dict = dict;
    rbtree_ptr->ifnone = Qnil;
    return rbtree;
}

VALUE rbtree_aset(VALUE, VALUE, VALUE);
VALUE rbtree_clear(VALUE);
VALUE rbtree_has_key(VALUE, VALUE);
VALUE rbtree_update(VALUE, VALUE);

/*********************************************************************/

static int
hash_to_rbtree_i(VALUE key, VALUE value, VALUE rbtree)
{
    if (key != Qundef)
        rbtree_aset(rbtree, key, value);
    return ST_CONTINUE;
}

/*
 *
 */
VALUE
rbtree_s_create(int argc, VALUE* argv, VALUE klass)
{
    long i;
    VALUE rbtree;

    if (argc == 1) {
        VALUE tmp;

        if (klass == RBTree && CLASS_OF(argv[0]) == MultiRBTree) {
            rb_raise(rb_eTypeError, "can't convert MultiRBTree to RBTree");
        }

        if (rb_obj_is_kind_of(argv[0], klass)) {
            rbtree = rbtree_alloc(klass);
            rbtree_update(rbtree, argv[0]);
            return rbtree;
        }

        tmp = rb_check_convert_type(argv[0], T_HASH, "Hash", "to_hash");
        if (!NIL_P(tmp)) {
            rbtree = rbtree_alloc(klass);
            st_foreach(RHASH_TBL(tmp), hash_to_rbtree_i, rbtree);
            return rbtree;
        }

        tmp = rb_check_array_type(argv[0]);
        if (!NIL_P(tmp)) {
            rbtree = rbtree_alloc(klass);
            for (i = 0; i < RARRAY_LEN(tmp); i++) {
                VALUE v = rb_check_array_type(RARRAY_PTR(tmp)[i]);
                if (NIL_P(v)) {
                    continue;
                }
                switch(RARRAY_LEN(v)) {
                case 1:
                    rbtree_aset(rbtree, RARRAY_PTR(v)[0], Qnil);
                    break;
                case 2:
                    rbtree_aset(rbtree, RARRAY_PTR(v)[0], RARRAY_PTR(v)[1]);
                    break;
                default:
                    continue;
                }
            }
            return rbtree;
        }
    }

    if (argc % 2 != 0)
        rb_raise(rb_eArgError, "odd number of arguments for RBTree");

    rbtree = rbtree_alloc(klass);
    for (i = 0; i < argc; i += 2)
        rbtree_aset(rbtree, argv[i], argv[i + 1]);
    return rbtree;
}

/*
 *
 */
VALUE
rbtree_initialize(int argc, VALUE* argv, VALUE self)
{
    rbtree_modify(self);

    if (rb_block_given_p()) {
        if (argc > 0)
            rbtree_argc_error();
        IFNONE(self) = rb_block_proc();
        FL_SET(self, RBTREE_PROC_DEFAULT);
    } else {
        if (argc > 1)
            rbtree_argc_error();
        else if (argc == 1)
            IFNONE(self) = argv[0];
    }
    return self;
}

/*********************************************************************/

typedef enum {
    INITIAL_VALUE, NODE_NOT_FOUND, NODE_FOUND
} insert_node_ret_t;

typedef struct {
    dict_t* dict;
    dnode_t* node;
    const void* key;
    insert_node_ret_t ret;
} insert_node_t;

static VALUE
insert_node_body(VALUE arg_)
{
    insert_node_t* arg = (insert_node_t*)arg_;
    if (dict_insert(arg->dict, arg->node, arg->key))
        arg->ret = NODE_NOT_FOUND;
    else
        arg->ret = NODE_FOUND;
    return Qnil;
}

static VALUE
insert_node_ensure(VALUE arg_)
{
    insert_node_t* arg = (insert_node_t*)arg_;
    dict_t* dict = arg->dict;
    dnode_t* node = arg->node;
    switch (arg->ret) {
    case INITIAL_VALUE:
        dict->dict_freenode(node, dict->dict_context);
        break;
    case NODE_NOT_FOUND:
        if (TYPE(arg->key) == T_STRING)
            node->dict_key = TO_KEY(rb_str_new4(GET_KEY(node)));
        break;
    case NODE_FOUND:
        dict->dict_freenode(node, dict->dict_context);
        break;
    }
    return Qnil;
}

static void
rbtree_insert(VALUE self, VALUE key, VALUE value)
{
    insert_node_t arg;
    dict_t* dict = DICT(self);
    dnode_t* node = dict->dict_allocnode(dict->dict_context);

    dnode_init(node, TO_VAL(value));

    arg.dict = dict;
    arg.node = node;
    arg.key = TO_KEY(key);
    arg.ret = INITIAL_VALUE;

    rb_ensure(insert_node_body, (VALUE)&arg,
              insert_node_ensure, (VALUE)&arg);
}

/*********************************************************************/

/*
 *
 */
VALUE
rbtree_aset(VALUE self, VALUE key, VALUE value)
{
    rbtree_modify(self);

    if (dict_isfull(DICT(self))) {
        dnode_t* node = dict_lookup(DICT(self), TO_KEY(key));
        if (node == NULL)
            rb_raise(rb_eIndexError, "rbtree full");
        else
            dnode_put(node, TO_VAL(value));
        return value;
    }
    rbtree_insert(self, key, value);
    return value;
}

/*
 *
 */
VALUE
rbtree_aref(VALUE self, VALUE key)
{
    dnode_t* node = dict_lookup(DICT(self), TO_KEY(key));
    if (node == NULL)
        return rb_funcall(self, id_default, 1, key);
    else
        return GET_VAL(node);
}

/*
 *
 */
VALUE
rbtree_fetch(int argc, VALUE* argv, VALUE self)
{
    dnode_t* node;
    int block_given;

    if (argc == 0 || argc > 2)
        rbtree_argc_error();
    block_given = rb_block_given_p();
    if (block_given && argc == 2)
	rb_warn("block supersedes default value argument");

    node = dict_lookup(DICT(self), TO_KEY(argv[0]));
    if (node != NULL)
        return GET_VAL(node);

    if (block_given)
        return rb_yield(argv[0]);
    if (argc == 1)
        rb_raise(rb_eIndexError, "key not found");
    return argv[1];
}

/*
 *
 */
VALUE
rbtree_size(VALUE self)
{
    return ULONG2NUM(dict_count(DICT(self)));
}

/*
 *
 */
VALUE
rbtree_empty_p(VALUE self)
{
    return dict_isempty(DICT(self)) ? Qtrue : Qfalse;
}

/*
 *
 */
VALUE
rbtree_default(int argc, VALUE* argv, VALUE self)
{
    VALUE key = Qnil;
    if (argc == 1)
        key = argv[0];
    else if (argc > 1)
        rbtree_argc_error();

    if (FL_TEST(self, RBTREE_PROC_DEFAULT)) {
        if (argc == 0) return Qnil;
        return rb_funcall(IFNONE(self), id_call, 2, self, key);
    }
    return IFNONE(self);
}

/*
 *
 */
VALUE
rbtree_set_default(VALUE self, VALUE ifnone)
{
    rbtree_modify(self);
    IFNONE(self) = ifnone;
    FL_UNSET(self, RBTREE_PROC_DEFAULT);
    return ifnone;
}

/*
 *
 */
VALUE
rbtree_default_proc(VALUE self)
{
    if (FL_TEST(self, RBTREE_PROC_DEFAULT))
        return IFNONE(self);
    return Qnil;
}

static int
value_eq(const void* key1, const void* key2)
{
    return rb_equal((VALUE)key1, (VALUE)key2) != 0;
}

/*
 *
 */
VALUE
rbtree_equal(VALUE self, VALUE other)
{
    int ret;
    if (self == other)
        return Qtrue;
    if (!rb_obj_is_kind_of(other, MultiRBTree))
        return Qfalse;
    ret = dict_equal(DICT(self), DICT(other), value_eq);
    return ret ? Qtrue : Qfalse;
}

/*********************************************************************/

typedef enum {
    EACH_NEXT, EACH_STOP
} each_return_t;

typedef each_return_t (*each_callback_func)(dnode_t*, void*);

typedef struct {
    VALUE self;
    each_callback_func func;
    void* arg;
    int reverse;
} rbtree_each_arg_t;

static VALUE
rbtree_each_ensure(VALUE self)
{
    ITER_LEV(self)--;
    return Qnil;
}

static VALUE
rbtree_each_body(VALUE arg_)
{
    rbtree_each_arg_t* arg = (rbtree_each_arg_t*)arg_;
    VALUE self = arg->self;
    dict_t* dict = DICT(self);
    dnode_t* node;
    dnode_t* first_node;
    dnode_t* (*next_func)(dict_t*, dnode_t*);

    if (arg->reverse) {
        first_node = dict_last(dict);
        next_func = dict_prev;
    } else {
        first_node = dict_first(dict);
        next_func = dict_next;
    }

    ITER_LEV(self)++;
    for (node = first_node;
         node != NULL;
         node = next_func(dict, node)) {

        if (arg->func(node, arg->arg) == EACH_STOP)
            break;
    }
    return self;
}

static VALUE
rbtree_for_each(VALUE self, each_callback_func func, void* arg)
{
    rbtree_each_arg_t each_arg;
    each_arg.self = self;
    each_arg.func = func;
    each_arg.arg = arg;
    each_arg.reverse = 0;
    return rb_ensure(rbtree_each_body, (VALUE)&each_arg,
                     rbtree_each_ensure, self);
}

static VALUE
rbtree_reverse_for_each(VALUE self, each_callback_func func, void* arg)
{
    rbtree_each_arg_t each_arg;
    each_arg.self = self;
    each_arg.func = func;
    each_arg.arg = arg;
    each_arg.reverse = 1;
    return rb_ensure(rbtree_each_body, (VALUE)&each_arg,
                     rbtree_each_ensure, self);
}

/*********************************************************************/

static each_return_t
each_i(dnode_t* node, void* arg)
{
    rb_yield(ASSOC(node));
    return EACH_NEXT;
}

/*
 * call-seq:
 *   rbtree.each {|key, value| block} => rbtree
 *
 * Calls block once for each key in order, passing the key and value
 * as a two-element array parameters.
 */
VALUE
rbtree_each(VALUE self)
{
    RETURN_ENUMERATOR(self, 0, NULL);
    return rbtree_for_each(self, each_i, NULL);
}

static each_return_t
each_pair_i(dnode_t* node, void* arg)
{
    rb_yield_values(2, GET_KEY(node), GET_VAL(node));
    return EACH_NEXT;
}

/*
 * call-seq:
 *   rbtree.each_pair {|key, value| block} => rbtree
 *
 * Calls block once for each key in order, passing the key and value
 * as parameters.
 */
VALUE
rbtree_each_pair(VALUE self)
{
    RETURN_ENUMERATOR(self, 0, NULL);
    return rbtree_for_each(self, each_pair_i, NULL);
}

static each_return_t
each_key_i(dnode_t* node, void* arg)
{
    rb_yield(GET_KEY(node));
    return EACH_NEXT;
}

/*
 * call-seq:
 *   rbtree.each_key {|key| block} => rbtree
 *
 * Calls block once for each key in order, passing the key as
 * parameters.
 */
VALUE
rbtree_each_key(VALUE self)
{
    RETURN_ENUMERATOR(self, 0, NULL);
    return rbtree_for_each(self, each_key_i, NULL);
}

static each_return_t
each_value_i(dnode_t* node, void* arg)
{
    rb_yield(GET_VAL(node));
    return EACH_NEXT;
}

/*
 * call-seq:
 *   rbtree.each_value {|value| block} => rbtree
 *
 * Calls block once for each key in order, passing the value as
 * parameters.
 */
VALUE
rbtree_each_value(VALUE self)
{
    RETURN_ENUMERATOR(self, 0, NULL);
    return rbtree_for_each(self, each_value_i, NULL);
}

/*
 * call-seq:
 *   rbtree.reverse_each {|key, value| block} => rbtree
 *
 * Calls block once for each key in reverse order, passing the key and
 * value as parameters.
 */
VALUE
rbtree_reverse_each(VALUE self)
{
    RETURN_ENUMERATOR(self, 0, NULL);
    return rbtree_reverse_for_each(self, each_pair_i, NULL);
}

static each_return_t
aset_i(dnode_t* node, void* self)
{
    rbtree_aset((VALUE)self, GET_KEY(node), GET_VAL(node));
    return EACH_NEXT;
}

static void
copy_dict(VALUE src, VALUE dest, dict_comp_t cmp,  void* context)
{
    VALUE temp = rbtree_alloc(CLASS_OF(dest));
    COMPARE(temp) = cmp;
    CONTEXT(temp) = context;
    rbtree_for_each(src, aset_i, (void*)temp);
    {
        dict_t* t = DICT(temp);
        DICT(temp) = DICT(dest);
        DICT(dest) = t;
    }
    rbtree_free(RBTREE(temp));
    rb_gc_force_recycle(temp);
}

/*
 *
 */
VALUE
rbtree_initialize_copy(VALUE self, VALUE other)
{
    if (self == other)
        return self;
    if (!rb_obj_is_kind_of(other, CLASS_OF(self))) {
        rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)",
                 rb_class2name(CLASS_OF(other)),
                 rb_class2name(CLASS_OF(self)));
    }

    copy_dict(other, self, COMPARE(other), CONTEXT(other));

    IFNONE(self) = IFNONE(other);
    if (FL_TEST(other, RBTREE_PROC_DEFAULT))
        FL_SET(self, RBTREE_PROC_DEFAULT);
    else
        FL_UNSET(self, RBTREE_PROC_DEFAULT);
    return self;
}

/*
 *
 */
VALUE
rbtree_values_at(int argc, VALUE* argv, VALUE self)
{
    long i;
    VALUE ary = rb_ary_new();

    for (i = 0; i < argc; i++)
        rb_ary_push(ary, rbtree_aref(self, argv[i]));
    return ary;
}

static each_return_t
select_i(dnode_t* node, void* ary)
{
    if (RTEST(rb_yield_values(2, GET_KEY(node), GET_VAL(node))))
        rb_ary_push((VALUE)ary, ASSOC(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_select(VALUE self)
{
    VALUE ary;

    RETURN_ENUMERATOR(self, 0, NULL);
    ary = rb_ary_new();
    rbtree_for_each(self, select_i, (void*)ary);
    return ary;
}

static each_return_t
index_i(dnode_t* node, void* arg_)
{
    VALUE* arg = (VALUE*)arg_;
    if (rb_equal(GET_VAL(node), arg[1])) {
        arg[0] = GET_KEY(node);
        return EACH_STOP;
    }
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_index(VALUE self, VALUE value)
{
    VALUE arg[2];
    arg[0] = Qnil;
    arg[1] = value;
    rbtree_for_each(self, index_i, (void*)&arg);
    return arg[0];
}

/*
 *
 */
VALUE
rbtree_clear(VALUE self)
{
    rbtree_modify(self);
    dict_free_nodes(DICT(self));
    return self;
}

/*
 *
 */
VALUE
rbtree_delete(VALUE self, VALUE key)
{
    dict_t* dict = DICT(self);
    dnode_t* node;
    VALUE value;

    rbtree_modify(self);
    node = dict_lookup(dict, TO_KEY(key));
    if (node == NULL)
        return rb_block_given_p() ? rb_yield(key) : Qnil;
    value = GET_VAL(node);
    dict_delete_free(dict, node);
    return value;
}

/*********************************************************************/

typedef struct dnode_list_t_ {
    struct dnode_list_t_* prev;
    dnode_t* node;
} dnode_list_t;

typedef struct {
    VALUE self;
    dnode_list_t* list;
    int raised;
} rbtree_delete_if_arg_t;

static VALUE
rbtree_delete_if_ensure(VALUE arg_)
{
    rbtree_delete_if_arg_t* arg = (rbtree_delete_if_arg_t*)arg_;
    dict_t* dict = DICT(arg->self);
    dnode_list_t* list = arg->list;

    if (--ITER_LEV(arg->self) == 0) {
        while (list != NULL) {
            dnode_list_t* l = list;
            if (!arg->raised)
                dict_delete_free(dict, l->node);
            list = l->prev;
            xfree(l);
        }
    }
    return Qnil;
}

static VALUE
rbtree_delete_if_body(VALUE arg_)
{
    rbtree_delete_if_arg_t* arg = (rbtree_delete_if_arg_t*)arg_;
    VALUE self = arg->self;
    dict_t* dict = DICT(self);
    dnode_t* node;

    arg->raised = 1;
    ITER_LEV(self)++;
    for (node = dict_first(dict);
         node != NULL;
         node = dict_next(dict, node)) {

        if (RTEST(rb_yield_values(2, GET_KEY(node), GET_VAL(node)))) {
            dnode_list_t* l = ALLOC(dnode_list_t);
            l->node = node;
            l->prev = arg->list;
            arg->list = l;
        }
    }
    arg->raised = 0;
    return self;
}

/*********************************************************************/

/*
 *
 */
VALUE
rbtree_delete_if(VALUE self)
{
    rbtree_delete_if_arg_t arg;

    RETURN_ENUMERATOR(self, 0, NULL);
    rbtree_modify(self);
    arg.self = self;
    arg.list = NULL;
    return rb_ensure(rbtree_delete_if_body, (VALUE)&arg,
                     rbtree_delete_if_ensure, (VALUE)&arg);
}

/*
 *
 */
VALUE
rbtree_reject_bang(VALUE self)
{
    dictcount_t count;

    RETURN_ENUMERATOR(self, 0, NULL);
    count = dict_count(DICT(self));
    rbtree_delete_if(self);
    if (count == dict_count(DICT(self)))
        return Qnil;
    return self;
}

/*
 *
 */
VALUE
rbtree_reject(VALUE self)
{
    return rbtree_reject_bang(rb_obj_dup(self));
}

static VALUE
rbtree_shift_pop(VALUE self, const int shift)
{
    dict_t* dict = DICT(self);
    dnode_t* node;
    VALUE ret;

    rbtree_modify(self);

    if (dict_isempty(dict)) {
        if (FL_TEST(self, RBTREE_PROC_DEFAULT)) {
            return rb_funcall(IFNONE(self), id_call, 2, self, Qnil);
        }
        return IFNONE(self);
    }

    if (shift)
        node = dict_last(dict);
    else
        node = dict_first(dict);
    ret = ASSOC(node);
    dict_delete_free(dict, node);
    return ret;
}

/*
 * call-seq:
 *   rbtree.shift => array or object
 *
 * Removes the first(that is, the smallest) key-value pair and returns
 * it as a two-item array.
 */
VALUE
rbtree_shift(VALUE self)
{
    return rbtree_shift_pop(self, 0);
}

/*
 * call-seq:
 *   rbtree.pop => array or object
 *
 * Removes the last(that is, the biggest) key-value pair and returns
 * it as a two-item array.
 */
VALUE
rbtree_pop(VALUE self)
{
    return rbtree_shift_pop(self, 1);
}

static each_return_t
invert_i(dnode_t* node, void* rbtree)
{
    rbtree_aset((VALUE)rbtree, GET_VAL(node), GET_KEY(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_invert(VALUE self)
{
    VALUE rbtree = rbtree_alloc(CLASS_OF(self));
    rbtree_for_each(self, invert_i, (void*)rbtree);
    return rbtree;
}

static each_return_t
update_block_i(dnode_t* node, void* self_)
{
    VALUE self = (VALUE)self_;
    VALUE key = GET_KEY(node);
    VALUE value = GET_VAL(node);

    if (rbtree_has_key(self, key))
        value = rb_yield_values(3, key, rbtree_aref(self, key), value);
    rbtree_aset(self, key, value);
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_update(VALUE self, VALUE other)
{
    rbtree_modify(self);

    if (self == other)
        return self;
    if (!rb_obj_is_kind_of(other, CLASS_OF(self))) {
        rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)",
                 rb_class2name(CLASS_OF(other)),
                 rb_class2name(CLASS_OF(self)));
    }

    if (rb_block_given_p())
        rbtree_for_each(other, update_block_i, (void*)self);
    else
        rbtree_for_each(other, aset_i, (void*)self);
    return self;
}

/*
 *
 */
VALUE
rbtree_merge(VALUE self, VALUE other)
{
    return rbtree_update(rb_obj_dup(self), other);
}

/*
 *
 */
VALUE
rbtree_has_key(VALUE self, VALUE key)
{
    return dict_lookup(DICT(self), TO_KEY(key)) == NULL ? Qfalse : Qtrue;
}

static each_return_t
has_value_i(dnode_t* node, void* arg_)
{
    VALUE* arg = (VALUE*)arg_;
    if (rb_equal(GET_VAL(node), arg[1])) {
        arg[0] = Qtrue;
        return EACH_STOP;
    }
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_has_value(VALUE self, VALUE value)
{
    VALUE arg[2];
    arg[0] = Qfalse;
    arg[1] = value;
    rbtree_for_each(self, has_value_i, (void*)&arg);
    return arg[0];
}

static each_return_t
keys_i(dnode_t* node, void* ary)
{
    rb_ary_push((VALUE)ary, GET_KEY(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_keys(VALUE self)
{
    VALUE ary = rb_ary_new();
    rbtree_for_each(self, keys_i, (void*)ary);
    return ary;
}

static each_return_t
values_i(dnode_t* node, void* ary)
{
    rb_ary_push((VALUE)ary, GET_VAL(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_values(VALUE self)
{
    VALUE ret = rb_ary_new();
    rbtree_for_each(self, values_i, (void*)ret);
    return ret;
}

static each_return_t
to_a_i(dnode_t* node, void* ary)
{
    rb_ary_push((VALUE)ary, ASSOC(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_to_a(VALUE self)
{
    VALUE ary = rb_ary_new();
    rbtree_for_each(self, to_a_i, (void*)ary);
#ifdef HAVE_TAINT
    OBJ_INFECT(ary, self);
#endif
    return ary;
}

static each_return_t
to_hash_i(dnode_t* node, void* hash)
{
    st_insert(RHASH_TBL((long)hash), GET_KEY(node), GET_VAL(node));
    return EACH_NEXT;
}

/*
 *
 */
VALUE
rbtree_to_hash(VALUE self)
{
    VALUE hash;
    if (CLASS_OF(self) == MultiRBTree) {
        rb_raise(rb_eTypeError, "can't convert MultiRBTree to Hash");
    }

    hash = rb_hash_new();
    rbtree_for_each(self, to_hash_i, (void*)hash);
    RHASH_SET_IFNONE(hash, IFNONE(self));
    if (FL_TEST(self, RBTREE_PROC_DEFAULT))
        FL_SET(hash, HASH_PROC_DEFAULT);
#ifdef HAVE_TAINT
    OBJ_INFECT(hash, self);
#endif
    return hash;
}

/*
 *
 */
VALUE
rbtree_to_rbtree(VALUE self)
{
    return self;
}

static VALUE
rbtree_begin_inspect(VALUE self)
{
    const char* c = rb_class2name(CLASS_OF(self));
    VALUE rb_str = rb_str_new(0, strlen(c) + 4);
    sprintf(RSTRING_PTR(rb_str), "#<%s: ", c);
    return rb_str;
}

static VALUE
to_s_rbtree(VALUE self, VALUE nil)
{
    return rb_ary_to_s(rbtree_to_a(self));
}

#ifdef HAVE_RB_EXEC_RECURSIVE
VALUE
rbtree_to_s_recursive(VALUE self, VALUE arg, int recursive)
{
    if (recursive)
        rb_str_cat2(rbtree_begin_inspect(self), "...>");
    return to_s_rbtree(self, Qnil);
}
#endif

/*
 *
 */
VALUE
rbtree_to_s(VALUE self)
{
#ifdef HAVE_RB_EXEC_RECURSIVE
    return rb_exec_recursive(rbtree_to_s_recursive, self, Qnil);
#else
    if (rb_inspecting_p(self))
 return rb_str_cat2(rbtree_begin_inspect(self), "...>");
    return rb_protect_inspect(to_s_rbtree, self, Qnil);
#endif
}

static each_return_t
inspect_i(dnode_t* node, void* ret_)
{
    VALUE ret = (VALUE)ret_;
    VALUE str;

    if (RSTRING_PTR(ret)[0] == '-')
        RSTRING_PTR(ret)[0] = '#';
    else
        rb_str_cat2(ret, ", ");

    str = rb_inspect(GET_KEY(node));
    rb_str_append(ret, str);
#ifdef HAVE_TAINT
    OBJ_INFECT(ret, str);
#endif

    rb_str_cat2(ret, "=>");

    str = rb_inspect(GET_VAL(node));
    rb_str_append(ret, str);
#ifdef HAVE_TAINT
    OBJ_INFECT(ret, str);
#endif

    return EACH_NEXT;
}

static VALUE
inspect_rbtree(VALUE self, VALUE ret)
{
    VALUE str;

    rb_str_cat2(ret, "{");
    RSTRING_PTR(ret)[0] = '-';
    rbtree_for_each(self, inspect_i, (void*)ret);
    RSTRING_PTR(ret)[0] = '#';
    rb_str_cat2(ret, "}");

    str = rb_inspect(IFNONE(self));
    rb_str_cat2(ret, ", default=");
    rb_str_append(ret, str);
#ifdef HAVE_TAINT
    OBJ_INFECT(ret, str);
#endif

    str = rb_inspect((VALUE)CONTEXT(self));
    rb_str_cat2(ret, ", cmp_proc=");
    rb_str_append(ret, str);
#ifdef HAVE_TAINT
    OBJ_INFECT(ret, str);
#endif

    rb_str_cat2(ret, ">");
#ifdef HAVE_TAINT
    OBJ_INFECT(ret, self);
#endif
    return ret;
}

#ifdef HAVE_RB_EXEC_RECURSIVE
VALUE
rbtree_inspect_recursive(VALUE self, VALUE arg, int recursive)
{
    VALUE str = rbtree_begin_inspect(self);
    if (recursive)
        return rb_str_cat2(str, "...>");
    return inspect_rbtree(self, str);
}
#endif

/*
 *
 */
VALUE
rbtree_inspect(VALUE self)
{
#ifdef HAVE_RB_EXEC_RECURSIVE
    return rb_exec_recursive(rbtree_inspect_recursive, self, Qnil);
#else
    VALUE str = rbtree_begin_inspect(self);
    if (rb_inspecting_p(self))
        return rb_str_cat2(str, "...>");
    return rb_protect_inspect(inspect_rbtree, self, str);
#endif
}

/*
 * call-seq:
 *   rbtree.lower_bound(key) => array
 *
 * Retruns key-value pair corresponding to the lowest key that is
 * equal to or greater than the given key(inside of lower
 * boundary). If there is no such key, returns nil.
 */
VALUE
rbtree_lower_bound(VALUE self, VALUE key)
{
    dnode_t* node = dict_lower_bound(DICT(self), TO_KEY(key));
    if (node == NULL)
        return Qnil;
    return ASSOC(node);
}

/*
 * call-seq:
 *   rbtree.upper_bound(key) => array
 *
 * Retruns key-value pair corresponding to the greatest key that is
 * equal to or lower than the given key(inside of upper boundary). If
 * there is no such key, returns nil.
 */
VALUE
rbtree_upper_bound(VALUE self, VALUE key)
{
    dnode_t* node = dict_upper_bound(DICT(self), TO_KEY(key));
    if (node == NULL)
        return Qnil;
    return ASSOC(node);
}

/*********************************************************************/

typedef struct {
    VALUE self;
    dnode_t* lower_node;
    dnode_t* upper_node;
    VALUE ret;
} rbtree_bound_arg_t;

static VALUE
rbtree_bound_body(VALUE arg_)
{
    rbtree_bound_arg_t* arg = (rbtree_bound_arg_t*)arg_;
    VALUE self = arg->self;
    dict_t* dict = DICT(self);
    dnode_t* lower_node = arg->lower_node;
    dnode_t* upper_node = arg->upper_node;
    const int block_given = rb_block_given_p();
    VALUE ret = arg->ret;
    dnode_t* node;

    ITER_LEV(self)++;
    for (node = lower_node;;
         node = dict_next(dict, node)) {

        if (block_given)
            rb_yield_values(2, GET_KEY(node), GET_VAL(node));
        else
            rb_ary_push(ret, ASSOC(node));
        if (node == upper_node)
            break;
    }
    return ret;
}

/*********************************************************************/

/*
 * call-seq:
 *   rbtree.bound(key1, key2 = key1)                      => array
 *   rbtree.bound(key1, key2 = key1) {|key, value| block} => rbtree
 *
 * Returns an array containing key-value pairs between the result of
 * MultiRBTree#lower_bound and MultiRBTree#upper_bound. If a block is
 * given it calls the block once for each pair.
 */
VALUE
rbtree_bound(int argc, VALUE* argv, VALUE self)
{
    dict_t* dict = DICT(self);
    dnode_t* lower_node;
    dnode_t* upper_node;
    VALUE ret;

    if (argc == 0 || argc > 2)
        rbtree_argc_error();

    lower_node = dict_lower_bound(dict, TO_KEY(argv[0]));
    upper_node = dict_upper_bound(dict, TO_KEY(argv[argc - 1]));
    ret = rb_block_given_p() ? self : rb_ary_new();

    if (lower_node == NULL || upper_node == NULL ||
        COMPARE(self)(dnode_getkey(lower_node),
                      dnode_getkey(upper_node),
                      CONTEXT(self)) > 0) {
        return ret;
    } else {
        rbtree_bound_arg_t arg;
        arg.self = self;
        arg.lower_node = lower_node;
        arg.upper_node = upper_node;
        arg.ret = ret;

        return rb_ensure(rbtree_bound_body, (VALUE)&arg,
                         rbtree_each_ensure, self);
    }
}

static VALUE
rbtree_first_last(VALUE self, const int first)
{
    dict_t* dict = DICT(self);
    dnode_t* node;

    if (dict_isempty(dict)) {
        if (FL_TEST(self, RBTREE_PROC_DEFAULT)) {
            return rb_funcall(IFNONE(self), id_call, 2, self, Qnil);
        }
        return IFNONE(self);
    }

    if (first)
        node = dict_first(dict);
    else
        node = dict_last(dict);
    return ASSOC(node);
}

/*
 * call-seq:
 *   rbtree.first => array or object
 *
 * Returns the first(that is, the smallest) key-value pair.
 */
VALUE
rbtree_first(VALUE self)
{
    return rbtree_first_last(self, 1);
}

/*
 * call-seq:
 *   rbtree.last => array of object
 *
 * Returns the last(that is, the biggest) key-value pair.
 */
VALUE
rbtree_last(VALUE self)
{
    return rbtree_first_last(self, 0);
}

/*
 * call-seq:
 *   rbtree.readjust                      => rbtree
 *   rbtree.readjust(nil)                 => rbtree
 *   rbtree.readjust(proc)                => rbtree
 *   rbtree.readjust {|key1, key2| block} => rbtree
 *
 * Sets a proc to compare keys and readjusts elements using the given
 * block or a Proc object given as the argument. The block takes two
 * arguments of a key and returns negative, 0, or positive depending
 * on the first argument is less than, equal to, or greater than the
 * second one. If no block is given it just readjusts elements using
 * current comparison block. If nil is given as the argument it sets
 * default comparison block.
 */
VALUE
rbtree_readjust(int argc, VALUE* argv, VALUE self)
{
    dict_comp_t cmp = NULL;
    void* context = NULL;

    rbtree_modify(self);

    if (argc == 0) {
        if (rb_block_given_p()) {
            cmp = rbtree_user_cmp;
            context = (void*)rb_block_proc();
        } else {
            cmp = COMPARE(self);
            context = CONTEXT(self);
        }
    } else if (argc == 1 && !rb_block_given_p()) {
        if (argv[0] == Qnil) {
            cmp = rbtree_cmp;
            context = (void*)Qnil;
        } else {
            if (CLASS_OF(argv[0]) != rb_cProc)
                rb_raise(rb_eTypeError,
                         "wrong argument type %s (expected Proc)",
                         rb_class2name(CLASS_OF(argv[0])));
            cmp = rbtree_user_cmp;
            context = (void*)argv[0];
        }
    } else {
        rbtree_argc_error();
    }

    if (dict_isempty(DICT(self))) {
        COMPARE(self) = cmp;
        CONTEXT(self) = context;
        return self;
    }
    copy_dict(self, self, cmp, context);
    return self;
}

/*
 * call-seq:
 *   rbtree.cmp_proc => proc
 *
 * Returns the comparison block that is given by MultiRBTree#readjust.
 */
VALUE
rbtree_cmp_proc(VALUE self)
{
    return (VALUE)(CONTEXT(self));
}

/*********************************************************************/

static ID id_comma_breakable;
static ID id_object_group;
static ID id_pp;
static ID id_pp_hash;
static ID id_text;

typedef struct {
    VALUE rbtree;
    VALUE pp;
} pp_arg_t;

static VALUE
pp_object_group(VALUE arg_)
{
    pp_arg_t* arg = (pp_arg_t*)arg_;
    return rb_funcall(arg->pp, id_object_group, 1, arg->rbtree);
}

static VALUE
pp_block(RB_BLOCK_CALL_FUNC_ARGLIST(nil, arg_))
{
    pp_arg_t* arg = (pp_arg_t*)arg_;
    VALUE pp = arg->pp;
    VALUE rbtree = arg->rbtree;

    rb_funcall(pp, id_text, 1, rb_str_new2(": "));
    rb_funcall(pp, id_pp_hash, 1, rbtree);
    rb_funcall(pp, id_comma_breakable, 0);
    rb_funcall(pp, id_text, 1, rb_str_new2("default="));
    rb_funcall(pp, id_pp, 1, IFNONE(rbtree));
    rb_funcall(pp, id_comma_breakable, 0);
    rb_funcall(pp, id_text, 1, rb_str_new2("cmp_proc="));
    rb_funcall(pp, id_pp, 1, (VALUE)CONTEXT(rbtree));
    return pp;
}

/*********************************************************************/

/*
 * Called by pretty printing function pp.
 */
VALUE
rbtree_pretty_print(VALUE self, VALUE pp)
{
    pp_arg_t pp_arg;
    pp_arg.rbtree = self;
    pp_arg.pp = pp;

    return rb_iterate(pp_object_group, (VALUE)&pp_arg,
                      pp_block, (VALUE)&pp_arg);
}

/*
 * Called by pretty printing function pp.
 */
VALUE
rbtree_pretty_print_cycle(VALUE self, VALUE pp)
{
#ifdef HAVE_RB_EXEC_RECURSIVE
    return rb_funcall(pp, id_pp, 1, rbtree_inspect_recursive(self, Qnil, 1));
#else
    return rb_funcall(pp, id_pp, 1, rbtree_inspect(self));
#endif
}

/*********************************************************************/

static each_return_t
to_flatten_ary_i(dnode_t* node, void* ary)
{
    rb_ary_push((VALUE)ary, GET_KEY(node));
    rb_ary_push((VALUE)ary, GET_VAL(node));
    return EACH_NEXT;
}

/*********************************************************************/

/*
 * Called by Marshal.dump.
 */
VALUE
rbtree_dump(VALUE self, VALUE _limit)
{
    VALUE ary;
    VALUE ret;

    if (FL_TEST(self, RBTREE_PROC_DEFAULT))
        rb_raise(rb_eTypeError, "cannot dump rbtree with default proc");
    if ((VALUE)CONTEXT(self) != Qnil)
        rb_raise(rb_eTypeError, "cannot dump rbtree with compare proc");

    ary = rb_ary_new2(dict_count(DICT(self)) * 2 + 1);
    rbtree_for_each(self, to_flatten_ary_i, (void*)ary);
    rb_ary_push(ary, IFNONE(self));

    ret = rb_marshal_dump(ary, Qnil);
    rb_ary_clear(ary);
    rb_gc_force_recycle(ary);
    return ret;
}

/*
 * Called by Marshal.load.
 */
VALUE
rbtree_s_load(VALUE klass, VALUE str)
{
    VALUE rbtree = rbtree_alloc(klass);
    VALUE ary = rb_marshal_load(str);
    VALUE* ptr = RARRAY_PTR(ary);
    long len = RARRAY_LEN(ary) - 1;
    long i;

    for (i = 0; i < len; i += 2)
        rbtree_aset(rbtree, ptr[i], ptr[i + 1]);
    IFNONE(rbtree) = ptr[len];

    rb_ary_clear(ary);
    rb_gc_force_recycle(ary);
    return rbtree;
}

/*********************************************************************/

/*
 * RBTree is a sorted associative collection that is implemented with
 * Red-Black Tree. The elements of RBTree are ordered and its interface
 * is the almost same as Hash, so simply you can consider RBTree sorted
 * Hash.
 *
 * Red-Black Tree is a kind of binary tree that automatically balances
 * by itself when a node is inserted or deleted. Thus the complexity
 * for insert, search and delete is O(log N) in expected and worst
 * case. On the other hand the complexity of Hash is O(1). Because
 * Hash is unordered the data structure is more effective than
 * Red-Black Tree as an associative collection.
 *
 * The elements of RBTree are sorted with natural ordering (by <=>
 * method) of its keys or by a comparator(Proc) set by readjust
 * method. It means all keys in RBTree should be comparable with each
 * other. Or a comparator that takes two arguments of a key should return
 * negative, 0, or positive depending on the first argument is less than,
 * equal to, or greater than the second one.
 *
 * The interface of RBTree is the almost same as Hash and there are a
 * few methods to take advantage of the ordering:
 *
 * * lower_bound, upper_bound, bound
 * * first, last
 * * shift, pop
 * * reverse_each
 *
 * Note: while iterating RBTree (e.g. in a block of each method), it is
 * not modifiable, or TypeError is thrown.
 *
 * RBTree supoorts pretty printing using pp.
 *
 * This library contains two classes. One is RBTree and the other is
 * MultiRBTree that is a parent class of RBTree. RBTree does not allow
 * duplications of keys but MultiRBTree does.
 *
 *   require "rbtree"
 *
 *   rbtree = RBTree["c", 10, "a", 20]
 *   rbtree["b"] = 30
 *   p rbtree["b"]              # => 30
 *   rbtree.each do |k, v|
 *     p [k, v]
 *   end                        # => ["a", 20] ["b", 30] ["c", 10]
 *
 *   mrbtree = MultiRBTree["c", 10, "a", 20, "e", 30, "a", 40]
 *   p mrbtree.lower_bound("b") # => ["c", 10]
 *   mrbtree.bound("a", "d") do |k, v|
 *     p [k, v]
 *   end                        # => ["a", 20] ["a", 40] ["c", 10]
 */
void Init_rbtree()
{
    MultiRBTree = rb_define_class("MultiRBTree", rb_cData);
    RBTree = rb_define_class("RBTree", MultiRBTree);

    rb_include_module(MultiRBTree, rb_mEnumerable);

    rb_define_alloc_func(MultiRBTree, rbtree_alloc);

    rb_define_singleton_method(MultiRBTree, "[]", rbtree_s_create, -1);

    rb_define_method(MultiRBTree, "initialize", rbtree_initialize, -1);
    rb_define_method(MultiRBTree, "initialize_copy", rbtree_initialize_copy, 1);

    rb_define_method(MultiRBTree, "to_a", rbtree_to_a, 0);
    rb_define_method(MultiRBTree, "to_s", rbtree_to_s, 0);
    rb_define_method(MultiRBTree, "to_hash", rbtree_to_hash, 0);
    rb_define_method(MultiRBTree, "to_rbtree", rbtree_to_rbtree, 0);
    rb_define_method(MultiRBTree, "inspect", rbtree_inspect, 0);

    rb_define_method(MultiRBTree, "==", rbtree_equal, 1);
    rb_define_method(MultiRBTree, "[]", rbtree_aref, 1);
    rb_define_method(MultiRBTree, "fetch", rbtree_fetch, -1);
    rb_define_method(MultiRBTree, "lower_bound", rbtree_lower_bound, 1);
    rb_define_method(MultiRBTree, "upper_bound", rbtree_upper_bound, 1);
    rb_define_method(MultiRBTree, "bound", rbtree_bound, -1);
    rb_define_method(MultiRBTree, "first", rbtree_first, 0);
    rb_define_method(MultiRBTree, "last", rbtree_last, 0);
    rb_define_method(MultiRBTree, "[]=", rbtree_aset, 2);
    rb_define_method(MultiRBTree, "store", rbtree_aset, 2);
    rb_define_method(MultiRBTree, "default", rbtree_default, -1);
    rb_define_method(MultiRBTree, "default=", rbtree_set_default, 1);
    rb_define_method(MultiRBTree, "default_proc", rbtree_default_proc, 0);
    rb_define_method(MultiRBTree, "index", rbtree_index, 1);
    rb_define_method(MultiRBTree, "empty?", rbtree_empty_p, 0);
    rb_define_method(MultiRBTree, "size", rbtree_size, 0);
    rb_define_method(MultiRBTree, "length", rbtree_size, 0);

    rb_define_method(MultiRBTree, "each", rbtree_each, 0);
    rb_define_method(MultiRBTree, "each_value", rbtree_each_value, 0);
    rb_define_method(MultiRBTree, "each_key", rbtree_each_key, 0);
    rb_define_method(MultiRBTree, "each_pair", rbtree_each_pair, 0);
    rb_define_method(MultiRBTree, "reverse_each", rbtree_reverse_each, 0);

    rb_define_method(MultiRBTree, "keys", rbtree_keys, 0);
    rb_define_method(MultiRBTree, "values", rbtree_values, 0);
    rb_define_method(MultiRBTree, "values_at", rbtree_values_at, -1);

    rb_define_method(MultiRBTree, "shift", rbtree_shift, 0);
    rb_define_method(MultiRBTree, "pop", rbtree_pop, 0);
    rb_define_method(MultiRBTree, "delete", rbtree_delete, 1);
    rb_define_method(MultiRBTree, "delete_if", rbtree_delete_if, 0);
    rb_define_method(MultiRBTree, "select", rbtree_select, 0);
    rb_define_method(MultiRBTree, "reject", rbtree_reject, 0);
    rb_define_method(MultiRBTree, "reject!", rbtree_reject_bang, 0);
    rb_define_method(MultiRBTree, "clear", rbtree_clear, 0);
    rb_define_method(MultiRBTree, "invert", rbtree_invert, 0);
    rb_define_method(MultiRBTree, "update", rbtree_update, 1);
    rb_define_method(MultiRBTree, "merge!", rbtree_update, 1);
    rb_define_method(MultiRBTree, "merge", rbtree_merge, 1);
    rb_define_method(MultiRBTree, "replace", rbtree_initialize_copy, 1);

    rb_define_method(MultiRBTree, "include?", rbtree_has_key, 1);
    rb_define_method(MultiRBTree, "member?", rbtree_has_key, 1);
    rb_define_method(MultiRBTree, "has_key?", rbtree_has_key, 1);
    rb_define_method(MultiRBTree, "has_value?", rbtree_has_value, 1);
    rb_define_method(MultiRBTree, "key?", rbtree_has_key, 1);
    rb_define_method(MultiRBTree, "value?", rbtree_has_value, 1);

    rb_define_method(MultiRBTree, "readjust", rbtree_readjust, -1);
    rb_define_method(MultiRBTree, "cmp_proc", rbtree_cmp_proc, 0);

    rb_define_method(MultiRBTree, "_dump", rbtree_dump, 1);
    rb_define_singleton_method(MultiRBTree, "_load", rbtree_s_load, 1);

    id_bound = rb_intern("bound");
    id_cmp = rb_intern("<=>");
    id_call = rb_intern("call");
    id_default = rb_intern("default");


    rb_define_method(MultiRBTree, "pretty_print", rbtree_pretty_print, 1);
    rb_define_method(MultiRBTree,
                     "pretty_print_cycle", rbtree_pretty_print_cycle, 1);

    id_comma_breakable = rb_intern("comma_breakable");
    id_object_group = rb_intern("object_group");
    id_pp_hash = rb_intern("pp_hash");
    id_text = rb_intern("text");
    id_pp = rb_intern("pp");
}
