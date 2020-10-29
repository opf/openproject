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
 * $Id: dict.c,v 1.15 2005/10/06 05:16:35 kuma Exp $
 * $Name:  $
 */

/*
 * Modified for Ruby/RBTree by OZAWA Takuma.
 */

#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
#include "dict.h"

#include <ruby.h>

#ifdef KAZLIB_RCSID
static const char rcsid[] = "$Id: dict.c,v 1.15 2005/10/06 05:16:35 kuma Exp $";
#endif

/*
 * These macros provide short convenient names for structure members,
 * which are embellished with dict_ prefixes so that they are
 * properly confined to the documented namespace. It's legal for a 
 * program which uses dict to define, for instance, a macro called ``parent''.
 * Such a macro would interfere with the dnode_t struct definition.
 * In general, highly portable and reusable C modules which expose their
 * structures need to confine structure member names to well-defined spaces.
 * The resulting identifiers aren't necessarily convenient to use, nor
 * readable, in the implementation, however!
 */

#define left dict_left
#define right dict_right
#define parent dict_parent
#define color dict_color
#define key dict_key
#define data dict_data

#define nilnode dict_nilnode
#define nodecount dict_nodecount
#define compare dict_compare
#define allocnode dict_allocnode
#define freenode dict_freenode
#define context dict_context
#define dupes dict_dupes

#define dictptr dict_dictptr

#define dict_root(D) ((D)->nilnode.left)
#define dict_nil(D) (&(D)->nilnode)
#define DICT_DEPTH_MAX 64

#define COMPARE(dict, key1, key2) dict->compare(key1, key2, dict->context)

static dnode_t *dnode_alloc(void *context);
static void dnode_free(dnode_t *node, void *context);

/*
 * Perform a ``left rotation'' adjustment on the tree.  The given node P and
 * its right child C are rearranged so that the P instead becomes the left
 * child of C.   The left subtree of C is inherited as the new right subtree
 * for P.  The ordering of the keys within the tree is thus preserved.
 */

static void rotate_left(dnode_t *upper)
{
    dnode_t *lower, *lowleft, *upparent;

    lower = upper->right;
    upper->right = lowleft = lower->left;
    lowleft->parent = upper;

    lower->parent = upparent = upper->parent;

    /* don't need to check for root node here because root->parent is
       the sentinel nil node, and root->parent->left points back to root */

    if (upper == upparent->left) {
	upparent->left = lower;
    } else {
	assert (upper == upparent->right);
	upparent->right = lower;
    }

    lower->left = upper;
    upper->parent = lower;
}

/*
 * This operation is the ``mirror'' image of rotate_left. It is
 * the same procedure, but with left and right interchanged.
 */

static void rotate_right(dnode_t *upper)
{
    dnode_t *lower, *lowright, *upparent;

    lower = upper->left;
    upper->left = lowright = lower->right;
    lowright->parent = upper;

    lower->parent = upparent = upper->parent;

    if (upper == upparent->right) {
	upparent->right = lower;
    } else {
	assert (upper == upparent->left);
	upparent->left = lower;
    }

    lower->right = upper;
    upper->parent = lower;
}

/*
 * Do a postorder traversal of the tree rooted at the specified
 * node and free everything under it.  Used by dict_free().
 */

static void free_nodes(dict_t *dict, dnode_t *node, dnode_t *nil)
{
    if (node == nil)
	return;
    free_nodes(dict, node->left, nil);
    free_nodes(dict, node->right, nil);
    dict->freenode(node, dict->context);
}

/*
 * This procedure performs a verification that the given subtree is a binary
 * search tree. It performs an inorder traversal of the tree using the
 * dict_next() successor function, verifying that the key of each node is
 * strictly lower than that of its successor, if duplicates are not allowed,
 * or lower or equal if duplicates are allowed.  This function is used for
 * debugging purposes. 
 */

