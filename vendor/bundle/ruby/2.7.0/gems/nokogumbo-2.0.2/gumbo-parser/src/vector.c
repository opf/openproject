/*
 Copyright 2018 Craig Barnes.
 Copyright 2010 Google Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "vector.h"
#include "util.h"

void gumbo_vector_init(unsigned int initial_capacity, GumboVector* vector) {
  vector->length = 0;
  vector->capacity = initial_capacity;
  if (initial_capacity > 0) {
    vector->data = gumbo_alloc(sizeof(void*) * initial_capacity);
  } else {
    vector->data = NULL;
  }
}

void gumbo_vector_destroy(GumboVector* vector) {
  if (vector->capacity > 0) {
    gumbo_free(vector->data);
  }
}

static void enlarge_vector_if_full(GumboVector* vector) {
  if (vector->length >= vector->capacity) {
    if (vector->capacity) {
      vector->capacity *= 2;
      size_t num_bytes = sizeof(void*) * vector->capacity;
      vector->data = gumbo_realloc(vector->data, num_bytes);
    } else {
      // 0-capacity vector; no previous array to deallocate.
      vector->capacity = 2;
      vector->data = gumbo_alloc(sizeof(void*) * vector->capacity);
    }
  }
}

void gumbo_vector_add(void* element, GumboVector* vector) {
  enlarge_vector_if_full(vector);
  assert(vector->data);
  assert(vector->length < vector->capacity);
  vector->data[vector->length++] = element;
}

void* gumbo_vector_pop(GumboVector* vector) {
  if (vector->length == 0) {
    return NULL;
  }
  return vector->data[--vector->length];
}

int gumbo_vector_index_of(GumboVector* vector, const void* element) {
  for (unsigned int i = 0; i < vector->length; ++i) {
    if (vector->data[i] == element) {
      return i;
    }
  }
  return -1;
}

void gumbo_vector_insert_at (
  void* element,
  unsigned int index,
  GumboVector* vector
) {
  assert(index <= vector->length);
  enlarge_vector_if_full(vector);
  ++vector->length;
  memmove (
    &vector->data[index + 1],
    &vector->data[index],
    sizeof(void*) * (vector->length - index - 1)
  );
  vector->data[index] = element;
}

void gumbo_vector_remove(void* node, GumboVector* vector) {
  int index = gumbo_vector_index_of(vector, node);
  if (index == -1) {
    return;
  }
  gumbo_vector_remove_at(index, vector);
}

void* gumbo_vector_remove_at(unsigned int index, GumboVector* vector) {
  assert(index < vector->length);
  void* result = vector->data[index];
  memmove (
    &vector->data[index],
    &vector->data[index + 1],
    sizeof(void*) * (vector->length - index - 1)
  );
  --vector->length;
  return result;
}
