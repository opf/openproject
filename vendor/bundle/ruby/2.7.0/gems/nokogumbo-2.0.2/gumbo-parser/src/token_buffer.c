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

#include <assert.h>

#include "ascii.h"
#include "token_buffer.h"
#include "tokenizer.h"
#include "util.h"

struct GumboInternalCharacterToken {
  GumboSourcePosition position;
  GumboStringPiece original_text;
  int c;
};

void gumbo_character_token_buffer_init(GumboCharacterTokenBuffer* buffer) {
  buffer->data = NULL;
  buffer->length = 0;
  buffer->capacity = 0;
}

void gumbo_character_token_buffer_append (
  const GumboToken* token,
  GumboCharacterTokenBuffer* buffer
) {
  assert(token->type == GUMBO_TOKEN_WHITESPACE
         || token->type == GUMBO_TOKEN_CHARACTER);
  if (buffer->length == buffer->capacity) {
    if (buffer->capacity == 0)
      buffer->capacity = 10;
    else
      buffer->capacity *= 2;
    size_t bytes = sizeof(*buffer->data) * buffer->capacity;
    buffer->data = gumbo_realloc(buffer->data, bytes);
  }
  size_t index = buffer->length++;
  buffer->data[index].position = token->position;
  buffer->data[index].original_text = token->original_text;
  buffer->data[index].c = token->v.character;
}

void gumbo_character_token_buffer_get (
  const GumboCharacterTokenBuffer* buffer,
  size_t index,
  struct GumboInternalToken* output
) {
  assert(index < buffer->length);
  int c = buffer->data[index].c;
  output->type = gumbo_ascii_isspace(c)?
    GUMBO_TOKEN_WHITESPACE : GUMBO_TOKEN_CHARACTER;
  output->position = buffer->data[index].position;
  output->original_text = buffer->data[index].original_text;
  output->v.character = c;
}

void gumbo_character_token_buffer_clear(GumboCharacterTokenBuffer* buffer) {
  buffer->length = 0;
}

void gumbo_character_token_buffer_destroy(GumboCharacterTokenBuffer* buffer) {
  gumbo_free(buffer->data);
  buffer->data = NULL;
  buffer->length = 0;
  buffer->capacity = 0;
}
