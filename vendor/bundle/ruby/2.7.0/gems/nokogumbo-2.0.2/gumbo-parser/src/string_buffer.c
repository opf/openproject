/*
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

#include <string.h>
#include "string_buffer.h"
#include "util.h"

// Size chosen via statistical analysis of ~60K websites.
// 99% of text nodes and 98% of attribute names/values fit in this initial size.
static const size_t kDefaultStringBufferSize = 5;

static void maybe_resize_string_buffer (
  size_t additional_chars,
  GumboStringBuffer* buffer
) {
  size_t new_length = buffer->length + additional_chars;
  size_t new_capacity = buffer->capacity;
  while (new_capacity < new_length) {
    new_capacity *= 2;
  }
  if (new_capacity != buffer->capacity) {
    buffer->data = gumbo_realloc(buffer->data, new_capacity);
    buffer->capacity = new_capacity;
  }
}

void gumbo_string_buffer_init(GumboStringBuffer* output) {
  output->data = gumbo_alloc(kDefaultStringBufferSize);
  output->length = 0;
  output->capacity = kDefaultStringBufferSize;
}

void gumbo_string_buffer_reserve (
  size_t min_capacity,
  GumboStringBuffer* output
) {
  maybe_resize_string_buffer(min_capacity - output->length, output);
}

void gumbo_string_buffer_append_codepoint (
  int c,
  GumboStringBuffer* output
) {
  // num_bytes is actually the number of continuation bytes, 1 less than the
  // total number of bytes. This is done to keep the loop below simple and
  // should probably change if we unroll it.
  int num_bytes, prefix;
  if (c <= 0x7f) {
    num_bytes = 0;
    prefix = 0;
  } else if (c <= 0x7ff) {
    num_bytes = 1;
    prefix = 0xc0;
  } else if (c <= 0xffff) {
    num_bytes = 2;
    prefix = 0xe0;
  } else {
    num_bytes = 3;
    prefix = 0xf0;
  }
  maybe_resize_string_buffer(num_bytes + 1, output);
  output->data[output->length++] = prefix | (c >> (num_bytes * 6));
  for (int i = num_bytes - 1; i >= 0; --i) {
    output->data[output->length++] = 0x80 | (0x3f & (c >> (i * 6)));
  }
}

void gumbo_string_buffer_append_string (
  const GumboStringPiece* str,
  GumboStringBuffer* output
) {
  maybe_resize_string_buffer(str->length, output);
  memcpy(output->data + output->length, str->data, str->length);
  output->length += str->length;
}

char* gumbo_string_buffer_to_string(const GumboStringBuffer* input) {
  char* buffer = gumbo_alloc(input->length + 1);
  memcpy(buffer, input->data, input->length);
  buffer[input->length] = '\0';
  return buffer;
}

void gumbo_string_buffer_clear(GumboStringBuffer* input) {
  input->length = 0;
}

void gumbo_string_buffer_destroy(GumboStringBuffer* buffer) {
  gumbo_free(buffer->data);
}