static int verify_bintree(dict_t *dict)
{
    dnode_t *first, *next;

    first = dict_first(dict);

    if (dict->dupes) {
        while (first && (next = dict_next(dict, first))) {
            if (COMPARE(dict, first->key, next->key) > 0)
                return 0;
            first = next;
        }
    } else {
        while (first && (next = dict_next(dict, first))) {
            if (COMPARE(dict, first->key, next->key) >= 0)
                return 0;
            first = next;
        }
    }
    return 1;
}


/*
 * This function recursively verifies that the given binary subtree satisfies
 * three of the red black properties. It checks that every red node has only
 * black children. It makes sure that each node is either red or black. And it
 * checks that every path has the same count of black nodes from root to leaf.
 * It returns the blackheight of the given subtree; this allows blackheights to
 * be computed recursively and compared for left and right siblings for
 * mismatches. It does not check for every nil node being black, because there
 * is only one sentinel nil node. The return value of this function is the
 * black height of the subtree rooted at the node ``root'', or zero if the
 * subtree is not red-black.
 */

static unsigned int verify_redblack(dnode_t *nil, dnode_t *root)
{
    unsigned height_left, height_right;

    if (root != nil) {
	height_left = verify_redblack(nil, root->left);
	height_right = verify_redblack(nil, root->right);
	if (height_left == 0 || height_right == 0)
	    return 0;
	if (height_left != height_right)
	    return 0;
	if (root->color == dnode_red) {
	    if (root->left->color != dnode_black)
		return 0;
	    if (root->right->color != dnode_black)
		return 0;
	    return height_left;
	}
	if (root->color != dnode_black)
	    return 0;
	return height_left + 1;
    } 
    return 1;
}

/*
 * Compute the actual count of nodes by traversing the tree and
 * return it. This could be compared against the stored count to
 * detect a mismatch.
 */

static dictcount_t verify_node_count(dnode_t *nil, dnode_t *root)
{
    if (root == nil)
	return 0;
    else
	return 1 + verify_node_count(nil, root->left)
	    + verify_node_count(nil, root->right);
}

/*
 * Verify that the tree contains the given node. This is done by
 * traversing all of the nodes and comparing their pointers to the
 * given pointer. Returns 1 if the node is found, otherwise
 * returns zero. It is intended for debugging purposes.
 */

static int verify_dict_has_node(dnode_t *nil, dnode_t *root, dnode_t *node)
{
    if (root != nil) {
	return root == node
		|| verify_dict_has_node(nil, root->left, node)
		|| verify_dict_has_node(nil, root->right, node);
    }
    return 0;
}


/*
 * Dynamically allocate and initialize a dictionary object.
 */

dict_t *dict_create(dict_comp_t comp)
{
    dict_t* new = ALLOC(dict_t);
    
    if (new) {
	new->compare = comp;
	new->allocnode = dnode_alloc;
	new->freenode = dnode_free;
	new->context = NULL;
	new->nodecount = 0;
	new->nilnode.left = &new->nilnode;
	new->nilnode.right = &new->nilnode;
	new->nilnode.parent = &new->nilnode;
	new->nilnode.color = dnode_black;
        new->dupes = 0;
    }
    return new;
}

/*
 * Select a different set of node allocator routines.
 */

void dict_set_allocator(dict_t *dict, dnode_alloc_t al,
	dnode_free_t fr, void *context)
{
    assert (dict_count(dict) == 0);
    assert ((al == NULL && fr == NULL) || (al != NULL && fr != NULL));

    dict->allocnode = al ? al : dnode_alloc;
    dict->freenode = fr ? fr : dnode_free;
    dict->context = context;
}

/*
 * Free a dynamically allocated dictionary object. Removing the nodes
 * from the tree before deleting it is required.
 */

void dict_destroy(dict_t *dict)
{
    assert (dict_isempty(dict));
    xfree(dict);
}

/*
 * Free all the nodes in the dictionary by using the dictionary's
 * installed free routine. The dictionary is emptied.
 */

