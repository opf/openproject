/*
 Copyright 2018 Stephen Checkoway

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

#ifndef GUMBO_TOKEN_BUFFER_H
#define GUMBO_TOKEN_BUFFER_H

#include <stdbool.h>
#include <stddef.h>

#include "gumbo.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalCharacterToken;
struct GumboInternalToken;

// A struct representing a growable sequence of character (and whitespace)
// tokens.
typedef struct {
  // A pointer to the start of the sequence.
  struct GumboInternalCharacterToken* data;

  // The length of the sequence.
  size_t length;

  // The capacity of the buffer.
  size_t capacity;
} GumboCharacterTokenBuffer;

// Initializes a new GumboCharacterTokenBuffer.
void gumbo_character_token_buffer_init(GumboCharacterTokenBuffer* buffer);

// Appends a character (or whitespace) token.
void gumbo_character_token_buffer_append (
  const struct GumboInternalToken* token,
  GumboCharacterTokenBuffer* buffer
);

void gumbo_character_token_buffer_get (
  const GumboCharacterTokenBuffer* buffer,
  size_t index,
  struct GumboInternalToken* output
);

// Reinitialize this string buffer. This clears it by setting length=0. It
// does not zero out the buffer itself.
void gumbo_character_token_buffer_clear(GumboCharacterTokenBuffer* buffer);

// Deallocates this GumboCharacterTokenBuffer.
void gumbo_character_token_buffer_destroy(GumboCharacterTokenBuffer* buffer);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_TOKEN_BUFFER_H
