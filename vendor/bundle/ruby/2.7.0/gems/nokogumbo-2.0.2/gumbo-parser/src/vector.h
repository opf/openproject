#ifndef GUMBO_VECTOR_H_
#define GUMBO_VECTOR_H_

#include "gumbo.h"

#ifdef __cplusplus
extern "C" {
#endif

// Initializes a new GumboVector with the specified initial capacity.
void gumbo_vector_init(unsigned int initial_capacity, GumboVector* vector);

// Frees the memory used by a GumboVector. Does not free the contained
// pointers.
void gumbo_vector_destroy(GumboVector* vector);

// Adds a new element to a GumboVector.
void gumbo_vector_add(void* element, GumboVector* vector);

// Removes and returns the element most recently added to the GumboVector.
// Ownership is transferred to caller. Capacity is unchanged. If the vector is
// empty, NULL is returned.
void* gumbo_vector_pop(GumboVector* vector);

// Inserts an element at a specific index. This is potentially O(N) time, but
// is necessary for some of the spec's behavior.
void gumbo_vector_insert_at (
  void* element,
  unsigned int index,
  GumboVector* vector
);

// Removes an element from the vector, or does nothing if the element is not in
// the vector.
void gumbo_vector_remove(void* element, GumboVector* vector);

// Removes and returns an element at a specific index. Note that this is
// potentially O(N) time and should be used sparingly.
void* gumbo_vector_remove_at(unsigned int index, GumboVector* vector);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_VECTOR_H_