void dict_free_nodes(dict_t *dict)
{
    dnode_t *nil = dict_nil(dict), *root = dict_root(dict);
    free_nodes(dict, root, nil);
    dict->nodecount = 0;
    dict->nilnode.left = &dict->nilnode;
    dict->nilnode.right = &dict->nilnode;
    dict->nilnode.parent = &dict->nilnode;
}

/*
 * Obsolescent function, equivalent to dict_free_nodes
 */

void dict_free(dict_t *dict)
{
#ifdef KAZLIB_OBSOLESCENT_DEBUG
    assert ("call to obsolescent function dict_free()" && 0);
#endif
    dict_free_nodes(dict);
}

/*
 * Initialize a user-supplied dictionary object.
 */

dict_t *dict_init(dict_t *dict, dict_comp_t comp)
{
    dict->compare = comp;
    dict->allocnode = dnode_alloc;
    dict->freenode = dnode_free;
    dict->context = NULL;
    dict->nodecount = 0;
    dict->nilnode.left = &dict->nilnode;
    dict->nilnode.right = &dict->nilnode;
    dict->nilnode.parent = &dict->nilnode;
    dict->nilnode.color = dnode_black;
    dict->dupes = 0;
    return dict;
}

/* 
 * Initialize a dictionary in the likeness of another dictionary
 */

void dict_init_like(dict_t *dict, const dict_t *template)
{
    dict->compare = template->compare;
    dict->allocnode = template->allocnode;
    dict->freenode = template->freenode;
    dict->context = template->context;
    dict->nodecount = 0;
    dict->nilnode.left = &dict->nilnode;
    dict->nilnode.right = &dict->nilnode;
    dict->nilnode.parent = &dict->nilnode;
    dict->nilnode.color = dnode_black;
    dict->dupes = template->dupes;

    assert (dict_similar(dict, template));
}

/*
 * Remove all nodes from the dictionary (without freeing them in any way).
 */

static void dict_clear(dict_t *dict)
{
    dict->nodecount = 0;
    dict->nilnode.left = &dict->nilnode;
    dict->nilnode.right = &dict->nilnode;
    dict->nilnode.parent = &dict->nilnode;
    assert (dict->nilnode.color == dnode_black);
}

/*
 * Verify the integrity of the dictionary structure.  This is provided for
 * debugging purposes, and should be placed in assert statements.   Just because
 * this function succeeds doesn't mean that the tree is not corrupt. Certain
 * corruptions in the tree may simply cause undefined behavior.
 */ 

int dict_verify(dict_t *dict)
{
    dnode_t *nil = dict_nil(dict), *root = dict_root(dict);

    /* check that the sentinel node and root node are black */
    if (root->color != dnode_black)
	return 0;
    if (nil->color != dnode_black)
	return 0;
    if (nil->right != nil)
	return 0;
    /* nil->left is the root node; check that its parent pointer is nil */
    if (nil->left->parent != nil)
	return 0;
    /* perform a weak test that the tree is a binary search tree */
    if (!verify_bintree(dict))
	return 0;
    /* verify that the tree is a red-black tree */
    if (!verify_redblack(nil, root))
	return 0;
    if (verify_node_count(nil, root) != dict_count(dict))
	return 0;
    return 1;
}

/*
 * Determine whether two dictionaries are similar: have the same comparison and
 * allocator functions, and same status as to whether duplicates are allowed.
 */

int dict_similar(const dict_t *left, const dict_t *right)
{
    if (left->compare != right->compare)
	return 0;

    if (left->allocnode != right->allocnode)
	return 0;

    if (left->freenode != right->freenode)
	return 0;

    if (left->context != right->context)
	return 0;

/*     if (left->dupes != right->dupes) */
/*         return 0; */

    return 1;
}

/*
 * Locate a node in the dictionary having the given key.
 * If the node is not found, a null a pointer is returned (rather than 
 * a pointer that dictionary's nil sentinel node), otherwise a pointer to the
 * located node is returned.
 */

dnode_t *dict_lookup(dict_t *dict, const void *key)
{
    dnode_t *root = dict_root(dict);
    dnode_t *nil = dict_nil(dict);
    dnode_t *saved;
    int result;

    /* simple binary search adapted for trees that contain duplicate keys */

    while (root != nil) {
	result = COMPARE(dict, key, root->key);
	if (result < 0)
	    root = root->left;
	else if (result > 0)
	    root = root->right;
	else {
            if (!dict->dupes) { /* no duplicates, return match          */
                return root;
            } else {            /* could be dupes, find leftmost one    */
                do {
                    saved = root;
                    root = root->left;
                    while (root != nil && COMPARE(dict, key, root->key))
                        root = root->right;
                } while (root != nil);
                return saved;
            }
        }
    }

    return NULL;
}

/*
 * Look for the node corresponding to the lowest key that is equal to or
 * greater than the given key.  If there is no such node, return null.
 */

dnode_t *dict_lower_bound(dict_t *dict, const void *key)
{
    dnode_t *root = dict_root(dict);
    dnode_t *nil = dict_nil(dict);
    dnode_t *tentative = 0;

    while (root != nil) {
	int result = COMPARE(dict, key, root->key);
        
	if (result > 0) {
	    root = root->right;
	} else if (result < 0) {
	    tentative = root;
	    root = root->left;
	} else {
            if (!dict->dupes) {
                return root;
            } else {
                tentative = root;
                root = root->left;
            }
        }
    }
    
    return tentative;
}

/*
 * Look for the node corresponding to the greatest key that is equal to or
 * lower than the given key.  If there is no such node, return null.
 */

dnode_t *dict_upper_bound(dict_t *dict, const void *key)
{
    dnode_t *root = dict_root(dict);
    dnode_t *nil = dict_nil(dict);
    dnode_t *tentative = 0;

    while (root != nil) {
	int result = COMPARE(dict, key, root->key);

	if (result < 0) {
	    root = root->left;
	} else if (result > 0) {
	    tentative = root;
	    root = root->right;
	} else {
            if (!dict->dupes) {
                return root;
            } else {
                tentative = root;
                root = root->right;
            }
        }
    }
    
    return tentative;
}

/*
 * Insert a node into the dictionary. The node should have been
 * initialized with a data field. All other fields are ignored.
 * The behavior is undefined if the user attempts to insert into
 * a dictionary that is already full (for which the dict_isfull()
 * function returns true).
 */

int dict_insert(dict_t *dict, dnode_t *node, const void *key)
{
    dnode_t *where = dict_root(dict), *nil = dict_nil(dict);
    dnode_t *parent = nil, *uncle, *grandpa;
    int result = -1;

    node->key = key;

    assert (!dict_isfull(dict));
    assert (!dict_contains(dict, node));
    assert (!dnode_is_in_a_dict(node));

    /* basic binary tree insert */
    
    while (where != nil) {
	parent = where;
	result = COMPARE(dict, key, where->key);
	/* trap attempts at duplicate key insertion unless it's explicitly allowed */

        if (!dict->dupes && result == 0) {
            where->data = node->data;
            return 0;
        } else if (result < 0) {
            where = where->left;
        } else {
            where = where->right;
        }
    }

    assert (where == nil);

    if (result < 0)
	parent->left = node;
    else
	parent->right = node;

    node->parent = parent;
    node->left = nil;
    node->right = nil;

    dict->nodecount++;

    /* red black adjustments */

    node->color = dnode_red;

    while (parent->color == dnode_red) {
	grandpa = parent->parent;
	if (parent == grandpa->left) {
	    uncle = grandpa->right;
	    if (uncle->color == dnode_red) {	/* red parent, red uncle */
		parent->color = dnode_black;
		uncle->color = dnode_black;
		grandpa->color = dnode_red;
		node = grandpa;
		parent = grandpa->parent;
	    } else {				/* red parent, black uncle */
	    	if (node == parent->right) {
		    rotate_left(parent);
		    parent = node;
		    assert (grandpa == parent->parent);
		    /* rotation between parent and child preserves grandpa */
		}
		parent->color = dnode_black;
		grandpa->color = dnode_red;
		rotate_right(grandpa);
		break;
	    }
	} else { 	/* symmetric cases: parent == parent->parent->right */
	    uncle = grandpa->left;
	    if (uncle->color == dnode_red) {
		parent->color = dnode_black;
		uncle->color = dnode_black;
		grandpa->color = dnode_red;
		node = grandpa;
		parent = grandpa->parent;
	    } else {
	    	if (node == parent->left) {
		    rotate_right(parent);
		    parent = node;
		    assert (grandpa == parent->parent);
		}
		parent->color = dnode_black;
		grandpa->color = dnode_red;
		rotate_left(grandpa);
		break;
	    }
	}
    }

    dict_root(dict)->color = dnode_black;

    assert (dict_verify(dict));
    return 1;
}

/*
 * Delete the given node from the dictionary. If the given node does not belong
 * to the given dictionary, undefined behavior results.  A pointer to the
 * deleted node is returned.
 */

dnode_t *dict_delete(dict_t *dict, dnode_t *delete)
{
    dnode_t *nil = dict_nil(dict), *child, *delparent = delete->parent;

    /* basic deletion */

    assert (!dict_isempty(dict));
    assert (dict_contains(dict, delete));

    /*
     * If the node being deleted has two children, then we replace it with its
     * successor (i.e. the leftmost node in the right subtree.) By doing this,
     * we avoid the traditional algorithm under which the successor's key and
     * value *only* move to the deleted node and the successor is spliced out
     * from the tree. We cannot use this approach because the user may hold
     * pointers to the successor, or nodes may be inextricably tied to some
     * other structures by way of embedding, etc. So we must splice out the
     * node we are given, not some other node, and must not move contents from
     * one node to another behind the user's back.
     */

    if (delete->left != nil && delete->right != nil) {
	dnode_t *next = dict_next(dict, delete);
	dnode_t *nextparent = next->parent;
	dnode_color_t nextcolor = next->color;

	assert (next != nil);
	assert (next->parent != nil);
	assert (next->left == nil);

	/*
	 * First, splice out the successor from the tree completely, by
	 * moving up its right child into its place.
	 */

	child = next->right;
	child->parent = nextparent;

	if (nextparent->left == next) {
	    nextparent->left = child;
	} else {
	    assert (nextparent->right == next);
	    nextparent->right = child;
	}

	/*
	 * Now that the successor has been extricated from the tree, install it
	 * in place of the node that we want deleted.
	 */

	next->parent = delparent;
	next->left = delete->left;
	next->right = delete->right;
	next->left->parent = next;
	next->right->parent = next;
	next->color = delete->color;
	delete->color = nextcolor;

	if (delparent->left == delete) {
	    delparent->left = next;
	} else {
	    assert (delparent->right == delete);
	    delparent->right = next;
	}

    } else {
	assert (delete != nil);
	assert (delete->left == nil || delete->right == nil);

	child = (delete->left != nil) ? delete->left : delete->right;

	child->parent = delparent = delete->parent;	    

	if (delete == delparent->left) {
	    delparent->left = child;    
	} else {
	    assert (delete == delparent->right);
	    delparent->right = child;
	}
    }

    delete->parent = NULL;
    delete->right = NULL;
    delete->left = NULL;

    dict->nodecount--;

    assert (verify_bintree(dict));

    /* red-black adjustments */

    if (delete->color == dnode_black) {
	dnode_t *parent, *sister;

	dict_root(dict)->color = dnode_red;

	while (child->color == dnode_black) {
	    parent = child->parent;
	    if (child == parent->left) {
		sister = parent->right;
		assert (sister != nil);
		if (sister->color == dnode_red) {
		    sister->color = dnode_black;
		    parent->color = dnode_red;
		    rotate_left(parent);
		    sister = parent->right;
		    assert (sister != nil);
		}
		if (sister->left->color == dnode_black
			&& sister->right->color == dnode_black) {
		    sister->color = dnode_red;
		    child = parent;
		} else {
		    if (sister->right->color == dnode_black) {
			assert (sister->left->color == dnode_red);
			sister->left->color = dnode_black;
			sister->color = dnode_red;
			rotate_right(sister);
			sister = parent->right;
			assert (sister != nil);
		    }
		    sister->color = parent->color;
		    sister->right->color = dnode_black;
		    parent->color = dnode_black;
		    rotate_left(parent);
		    break;
		}
	    } else {	/* symmetric case: child == child->parent->right */
		assert (child == parent->right);
		sister = parent->left;
		assert (sister != nil);
		if (sister->color == dnode_red) {
		    sister->color = dnode_black;
		    parent->color = dnode_red;
		    rotate_right(parent);
		    sister = parent->left;
		    assert (sister != nil);
		}
		if (sister->right->color == dnode_black
			&& sister->left->color == dnode_black) {
		    sister->color = dnode_red;
		    child = parent;
		} else {
		    if (sister->left->color == dnode_black) {
			assert (sister->right->color == dnode_red);
			sister->right->color = dnode_black;
			sister->color = dnode_red;
			rotate_left(sister);
			sister = parent->left;
			assert (sister != nil);
		    }
		    sister->color = parent->color;
		    sister->left->color = dnode_black;
		    parent->color = dnode_black;
		    rotate_right(parent);
		    break;
		}
	    }
	}

	child->color = dnode_black;
	dict_root(dict)->color = dnode_black;
    }

    assert (dict_verify(dict));

    return delete;
}

/*
 * Allocate a node using the dictionary's allocator routine, give it
 * the data item.
 */

int dict_alloc_insert(dict_t *dict, const void *key, void *data)
{
    dnode_t *node = dict->allocnode(dict->context);

    if (node) {
	dnode_init(node, data);
	if (!dict_insert(dict, node, key))
            dict->freenode(node, dict->context);
	return 1;
    }
    return 0;
}

void dict_delete_free(dict_t *dict, dnode_t *node)
{
    dict_delete(dict, node);
    dict->freenode(node, dict->context);
}

/*
 * Return the node with the lowest (leftmost) key. If the dictionary is empty
 * (that is, dict_isempty(dict) returns 1) a null pointer is returned.
 */

dnode_t *dict_first(dict_t *dict)
{
    dnode_t *nil = dict_nil(dict), *root = dict_root(dict), *left;

    if (root != nil)
	while ((left = root->left) != nil)
	    root = left;

    return (root == nil) ? NULL : root;
}

/*
 * Return the node with the highest (rightmost) key. If the dictionary is empty
 * (that is, dict_isempty(dict) returns 1) a null pointer is returned.
 */

dnode_t *dict_last(dict_t *dict)
{
    dnode_t *nil = dict_nil(dict), *root = dict_root(dict), *right;

    if (root != nil)
	while ((right = root->right) != nil)
	    root = right;

    return (root == nil) ? NULL : root;
}

/*
 * Return the given node's successor node---the node which has the
 * next key in the the left to right ordering. If the node has
 * no successor, a null pointer is returned rather than a pointer to
 * the nil node.
 */

dnode_t *dict_next(dict_t *dict, dnode_t *curr)
{
    dnode_t *nil = dict_nil(dict), *parent, *left;

    if (curr->right != nil) {
	curr = curr->right;
	while ((left = curr->left) != nil)
	    curr = left;
	return curr;
    }

    parent = curr->parent;

    while (parent != nil && curr == parent->right) {
	curr = parent;
	parent = curr->parent;
    }

    return (parent == nil) ? NULL : parent;
}

/*
 * Return the given node's predecessor, in the key order.
 * The nil sentinel node is returned if there is no predecessor.
 */

dnode_t *dict_prev(dict_t *dict, dnode_t *curr)
{
    dnode_t *nil = dict_nil(dict), *parent, *right;

    if (curr->left != nil) {
	curr = curr->left;
	while ((right = curr->right) != nil)
	    curr = right;
	return curr;
    }

    parent = curr->parent;

    while (parent != nil && curr == parent->left) {
	curr = parent;
	parent = curr->parent;
    }

    return (parent == nil) ? NULL : parent;
}

void dict_allow_dupes(dict_t *dict)
{
    dict->dupes = 1;
}

dictcount_t dict_count(dict_t *dict)
{
    return dict->nodecount;
}

int dict_isempty(dict_t *dict)
{
    return dict->nodecount == 0;
}

int dict_isfull(dict_t *dict)
{
    return dict->nodecount == DICTCOUNT_T_MAX;
}

int dict_contains(dict_t *dict, dnode_t *node)
{
    return verify_dict_has_node(dict_nil(dict), dict_root(dict), node);
}

static dnode_t *dnode_alloc(void *context)
{
    return malloc(sizeof *dnode_alloc(NULL));
}

static void dnode_free(dnode_t *node, void *context)
{
    free(node);
}

dnode_t *dnode_create(void *data)
{
    dnode_t *new = malloc(sizeof *new);
    if (new) {
	new->data = data;
	new->parent = NULL;
	new->left = NULL;
	new->right = NULL;
    }
    return new;
}

dnode_t *dnode_init(dnode_t *dnode, void *data)
{
    dnode->data = data;
    dnode->parent = NULL;
    dnode->left = NULL;
    dnode->right = NULL;
    return dnode;
}

void dnode_destroy(dnode_t *dnode)
{
    assert (!dnode_is_in_a_dict(dnode));
    free(dnode);
}

void *dnode_get(dnode_t *dnode)
{
    return dnode->data;
}

const void *dnode_getkey(dnode_t *dnode)
{
    return dnode->key;
}

void dnode_put(dnode_t *dnode, void *data)
{
    dnode->data = data;
}

int dnode_is_in_a_dict(dnode_t *dnode)
{
    return (dnode->parent && dnode->left && dnode->right);
}

void dict_process(dict_t *dict, void *context, dnode_process_t function)
{
    dnode_t *node = dict_first(dict), *next;

    while (node != NULL) {
	/* check for callback function deleting	*/
	/* the next node from under us		*/
	assert (dict_contains(dict, node));
	next = dict_next(dict, node);
	function(dict, node, context);
	node = next;
    }
}

static void load_begin_internal(dict_load_t *load, dict_t *dict)
{
    load->dictptr = dict;
    load->nilnode.left = &load->nilnode;
    load->nilnode.right = &load->nilnode;
}

void dict_load_begin(dict_load_t *load, dict_t *dict)
{
    assert (dict_isempty(dict));
    load_begin_internal(load, dict);
}

void dict_load_next(dict_load_t *load, dnode_t *newnode, const void *key)
{
    dict_t *dict = load->dictptr;
    dnode_t *nil = &load->nilnode;
    
    assert (!dnode_is_in_a_dict(newnode));
    assert (dict->nodecount < DICTCOUNT_T_MAX);

    #ifndef NDEBUG
    if (dict->nodecount > 0) {
        if (dict->dupes)
            assert (COMPARE(dict, nil->left->key, key) <= 0);
        else
            assert (COMPARE(dict, nil->left->key, key) < 0);
    }
    #endif

    newnode->key = key;
    nil->right->left = newnode;
    nil->right = newnode;
    newnode->left = nil;
    dict->nodecount++;
}

void dict_load_end(dict_load_t *load)
{
    dict_t *dict = load->dictptr;
    dnode_t *tree[DICT_DEPTH_MAX] = { 0 };
    dnode_t *curr, *dictnil = dict_nil(dict), *loadnil = &load->nilnode, *next;
    dnode_t *complete = 0;
    dictcount_t fullcount = DICTCOUNT_T_MAX, nodecount = dict->nodecount;
    dictcount_t botrowcount;
    unsigned baselevel = 0, level = 0, i;

    assert (dnode_red == 0 && dnode_black == 1);

    while (fullcount >= nodecount && fullcount)
	fullcount >>= 1;

    botrowcount = nodecount - fullcount;

    for (curr = loadnil->left; curr != loadnil; curr = next) {
	next = curr->left;

	if (complete == NULL && botrowcount-- == 0) {
	    assert (baselevel == 0);
	    assert (level == 0);
	    baselevel = level = 1;
	    complete = tree[0];

	    if (complete != 0) {
		tree[0] = 0;
		complete->right = dictnil;
		while (tree[level] != 0) {
		    tree[level]->right = complete;
		    complete->parent = tree[level];
		    complete = tree[level];
		    tree[level++] = 0;
		}
	    }
	}

	if (complete == NULL) {
	    curr->left = dictnil;
	    curr->right = dictnil;
	    curr->color = level % 2;
	    complete = curr;

	    assert (level == baselevel);
	    while (tree[level] != 0) {
		tree[level]->right = complete;
		complete->parent = tree[level];
		complete = tree[level];
		tree[level++] = 0;
	    }
	} else {
	    curr->left = complete;
	    curr->color = (level + 1) % 2;
	    complete->parent = curr;
	    tree[level] = curr;
	    complete = 0;
	    level = baselevel;
	}
    }

    if (complete == NULL)
	complete = dictnil;

    for (i = 0; i < DICT_DEPTH_MAX; i++) {
	if (tree[i] != 0) {
	    tree[i]->right = complete;
	    complete->parent = tree[i];
	    complete = tree[i];
	}
    }

    dictnil->color = dnode_black;
    dictnil->right = dictnil;
    complete->parent = dictnil;
    complete->color = dnode_black;
    dict_root(dict) = complete;

    assert (dict_verify(dict));
}

void dict_merge(dict_t *dest, dict_t *source)
{
    dict_load_t load;
    dnode_t *leftnode = dict_first(dest), *rightnode = dict_first(source);

    assert (dict_similar(dest, source));	

    if (source == dest)
	return;

    dest->nodecount = 0;
    load_begin_internal(&load, dest);

    for (;;) {
	if (leftnode != NULL && rightnode != NULL) {
	    if (COMPARE(dest, leftnode->key, rightnode->key) < 0)
		goto copyleft;
	    else
		goto copyright;
	} else if (leftnode != NULL) {
	    goto copyleft;
	} else if (rightnode != NULL) {
	    goto copyright;
	} else {
	    assert (leftnode == NULL && rightnode == NULL);
	    break;
	}

    copyleft:
	{
	    dnode_t *next = dict_next(dest, leftnode);
	    #ifndef NDEBUG
	    leftnode->left = NULL;	/* suppress assertion in dict_load_next */
	    #endif
	    dict_load_next(&load, leftnode, leftnode->key);
	    leftnode = next;
	    continue;
	}
	
    copyright:
	{
	    dnode_t *next = dict_next(source, rightnode);
	    #ifndef NDEBUG
	    rightnode->left = NULL;
	    #endif
	    dict_load_next(&load, rightnode, rightnode->key);
	    rightnode = next;
	    continue;
	}
    }

    dict_clear(source);
    dict_load_end(&load);
}

int dict_equal(dict_t* dict1, dict_t* dict2,
               dict_value_eql_t value_eql)
{
    dnode_t* node1;
    dnode_t* node2;

    if (dict_count(dict1) != dict_count(dict2))
        return 0; 
    if (!dict_similar(dict1, dict2))
        return 0;
    
    for (node1 = dict_first(dict1), node2 = dict_first(dict2);
         node1 != NULL && node2 != NULL;
         node1 = dict_next(dict1, node1), node2 = dict_next(dict2, node2)) {
        
        if (COMPARE(dict1, node1->key, node2->key) != 0)
            return 0;
        if (!value_eql(node1->data, node2->data))
            return 0;
    }
    return 1;
}
