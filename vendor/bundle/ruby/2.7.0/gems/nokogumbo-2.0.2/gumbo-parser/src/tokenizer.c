/*
 Copyright 2010 Google Inc.
 Copyright 2017-2018 Craig Barnes
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

/*
 Coding conventions specific to this file:

 1. Functions that fill in a token should be named emit_*, and should be
    followed immediately by a return from the tokenizer.
 2. Functions that shuffle data from temporaries to final API structures
    should be named finish_*, and be called just before the tokenizer exits the
    state that accumulates the temporary.
 3. All internal data structures should be kept in an initialized state from
    tokenizer creation onwards, ready to accept input. When a buffer's flushed
    and reset, it should be deallocated and immediately reinitialized.
 4. Make sure there are appropriate break statements following each state.
 5. Assertions on the state of the temporary and tag buffers are usually a
    good idea, and should go at the entry point of each state when added.
 6. Statement order within states goes:
    1. Add parse errors, if appropriate.
    2. Call finish_* functions to build up tag state.
    2. Switch to new state. Set _reconsume flag if appropriate.
    3. Perform any other temporary buffer manipulation.
    4. Emit tokens
    5. Return/break.
    This order ensures that we can verify that every emit is followed by
    a return, ensures that the correct state is recorded with any parse
    errors, and prevents parse error position from being messed up by
    possible mark/resets in temporary buffer manipulation.
*/

#include <assert.h>
#include <string.h>
#include "tokenizer.h"
#include "ascii.h"
#include "attribute.h"
#include "char_ref.h"
#include "error.h"
#include "gumbo.h"
#include "parser.h"
#include "string_buffer.h"
#include "token_type.h"
#include "tokenizer_states.h"
#include "utf8.h"
#include "util.h"
#include "vector.h"

// Compared against _temporary_buffer to determine if we're in
// double-escaped script mode.
static const GumboStringPiece kScriptTag = {.data = "script", .length = 6};

// An enum for the return value of each individual state. Each of the emit_*
// functions should return EMIT_TOKEN and should be called as
// return emit_foo(parser, ..., output);
// Each of the handle_*_state functions that do not return emit_* should
// instead return CONTINUE to indicate to gumbo_lex to continue lexing.
typedef enum {
  EMIT_TOKEN,
  CONTINUE,
} StateResult;

// This is a struct containing state necessary to build up a tag token,
// character by character.
typedef struct GumboInternalTagState {
  // A buffer to accumulate characters for various GumboStringPiece fields.
  GumboStringBuffer _buffer;

  // A pointer to the start of the original text corresponding to the contents
  // of the buffer.
  const char* _original_text;

  // The current tag enum, computed once the tag name state has finished so that
  // the buffer can be re-used for building up attributes.
  GumboTag _tag;

  // The current tag name. It's set at the same time that _tag is set if _tag
  // is set to GUMBO_TAG_UNKNOWN.
  char *_name;

  // The starting location of the text in the buffer.
  GumboSourcePosition _start_pos;

  // The current list of attributes. This is copied (and ownership of its data
  // transferred) to the GumboStartTag token upon completion of the tag. New
  // attributes are added as soon as their attribute name state is complete, and
  // values are filled in by operating on _attributes.data[attributes.length-1].
  GumboVector /* GumboAttribute */ _attributes;

  // If true, the next attribute value to be finished should be dropped. This
  // happens if a duplicate attribute name is encountered - we want to consume
  // the attribute value, but shouldn't overwrite the existing value.
  bool _drop_next_attr_value;

  // The last start tag to have been emitted by the tokenizer. This is
  // necessary to check for appropriate end tags.
  GumboTag _last_start_tag;

  // If true, then this is a start tag. If false, it's an end tag. This is
  // necessary to generate the appropriate token type at tag-closing time.
  bool _is_start_tag;

  // If true, then this tag is "self-closing" and doesn't have an end tag.
  bool _is_self_closing;
} GumboTagState;

// This is the main tokenizer state struct, containing all state used by in
// tokenizing the input stream.
typedef struct GumboInternalTokenizerState {
  // The current lexer state. Starts in GUMBO_LEX_DATA.
  GumboTokenizerEnum _state;

  // A flag indicating whether the current input character needs to reconsumed
  // in another state, or whether the next input character should be read for
  // the next iteration of the state loop. This is set when the spec reads
  // "Reconsume the current input character in..."
  bool _reconsume_current_input;

  // A flag indicating whether the adjusted current node is a foreign element.
  // This is set by gumbo_tokenizer_set_is_adjusted_current_node_foreign and
  // checked in the markup declaration state.
  bool _is_adjusted_current_node_foreign;

  // A flag indicating whether the tokenizer is in a CDATA section. If so, then
  // text tokens emitted will be GUMBO_TOKEN_CDATA.
  bool _is_in_cdata;

  // Certain states (notably character references) may emit two character tokens
  // at once, but the contract for lex() fills in only one token at a time. The
  // extra character is buffered here, and then this is checked on entry to
  // lex(). If a character is stored here, it's immediately emitted and control
  // returns from the lexer. kGumboNoChar is used to represent 'no character
  // stored.'
  //
  // Note that characters emitted through this mechanism will have their source
  // position marked as the character under the mark, i.e. multiple characters
  // may be emitted with the same position. This is desirable for character
  // references, but unsuitable for many other cases. Use the _temporary_buffer
  // mechanism if the buffered characters must have their original positions in
  // the document.
  int _buffered_emit_char;

  // A temporary buffer to accumulate characters, as described by the "temporary
  // buffer" phrase in the tokenizer spec. We use this in a somewhat unorthodox
  // way: In situations where the spec calls for inserting characters into the
  // temporary buffer that exactly match the input in order to emit them as
  // character tokens, we don't actually do it.
  // Instead, we mark the input and reset the input to it using set_mark() and
  // emit_from_mark(). We do use the temporary buffer for other uses such as
  // DOCTYPEs, comments, and detecting escaped <script> tags.
  GumboStringBuffer _temporary_buffer;

  // The position to resume normal operation after we start emitting from the
  // mark. NULL whenever we're not emitting from the mark.
  const char* _resume_pos;

  // The character reference state uses a return state to return to the state
  // it was invoked from.
  GumboTokenizerEnum _return_state;

  // Numeric character reference.
  uint32_t _character_reference_code;

  // Pointer to the beginning of the current token in the original buffer; used
  // to record the original text.
  const char* _token_start;

  // GumboSourcePosition recording the source location of the start of the
  // current token.
  GumboSourcePosition _token_start_pos;

  // Current tag state.
  GumboTagState _tag_state;

  // Doctype state. We use the temporary buffer to accumulate characters (it's
  // not used for anything else in the doctype states), and then freshly
  // allocate the strings in the doctype token, then copy it over on emit.
  GumboTokenDocType _doc_type_state;

  // The UTF8Iterator over the tokenizer input.
  Utf8Iterator _input;
} GumboTokenizerState;

// Adds a parse error to the parser's error struct.
static void tokenizer_add_parse_error (
  GumboParser* parser,
  GumboErrorType type
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboError* error = gumbo_add_error(parser);
  if (!error) {
    return;
  }
  const Utf8Iterator* input = &tokenizer->_input;
  utf8iterator_get_position(input, &error->position);
  error->original_text.data = utf8iterator_get_char_pointer(input);
  error->original_text.length = utf8iterator_get_width(input);
  error->type = type;
  error->v.tokenizer.state = tokenizer->_state;
  error->v.tokenizer.codepoint = utf8iterator_current(input);
}

// Adds an error pointing at the start of the character reference.
static void tokenizer_add_char_ref_error (
  struct GumboInternalParser* parser,
  GumboErrorType type,
  int codepoint
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboError* error = gumbo_add_error(parser);
  if (!error)
    return;
  Utf8Iterator* input = &tokenizer->_input;
  error->type = type;
  error->position = utf8iterator_get_mark_position(input);
  const char* mark = utf8iterator_get_mark_pointer(input);
  error->original_text.data = mark;
  error->original_text.length = utf8iterator_get_char_pointer(input) - mark;
  error->v.tokenizer.state = tokenizer->_state;
  error->v.tokenizer.codepoint = codepoint;
}

// Adds an error pointing at the start of the token.
static void tokenizer_add_token_parse_error (
  GumboParser* parser,
  GumboErrorType type
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboError* error = gumbo_add_error(parser);
  if (!error)
    return;
  Utf8Iterator* input = &tokenizer->_input;
  error->type = type;
  error->position = tokenizer->_token_start_pos;
  error->original_text.data = tokenizer->_token_start;
  error->original_text.length =
    utf8iterator_get_char_pointer(input) - tokenizer->_token_start;
  error->v.tokenizer.state = tokenizer->_state;
  error->v.tokenizer.codepoint = 0;
}

static bool is_alpha(int c) {
  return gumbo_ascii_isalpha(c);
}

static int ensure_lowercase(int c) {
  return gumbo_ascii_tolower(c);
}

static GumboTokenType get_char_token_type(bool is_in_cdata, int c) {
  if (is_in_cdata && c > 0) {
    return GUMBO_TOKEN_CDATA;
  }

  switch (c) {
    case '\t':
    case '\n':
    case '\r':
    case '\f':
    case ' ':
      return GUMBO_TOKEN_WHITESPACE;
    case 0:
      gumbo_debug("Emitted null byte.\n");
      return GUMBO_TOKEN_NULL;
    case -1:
      return GUMBO_TOKEN_EOF;
    default:
      return GUMBO_TOKEN_CHARACTER;
  }
}

// Starts recording characters in the temporary buffer.
static void clear_temporary_buffer(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  gumbo_string_buffer_clear(&tokenizer->_temporary_buffer);
}

// Appends a codepoint to the temporary buffer.
static void append_char_to_temporary_buffer (
  GumboParser* parser,
  int codepoint
) {
  gumbo_string_buffer_append_codepoint (
   codepoint,
   &parser->_tokenizer_state->_temporary_buffer
  );
}

static void append_string_to_temporary_buffer (
  GumboParser* parser,
  const GumboStringPiece* str
) {
  gumbo_string_buffer_append_string (
    str,
    &parser->_tokenizer_state->_temporary_buffer
  );
}


static bool temporary_buffer_is_empty(const GumboParser* parser) {
  return parser->_tokenizer_state->_temporary_buffer.length == 0;
}

static void doc_type_state_init(GumboParser* parser) {
  GumboTokenDocType* doc_type_state =
      &parser->_tokenizer_state->_doc_type_state;
  // We initialize these to NULL here so that we don't end up leaking memory if
  // we never see a doctype token. When we do see a doctype token, we reset
  // them to a freshly-allocated empty string so that we can present a uniform
  // interface to client code and not make them check for null. Ownership is
  // transferred to the doctype token when it's emitted.
  doc_type_state->name = NULL;
  doc_type_state->public_identifier = NULL;
  doc_type_state->system_identifier = NULL;
  doc_type_state->force_quirks = false;
  doc_type_state->has_public_identifier = false;
  doc_type_state->has_system_identifier = false;
}

// Sets the token original_text and position to the current iterator position.
// This is necessary because [CDATA[ sections may include text that is ignored
// by the tokenizer.
static void reset_token_start_point(GumboTokenizerState* tokenizer) {
  tokenizer->_token_start = utf8iterator_get_char_pointer(&tokenizer->_input);
  utf8iterator_get_position(&tokenizer->_input, &tokenizer->_token_start_pos);
}

// Sets the tag buffer original text and start point to the current iterator
// position. This is necessary because attribute names & values may have
// whitespace preceeding them, and so we can't assume that the actual token
// starting point was the end of the last tag buffer usage.
static void reset_tag_buffer_start_point(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;

  utf8iterator_get_position(&tokenizer->_input, &tag_state->_start_pos);
  tag_state->_original_text = utf8iterator_get_char_pointer(&tokenizer->_input);
}

// Moves the temporary buffer contents over to the specified output string,
// and clears the temporary buffer.
static void finish_temporary_buffer(GumboParser* parser, const char** output) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  *output = gumbo_string_buffer_to_string(&tokenizer->_temporary_buffer);
  clear_temporary_buffer(parser);
}

// Advances the iterator past the end of the token, and then fills in the
// relevant position fields. It's assumed that after every emit, the tokenizer
// will immediately return (letting the tree-construction stage read the filled
// in Token). Thus, it's safe to advance the input stream here, since it will
// bypass the advance at the bottom of the state machine loop.
//
// Since this advances the iterator and resets the current input, make sure to
// call it after you've recorded any other data you need for the token.
static void finish_token(GumboParser* parser, GumboToken* token) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  if (!tokenizer->_reconsume_current_input) {
    utf8iterator_next(&tokenizer->_input);
  }

  token->position = tokenizer->_token_start_pos;
  token->original_text.data = tokenizer->_token_start;
  reset_token_start_point(tokenizer);
  token->original_text.length =
      tokenizer->_token_start - token->original_text.data;
  if (token->original_text.length > 0 &&
      token->original_text.data[token->original_text.length - 1] == '\r') {
    // The UTF8 iterator will ignore carriage returns in the input stream, which
    // means that the next token may start one past a \r character. The pointer
    // arithmetic above results in that \r being appended to the original text
    // of the preceding token, so we have to adjust its length here to chop the
    // \r off.
    --token->original_text.length;
  }
}

// Records the doctype public ID, assumed to be in the temporary buffer.
// Convenience method that also sets has_public_identifier to true.
static void finish_doctype_public_id(GumboParser* parser) {
  GumboTokenDocType* doc_type_state =
      &parser->_tokenizer_state->_doc_type_state;
  gumbo_free((void*) doc_type_state->public_identifier);
  finish_temporary_buffer(parser, &doc_type_state->public_identifier);
  doc_type_state->has_public_identifier = true;
}

// Records the doctype system ID, assumed to be in the temporary buffer.
// Convenience method that also sets has_system_identifier to true.
static void finish_doctype_system_id(GumboParser* parser) {
  GumboTokenDocType* doc_type_state =
      &parser->_tokenizer_state->_doc_type_state;
  gumbo_free((void*) doc_type_state->system_identifier);
  finish_temporary_buffer(parser, &doc_type_state->system_identifier);
  doc_type_state->has_system_identifier = true;
}

// Writes a single specified character to the output token.
static StateResult emit_char(GumboParser* parser, int c, GumboToken* output) {
  output->type = get_char_token_type(parser->_tokenizer_state->_is_in_cdata, c);
  output->v.character = c;
  finish_token(parser, output);
  return EMIT_TOKEN;
}

// Writes a replacement character token and records a parse error.
// Always returns EMIT_TOKEN, per gumbo_lex return value.
static StateResult emit_replacement_char(
    GumboParser* parser, GumboToken* output) {
  // In all cases, this is because of a null byte in the input stream.
  tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
  emit_char(parser, kUtf8ReplacementChar, output);
  return EMIT_TOKEN;
}

// Writes an EOF character token. Always returns EMIT_TOKEN.
static StateResult emit_eof(GumboParser* parser, GumboToken* output) {
  return emit_char(parser, -1, output);
}

// Writes out a doctype token, copying it from the tokenizer state.
static StateResult emit_doctype(GumboParser* parser, GumboToken* output) {
  output->type = GUMBO_TOKEN_DOCTYPE;
  output->v.doc_type = parser->_tokenizer_state->_doc_type_state;
  finish_token(parser, output);
  doc_type_state_init(parser);
  return EMIT_TOKEN;
}

// Debug-only function that explicitly sets the attribute vector data to NULL so
// it can be asserted on tag creation, verifying that there are no memory leaks.
static void mark_tag_state_as_empty(GumboTagState* tag_state) {
  UNUSED_IF_NDEBUG(tag_state);
  tag_state->_name = NULL;
#ifndef NDEBUG
  tag_state->_attributes = kGumboEmptyVector;
#endif
}

// Writes out the current tag as a start or end tag token.
// Always returns EMIT_TOKEN.
static StateResult emit_current_tag(GumboParser* parser, GumboToken* output) {
  GumboTagState* tag_state = &parser->_tokenizer_state->_tag_state;
  if (tag_state->_is_start_tag) {
    output->type = GUMBO_TOKEN_START_TAG;
    output->v.start_tag.tag = tag_state->_tag;
    output->v.start_tag.name = tag_state->_name;
    output->v.start_tag.attributes = tag_state->_attributes;
    output->v.start_tag.is_self_closing = tag_state->_is_self_closing;
    tag_state->_last_start_tag = tag_state->_tag;
    mark_tag_state_as_empty(tag_state);
    gumbo_debug(
        "Emitted start tag %s.\n", gumbo_normalized_tagname(tag_state->_tag));
  } else {
    output->type = GUMBO_TOKEN_END_TAG;
    output->v.end_tag.tag = tag_state->_tag;
    output->v.end_tag.name = tag_state->_name;
    if (tag_state->_is_self_closing)
      tokenizer_add_token_parse_error(parser, GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS);
    if (tag_state->_attributes.length > 0)
      tokenizer_add_token_parse_error(parser, GUMBO_ERR_END_TAG_WITH_ATTRIBUTES);
    // In end tags, ownership of the attributes vector is not transferred to the
    // token, but it's still initialized as normal, so it must be manually
    // deallocated. There may also be attributes to destroy, in certain broken
    // cases like </div</th> (the "th" is an attribute there).
    for (unsigned int i = 0; i < tag_state->_attributes.length; ++i) {
      gumbo_destroy_attribute(tag_state->_attributes.data[i]);
    }
    gumbo_free(tag_state->_attributes.data);
    mark_tag_state_as_empty(tag_state);
    gumbo_debug(
        "Emitted end tag %s.\n", gumbo_normalized_tagname(tag_state->_tag));
  }
  gumbo_string_buffer_destroy(&tag_state->_buffer);
  finish_token(parser, output);
  gumbo_debug (
    "Original text = %.*s.\n",
    (int) output->original_text.length,
    output->original_text.data
  );
  assert(output->original_text.length >= 2);
  assert(output->original_text.data[0] == '<');
  assert(output->original_text.data[output->original_text.length - 1] == '>');
  return EMIT_TOKEN;
}

// In some states, we speculatively start a tag, but don't know whether it'll be
// emitted as tag token or as a series of character tokens until we finish it.
// We need to abandon the tag we'd started & free its memory in that case to
// avoid a memory leak.
static void abandon_current_tag(GumboParser* parser) {
  GumboTagState* tag_state = &parser->_tokenizer_state->_tag_state;
  for (unsigned int i = 0; i < tag_state->_attributes.length; ++i) {
    gumbo_destroy_attribute(tag_state->_attributes.data[i]);
  }
  gumbo_free(tag_state->_attributes.data);
  mark_tag_state_as_empty(tag_state);
  gumbo_string_buffer_destroy(&tag_state->_buffer);
  gumbo_debug("Abandoning current tag.\n");
}

// Emits a comment token. Comments use the temporary buffer to accumulate their
// data, and then it's copied over and released to the 'text' field of the
// GumboToken union. Always returns EMIT_TOKEN.
static StateResult emit_comment(GumboParser* parser, GumboToken* output) {
  output->type = GUMBO_TOKEN_COMMENT;
  finish_temporary_buffer(parser, &output->v.text);
  finish_token(parser, output);
  return EMIT_TOKEN;
}

static void set_mark(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  utf8iterator_mark(&tokenizer->_input);
}

// Checks to see we should be emitting characters from the mark, and fills the
// output token with the next output character if so.
// Returns EMIT_TOKEN if a character has been emitted and the tokenizer should
// immediately return, CONTINUE if we should resume normal operation.
static StateResult maybe_emit_from_mark (
    GumboParser* parser,
    GumboToken* output
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  const char* pos = tokenizer->_resume_pos;

  if (!pos)
    return CONTINUE;
  if (utf8iterator_get_char_pointer(&tokenizer->_input) >= pos) {
    tokenizer->_resume_pos = NULL;
    return CONTINUE;
  }

  // emit_char advances the input stream. _reconsume_current_input should
  // *never* be set when emitting from the mark since those characters have
  // already been advanced past.
  assert(!tokenizer->_reconsume_current_input);
  return emit_char(parser, utf8iterator_current(&tokenizer->_input), output);
}

// Sets up the tokenizer to begin emitting from the mark up to, but not
// including, the current code point. This resets the input iterator stream to
// the mark, sets up _resume_pos, and then emits the first character in it.
// Returns EMIT_TOKEN.
static StateResult emit_from_mark(GumboParser* parser, GumboToken* output) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  tokenizer->_resume_pos = utf8iterator_get_char_pointer(&tokenizer->_input);
  utf8iterator_reset(&tokenizer->_input);
  // Now that we have reset the input, we need to advance through it.
  tokenizer->_reconsume_current_input = false;
  StateResult result = maybe_emit_from_mark(parser, output);
  assert(result == EMIT_TOKEN);
  return result;
}

// Appends a codepoint to the current tag buffer. If
// reinitilize_position_on_first is set, this also initializes the tag buffer
// start point; the only time you would *not* want to pass true for this
// parameter is if you want the original_text to include character (like an
// opening quote) that doesn't appear in the value.
static void append_char_to_tag_buffer (
  GumboParser* parser,
  int codepoint,
  bool reinitilize_position_on_first
) {
  GumboStringBuffer* buffer = &parser->_tokenizer_state->_tag_state._buffer;
  if (buffer->length == 0 && reinitilize_position_on_first) {
    reset_tag_buffer_start_point(parser);
  }
  gumbo_string_buffer_append_codepoint(codepoint, buffer);
}

// Like above but append a string.
static void append_string_to_tag_buffer (
  GumboParser* parser,
  GumboStringPiece* str,
  bool reinitilize_position_on_first
) {
  GumboStringBuffer* buffer = &parser->_tokenizer_state->_tag_state._buffer;
  if (buffer->length == 0 && reinitilize_position_on_first) {
    reset_tag_buffer_start_point(parser);
  }
  gumbo_string_buffer_append_string(str, buffer);
}

// (Re-)initialize the tag buffer. This also resets the original_text pointer
// and _start_pos field to point to the current position.
static void initialize_tag_buffer(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;

  gumbo_string_buffer_init(&tag_state->_buffer);
  reset_tag_buffer_start_point(parser);
}

// https://html.spec.whatwg.org/multipage/parsing.html#charref-in-attribute
static bool character_reference_part_of_attribute(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  switch (tokenizer->_return_state) {
  case GUMBO_LEX_ATTR_VALUE_DOUBLE_QUOTED:
  case GUMBO_LEX_ATTR_VALUE_SINGLE_QUOTED:
  case GUMBO_LEX_ATTR_VALUE_UNQUOTED:
    return true;
  default:
    return false;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#flush-code-points-consumed-as-a-character-reference
// For each code point in the temporary buffer, add to the current attribute
// value if the character reference was consumed as part of an attribute or
// emit the code point as a character token.
static StateResult flush_code_points_consumed_as_character_reference (
  GumboParser* parser,
  GumboToken* output
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  if (character_reference_part_of_attribute(parser)) {
    const char *start = utf8iterator_get_mark_pointer(&tokenizer->_input);
    assert(start);
    GumboStringPiece str = {
      .data = start,
      .length = utf8iterator_get_char_pointer(&tokenizer->_input) - start,
    };
    bool unquoted = tokenizer->_return_state == GUMBO_LEX_ATTR_VALUE_UNQUOTED;
    append_string_to_tag_buffer(parser, &str, unquoted);
    return CONTINUE;
  }
  return emit_from_mark(parser, output);
}

// After a character reference has been successfully constructed, the standard
// says to set the temporary buffer equal to the empty string, append the code
// point(s) associated with the reference and flush code points consumed as a
// character reference.
// https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
// https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
// That doesn't work for us because we use the temporary buffer in lock step
// with the input for position and that would fail if we inserted a different
// number of code points. So duplicate a bit of the above logic.
static StateResult flush_char_ref (
  GumboParser* parser,
  int first,
  int second,
  GumboToken* output
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  if (character_reference_part_of_attribute(parser)) {
    bool unquoted = tokenizer->_return_state == GUMBO_LEX_ATTR_VALUE_UNQUOTED;
    append_char_to_tag_buffer(parser, first, unquoted);
    if (second != kGumboNoChar)
      append_char_to_tag_buffer(parser, second, unquoted);
    return CONTINUE;
  }
  tokenizer->_buffered_emit_char = second;
  return emit_char(parser, first, output);
}


// Initializes the tag_state to start a new tag, keeping track of the opening
// positions and original text. Takes a boolean indicating whether this is a
// start or end tag.
static void start_new_tag(GumboParser* parser, bool is_start_tag) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;
  int c = utf8iterator_current(&tokenizer->_input);
  assert(is_alpha(c));
  c = ensure_lowercase(c);
  assert(is_alpha(c));

  initialize_tag_buffer(parser);

  assert(tag_state->_name == NULL);
  assert(tag_state->_attributes.data == NULL);
  // Initial size chosen by statistical analysis of a corpus of 60k webpages.
  // 99.5% of elements have 0 attributes, 93% of the remainder have 1. These
  // numbers are a bit higher for more modern websites (eg. ~45% = 0, ~40% = 1
  // for the HTML5 Spec), but still have basically 99% of nodes with <= 2 attrs.
  gumbo_vector_init(1, &tag_state->_attributes);
  tag_state->_drop_next_attr_value = false;
  tag_state->_is_start_tag = is_start_tag;
  tag_state->_is_self_closing = false;
  gumbo_debug("Starting new tag.\n");
}

// Fills in the specified char* with the contents of the tag buffer.
static void copy_over_tag_buffer(GumboParser* parser, const char** output) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;
  *output = gumbo_string_buffer_to_string(&tag_state->_buffer);
}

// Fills in:
// * The original_text GumboStringPiece with the portion of the original
// buffer that corresponds to the tag buffer.
// * The start_pos GumboSourcePosition with the start position of the tag
// buffer.
// * The end_pos GumboSourcePosition with the current source position.
static void copy_over_original_tag_text (
  GumboParser* parser,
  GumboStringPiece* original_text,
  GumboSourcePosition* start_pos,
  GumboSourcePosition* end_pos
) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;

  original_text->data = tag_state->_original_text;
  original_text->length = utf8iterator_get_char_pointer(&tokenizer->_input) -
                          tag_state->_original_text;
  if (
    original_text->length
    && original_text->data[original_text->length - 1] == '\r'
  ) {
    // Since \r is skipped by the UTF-8 iterator, it can sometimes end up
    // appended to the end of original text even when it's really the first part
    // of the next character. If we detect this situation, shrink the length of
    // the original text by 1 to remove the carriage return.
    --original_text->length;
  }
  *start_pos = tag_state->_start_pos;
  utf8iterator_get_position(&tokenizer->_input, end_pos);
}

// Releases and then re-initializes the tag buffer.
static void reinitialize_tag_buffer(GumboParser* parser) {
  gumbo_free(parser->_tokenizer_state->_tag_state._buffer.data);
  initialize_tag_buffer(parser);
}

// Moves some data from the temporary buffer over the the tag-based fields in
// TagState.
static void finish_tag_name(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;

  const char *data = tag_state->_buffer.data;
  size_t length = tag_state->_buffer.length;
  tag_state->_tag = gumbo_tagn_enum(data, length);
  if (tag_state->_tag == GUMBO_TAG_UNKNOWN) {
    char *name = gumbo_alloc(length + 1);
    memcpy(name, data, length);
    name[length] = 0;
    tag_state->_name = name;
  }
  reinitialize_tag_buffer(parser);
}

// Adds an ERR_DUPLICATE_ATTR parse error to the parser's error struct.
static void add_duplicate_attr_error(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboError* error = gumbo_add_error(parser);
  if (!error) {
    return;
  }
  GumboTagState* tag_state = &parser->_tokenizer_state->_tag_state;
  error->type = GUMBO_ERR_DUPLICATE_ATTRIBUTE;
  error->position = tag_state->_start_pos;
  error->original_text.data = tag_state->_original_text;
  error->original_text.length =
    utf8iterator_get_char_pointer(&tokenizer->_input) - error->original_text.data;
  error->v.tokenizer.state = tokenizer->_state;
}

// Creates a new attribute in the current tag, copying the current tag buffer to
// the attribute's name. The attribute's value starts out as the empty string
// (following the "Boolean attributes" section of the spec) and is only
// overwritten on finish_attribute_value(). If the attribute has already been
// specified, the new attribute is dropped and a parse error is added
static void finish_attribute_name(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  GumboTagState* tag_state = &tokenizer->_tag_state;
  // May've been set by a previous attribute without a value; reset it here.
  tag_state->_drop_next_attr_value = false;
  assert(tag_state->_attributes.data);
  assert(tag_state->_attributes.capacity);

  GumboVector* /* GumboAttribute* */ attributes = &tag_state->_attributes;
  for (unsigned int i = 0; i < attributes->length; ++i) {
    GumboAttribute* attr = attributes->data[i];
    if (
      strlen(attr->name) == tag_state->_buffer.length
      && 0 == memcmp (
        attr->name,
        tag_state->_buffer.data,
        tag_state->_buffer.length
      )
    ) {
      // Identical attribute; bail.
      add_duplicate_attr_error(parser);
      reinitialize_tag_buffer(parser);
      tag_state->_drop_next_attr_value = true;
      return;
    }
  }

  GumboAttribute* attr = gumbo_alloc(sizeof(GumboAttribute));
  attr->attr_namespace = GUMBO_ATTR_NAMESPACE_NONE;
  copy_over_tag_buffer(parser, &attr->name);
  copy_over_original_tag_text (
    parser,
    &attr->original_name,
    &attr->name_start,
    &attr->name_end
  );
  attr->value = gumbo_strdup("");
  copy_over_original_tag_text (
    parser,
    &attr->original_value,
    &attr->name_start,
    &attr->name_end
  );
  gumbo_vector_add(attr, attributes);
  reinitialize_tag_buffer(parser);
}

// Finishes an attribute value. This sets the value of the most recently added
// attribute to the current contents of the tag buffer.
static void finish_attribute_value(GumboParser* parser) {
  GumboTagState* tag_state = &parser->_tokenizer_state->_tag_state;
  if (tag_state->_drop_next_attr_value) {
    // Duplicate attribute name detected in an earlier state, so we have to
    // ignore the value.
    tag_state->_drop_next_attr_value = false;
    reinitialize_tag_buffer(parser);
    return;
  }

  GumboAttribute* attr =
      tag_state->_attributes.data[tag_state->_attributes.length - 1];
  gumbo_free((void*) attr->value);
  copy_over_tag_buffer(parser, &attr->value);
  copy_over_original_tag_text(
      parser, &attr->original_value, &attr->value_start, &attr->value_end);
  reinitialize_tag_buffer(parser);
}

// Returns true if the current end tag matches the last start tag emitted.
static bool is_appropriate_end_tag(GumboParser* parser) {
  GumboTagState* tag_state = &parser->_tokenizer_state->_tag_state;
  assert(!tag_state->_is_start_tag);
  return tag_state->_last_start_tag != GUMBO_TAG_LAST &&
         tag_state->_last_start_tag == gumbo_tagn_enum(tag_state->_buffer.data,
                                           tag_state->_buffer.length);
}

void gumbo_tokenizer_state_init (
  GumboParser* parser,
  const char* text,
  size_t text_length
) {
  GumboTokenizerState* tokenizer = gumbo_alloc(sizeof(GumboTokenizerState));
  parser->_tokenizer_state = tokenizer;
  gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
  tokenizer->_return_state = GUMBO_LEX_DATA;
  tokenizer->_character_reference_code = 0;
  tokenizer->_reconsume_current_input = false;
  tokenizer->_is_adjusted_current_node_foreign = false;
  tokenizer->_is_in_cdata = false;
  tokenizer->_tag_state._last_start_tag = GUMBO_TAG_LAST;
  tokenizer->_tag_state._name = NULL;

  tokenizer->_buffered_emit_char = kGumboNoChar;
  gumbo_string_buffer_init(&tokenizer->_temporary_buffer);
  tokenizer->_resume_pos = NULL;

  mark_tag_state_as_empty(&tokenizer->_tag_state);

  tokenizer->_token_start = text;
  utf8iterator_init(parser, text, text_length, &tokenizer->_input);
  utf8iterator_get_position(&tokenizer->_input, &tokenizer->_token_start_pos);
  doc_type_state_init(parser);
}

void gumbo_tokenizer_state_destroy(GumboParser* parser) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  assert(tokenizer->_doc_type_state.name == NULL);
  assert(tokenizer->_doc_type_state.public_identifier == NULL);
  assert(tokenizer->_doc_type_state.system_identifier == NULL);
  gumbo_string_buffer_destroy(&tokenizer->_temporary_buffer);
  assert(tokenizer->_tag_state._name == NULL);
  assert(tokenizer->_tag_state._attributes.data == NULL);
  gumbo_free(tokenizer);
}

void gumbo_tokenizer_set_state(GumboParser* parser, GumboTokenizerEnum state) {
  parser->_tokenizer_state->_state = state;
}

void gumbo_tokenizer_set_is_adjusted_current_node_foreign (
  GumboParser* parser,
  bool is_foreign
) {
  if (is_foreign != parser->_tokenizer_state->_is_adjusted_current_node_foreign) {
    gumbo_debug (
      "Toggling is_current_node_foreign to %s.\n",
      is_foreign ? "true" : "false"
    );
  }
  parser->_tokenizer_state->_is_adjusted_current_node_foreign = is_foreign;
}

static void reconsume_in_state(GumboParser* parser, GumboTokenizerEnum state) {
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;
  tokenizer->_reconsume_current_input = true;
  tokenizer->_state = state;
}

// https://html.spec.whatwg.org/multipage/parsing.html#data-state
static StateResult handle_data_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '&':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_CHARACTER_REFERENCE);
      set_mark(parser);
      tokenizer->_return_state = GUMBO_LEX_DATA;
      return CONTINUE;
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_TAG_OPEN);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      return emit_char(parser, c, output);
    case -1:
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
static StateResult handle_rcdata_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '&':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_CHARACTER_REFERENCE);
      set_mark(parser);
      tokenizer->_return_state = GUMBO_LEX_RCDATA;
      return CONTINUE;
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_RCDATA_LT);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state
static StateResult handle_rawtext_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_RAWTEXT_LT);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
static StateResult handle_script_data_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_LT);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#plaintext-state
static StateResult handle_plaintext_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#tag-open-state
static StateResult handle_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '!':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_MARKUP_DECLARATION_OPEN);
      clear_temporary_buffer(parser);
      return CONTINUE;
    case '/':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_END_TAG_OPEN);
      return CONTINUE;
    case '?':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME);
      clear_temporary_buffer(parser);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_COMMENT);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_BEFORE_TAG_NAME);
      // Switch to data to emit EOF.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_from_mark(parser, output);
    default:
      if (is_alpha(c)) {
        reconsume_in_state(parser, GUMBO_LEX_TAG_NAME);
        start_new_tag(parser, true);
        return CONTINUE;
      }
      tokenizer_add_parse_error(parser, GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#end-tag-open-state
static StateResult handle_end_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_END_TAG_NAME);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_BEFORE_TAG_NAME);
      // Similar to the tag open state except we need to emit '<' and '/'
      // before the EOF.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_from_mark(parser, output);
    default:
      if (is_alpha(c)) {
        reconsume_in_state(parser, GUMBO_LEX_TAG_NAME);
        start_new_tag(parser, false);
      } else {
        tokenizer_add_parse_error(parser, GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME);
        reconsume_in_state(parser, GUMBO_LEX_BOGUS_COMMENT);
        clear_temporary_buffer(parser);
      }
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#tag-name-state
static StateResult handle_tag_name_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    case '/':
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    case '>':
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_tag_buffer(parser, kUtf8ReplacementChar, true);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
static StateResult handle_rcdata_lt_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '/') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_RCDATA_END_TAG_OPEN);
    return CONTINUE;
  } else {
    reconsume_in_state(parser, GUMBO_LEX_RCDATA);
    return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
static StateResult handle_rcdata_end_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    reconsume_in_state(parser, GUMBO_LEX_RCDATA_END_TAG_NAME);
    start_new_tag(parser, false);
    return CONTINUE;
  }
  reconsume_in_state(parser, GUMBO_LEX_RCDATA);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
static StateResult handle_rcdata_end_tag_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  UNUSED_IF_NDEBUG(tokenizer);
  if (is_alpha(c)) {
    append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
    return CONTINUE;
  }
  switch (c) {
  case '\t':
  case '\n':
  case '\f':
  case ' ':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    }
    break;
  case '/':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    }
    break;
  case '>':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    }
    break;
  }
  abandon_current_tag(parser);
  reconsume_in_state(parser, GUMBO_LEX_RCDATA);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
static StateResult handle_rawtext_lt_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '/') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_RAWTEXT_END_TAG_OPEN);
    return CONTINUE;
  } else {
    reconsume_in_state(parser, GUMBO_LEX_RAWTEXT);
    return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
static StateResult handle_rawtext_end_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    reconsume_in_state(parser, GUMBO_LEX_RAWTEXT_END_TAG_NAME);
    start_new_tag(parser, false);
    return CONTINUE;
  } else {
    reconsume_in_state(parser, GUMBO_LEX_RAWTEXT);
    return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
static StateResult handle_rawtext_end_tag_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
    return CONTINUE;
  }
  switch (c) {
  case '\t':
  case '\n':
  case '\f':
  case ' ':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    }
    break;
  case '/':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    }
    break;
  case '>':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    }
    break;
  }
  abandon_current_tag(parser);
  reconsume_in_state(parser, GUMBO_LEX_RAWTEXT);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
static StateResult handle_script_data_lt_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '/') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_END_TAG_OPEN);
    return CONTINUE;
  }
  if (c == '!') {
    // This is the only place we don't reconsume the input before emitting the
    // temporary buffer. Since the current position is stored and the current
    // character is not emitted, we need to advance the input and then
    // reconsume.
    utf8iterator_next(&tokenizer->_input);
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_START);
    return emit_from_mark(parser, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
static StateResult handle_script_data_end_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_END_TAG_NAME);
    start_new_tag(parser, false);
    return CONTINUE;
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
static StateResult handle_script_data_end_tag_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
    return CONTINUE;
  }
  switch (c) {
  case '\t':
  case '\n':
  case '\f':
  case ' ':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    }
    break;
  case '/':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    }
    break;
  case '>':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    }
    break;
  }
  abandon_current_tag(parser);
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-state
static StateResult handle_script_data_escaped_start_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '-') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_START_DASH);
    return emit_char(parser, c, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
static StateResult handle_script_data_escaped_start_dash_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '-') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH_DASH);
    return emit_char(parser, c, output);
  } else {
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
static StateResult handle_script_data_escaped_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH);
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_LT);
      clear_temporary_buffer(parser);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
static StateResult handle_script_data_escaped_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH_DASH);
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_LT);
      clear_temporary_buffer(parser);
      set_mark(parser);
      return CONTINUE;
    case '\0':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
static StateResult handle_script_data_escaped_dash_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_LT);
      clear_temporary_buffer(parser);
      set_mark(parser);
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA);
      return emit_char(parser, c, output);
    case '\0':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
static StateResult handle_script_data_escaped_lt_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  assert(temporary_buffer_is_empty(parser));
  if (c == '/') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_OPEN);
    return CONTINUE;
  }
  if (is_alpha(c)) {
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_START);
    return emit_from_mark(parser, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
static StateResult handle_script_data_escaped_end_tag_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_NAME);
    start_new_tag(parser, false);
    return CONTINUE;
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
static StateResult handle_script_data_escaped_end_tag_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (is_alpha(c)) {
    append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
    return CONTINUE;
  }
  switch (c) {
  case '\t':
  case '\n':
  case '\f':
  case ' ':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    }
    break;
  case '/':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    }
    break;
  case '>':
    if (is_appropriate_end_tag(parser)) {
      finish_tag_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    }
    break;
  }
  abandon_current_tag(parser);
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
  return emit_from_mark(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
static StateResult handle_script_data_double_escaped_start_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
    case '/':
    case '>':
      gumbo_tokenizer_set_state (
        parser,
        gumbo_string_equals (
          &kScriptTag,
          (GumboStringPiece*) &tokenizer->_temporary_buffer
        )
        ? GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED
        : GUMBO_LEX_SCRIPT_DATA_ESCAPED
      );
      return emit_char(parser, c, output);
  }
  if (is_alpha(c)) {
    append_char_to_temporary_buffer(parser, ensure_lowercase(c));
    return emit_char(parser, c, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_ESCAPED);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
static StateResult handle_script_data_double_escaped_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH);
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_LT);
      return emit_char(parser, c, output);
    case '\0':
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
static StateResult handle_script_data_double_escaped_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH);
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_LT);
      return emit_char(parser, c, output);
    case '\0':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
static StateResult handle_script_data_double_escaped_dash_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      return emit_char(parser, c, output);
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_LT);
      return emit_char(parser, c, output);
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA);
      return emit_char(parser, c, output);
    case '\0':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
      return emit_replacement_char(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT);
      return emit_eof(parser, output);
    default:
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
      return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
static StateResult handle_script_data_double_escaped_lt_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (c == '/') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_END);
    clear_temporary_buffer(parser);
    return emit_char(parser, c, output);
  } else {
    reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-state
static StateResult handle_script_data_double_escaped_end_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
    case '/':
    case '>':
      gumbo_tokenizer_set_state(
          parser, gumbo_string_equals(&kScriptTag,
                      (GumboStringPiece*) &tokenizer->_temporary_buffer)
                      ? GUMBO_LEX_SCRIPT_DATA_ESCAPED
                      : GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
      return emit_char(parser, c, output);
  }
  if (is_alpha(c)) {
    append_char_to_temporary_buffer(parser, ensure_lowercase(c));
    return emit_char(parser, c, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-name-state
static StateResult handle_before_attr_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '/':
    case '>':
    case -1:
      reconsume_in_state(parser, GUMBO_LEX_AFTER_ATTR_NAME);
      return CONTINUE;
    case '=':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_ATTR_NAME);
      append_char_to_tag_buffer(parser, c, true);
      return CONTINUE;
    default:
      reconsume_in_state(parser, GUMBO_LEX_ATTR_NAME);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
static StateResult handle_attr_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
    case '/':
    case '>':
    case -1:
      finish_attribute_name(parser);
      reconsume_in_state(parser, GUMBO_LEX_AFTER_ATTR_NAME);
      return CONTINUE;
    case '=':
      finish_attribute_name(parser);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_VALUE);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_tag_buffer(parser, kUtf8ReplacementChar, true);
      return CONTINUE;
    case '"':
    case '\'':
    case '<':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME);
    // Fall through.
    default:
      append_char_to_tag_buffer(parser, ensure_lowercase(c), true);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-name-state
static StateResult handle_after_attr_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '/':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    case '=':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_VALUE);
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      reconsume_in_state(parser, GUMBO_LEX_ATTR_NAME);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-value-state
static StateResult handle_before_attr_value_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '"':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_ATTR_VALUE_DOUBLE_QUOTED);
      reset_tag_buffer_start_point(parser);
      return CONTINUE;
    case '\'':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_ATTR_VALUE_SINGLE_QUOTED);
      reset_tag_buffer_start_point(parser);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_ATTRIBUTE_VALUE);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
  }
  reconsume_in_state(parser, GUMBO_LEX_ATTR_VALUE_UNQUOTED);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-double-quoted-state
static StateResult handle_attr_value_double_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '"':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_ATTR_VALUE_QUOTED);
      return CONTINUE;
    case '&':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_CHARACTER_REFERENCE);
      set_mark(parser);
      tokenizer->_return_state = GUMBO_LEX_ATTR_VALUE_DOUBLE_QUOTED;
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_tag_buffer(parser, kUtf8ReplacementChar, false);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      append_char_to_tag_buffer(parser, c, false);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-single-quoted-state
static StateResult handle_attr_value_single_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\'':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_ATTR_VALUE_QUOTED);
      return CONTINUE;
    case '&':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_CHARACTER_REFERENCE);
      set_mark(parser);
      tokenizer->_return_state = GUMBO_LEX_ATTR_VALUE_SINGLE_QUOTED;
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_tag_buffer(parser, kUtf8ReplacementChar, false);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      append_char_to_tag_buffer(parser, c, false);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-unquoted-state
static StateResult handle_attr_value_unquoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      finish_attribute_value(parser);
      return CONTINUE;
    case '&':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_CHARACTER_REFERENCE);
      set_mark(parser);
      tokenizer->_return_state = GUMBO_LEX_ATTR_VALUE_UNQUOTED;
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      finish_attribute_value(parser);
      return emit_current_tag(parser, output);
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_tag_buffer(parser, kUtf8ReplacementChar, true);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    case '"':
    case '\'':
    case '<':
    case '=':
    case '`':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE);
    // Fall through.
    default:
      append_char_to_tag_buffer(parser, c, true);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-value-quoted-state
static StateResult handle_after_attr_value_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  finish_attribute_value(parser);
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
    case '/':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_SELF_CLOSING_START_TAG);
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_current_tag(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES);
      reconsume_in_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#self-closing-start-tag-state
static StateResult handle_self_closing_start_tag_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_tag_state._is_self_closing = true;
      return emit_current_tag(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_TAG);
      abandon_current_tag(parser);
      return emit_eof(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG);
      reconsume_in_state(parser, GUMBO_LEX_BEFORE_ATTR_NAME);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#bogus-comment-state
static StateResult handle_bogus_comment_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
  case '>':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
    return emit_comment(parser, output);
  case -1:
    // We need to emit the comment and then the EOF, so reconsume in data
    // state.
    reconsume_in_state(parser, GUMBO_LEX_DATA);
    return emit_comment(parser, output);
  case '\0':
    tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
    append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
    return CONTINUE;
  default:
    append_char_to_temporary_buffer(parser, c);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
static StateResult handle_markup_declaration_open_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int UNUSED_ARG(c),
  GumboToken* UNUSED_ARG(output)
) {
  if (
    utf8iterator_maybe_consume_match (
      &tokenizer->_input,
      "--",
      sizeof("--") - 1,
      /* case sensitive */ true
    )
  ) {
    reconsume_in_state(parser, GUMBO_LEX_COMMENT_START);
    return CONTINUE;
  }
  if (
    utf8iterator_maybe_consume_match (
      &tokenizer->_input,
      "DOCTYPE",
      sizeof("DOCTYPE") - 1,
      /* case sensitive */ false
    )
  ) {
    reconsume_in_state(parser, GUMBO_LEX_DOCTYPE);
    // If we get here, we know we'll eventually emit a doctype token, so now is
    // the time to initialize the doctype strings. (Not in doctype_state_init,
    // since then they'll leak if ownership never gets transferred to the
    // doctype token.
    tokenizer->_doc_type_state.name = gumbo_strdup("");
    tokenizer->_doc_type_state.public_identifier = gumbo_strdup("");
    tokenizer->_doc_type_state.system_identifier = gumbo_strdup("");
    return CONTINUE;
  }
  if (
    utf8iterator_maybe_consume_match (
      &tokenizer->_input,
      "[CDATA[", sizeof("[CDATA[") - 1,
      /* case sensitive */ true
    )
  ) {
    if (tokenizer->_is_adjusted_current_node_foreign) {
      reconsume_in_state(parser, GUMBO_LEX_CDATA_SECTION);
      tokenizer->_is_in_cdata = true;
      // Start the token after the <![CDATA[.
      reset_token_start_point(tokenizer);
    } else {
      tokenizer_add_token_parse_error(parser, GUMBO_ERR_CDATA_IN_HTML_CONTENT);
      clear_temporary_buffer(parser);
      append_string_to_temporary_buffer (
        parser,
        &(const GumboStringPiece) { .data = "[CDATA[", .length = 7 }
      );
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_COMMENT);
    }
    return CONTINUE;
  }
  tokenizer_add_parse_error(parser, GUMBO_ERR_INCORRECTLY_OPENED_COMMENT);
  reconsume_in_state(parser, GUMBO_LEX_BOGUS_COMMENT);
  clear_temporary_buffer(parser);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
static StateResult handle_comment_start_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_START_DASH);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    default:
      reconsume_in_state(parser, GUMBO_LEX_COMMENT);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
static StateResult handle_comment_start_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_END);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_COMMENT);
      // Switch to data to emit the EOF next.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    default:
      reconsume_in_state(parser, GUMBO_LEX_COMMENT);
      append_char_to_temporary_buffer(parser, '-');
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-state
static StateResult handle_comment_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '<':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_LT);
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_END_DASH);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_COMMENT);
      // Switch to data to emit the EOF token next.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    default:
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-state
static StateResult handle_comment_lt_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '!':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_LT_BANG);
    append_char_to_temporary_buffer(parser, c);
    return CONTINUE;
  case '<':
    append_char_to_temporary_buffer(parser, c);
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_COMMENT);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
static StateResult handle_comment_lt_bang_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '-':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_LT_BANG_DASH);
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_COMMENT);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
static StateResult handle_comment_lt_bang_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '-':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_LT_BANG_DASH_DASH);
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_COMMENT_END_DASH);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
static StateResult handle_comment_lt_bang_dash_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '>':
  case -1:
    reconsume_in_state(parser, GUMBO_LEX_COMMENT_END);
    return CONTINUE;
  default:
    tokenizer_add_parse_error(parser, GUMBO_ERR_NESTED_COMMENT);
    reconsume_in_state(parser, GUMBO_LEX_COMMENT_END);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
static StateResult handle_comment_end_dash_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '-':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_END);
    return CONTINUE;
  case -1:
    tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_COMMENT);
    // Switch to data to emit EOF next.
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
    return emit_comment(parser, output);
  default:
    reconsume_in_state(parser, GUMBO_LEX_COMMENT);
    append_char_to_temporary_buffer(parser, '-');
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-end-state
static StateResult handle_comment_end_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    case '!':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_END_BANG);
      return CONTINUE;
    case '-':
      append_char_to_temporary_buffer(parser, '-');
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_COMMENT);
      // Switch to data to emit EOF next.
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    default:
      reconsume_in_state(parser, GUMBO_LEX_COMMENT);
      append_char_to_temporary_buffer(parser, '-');
      append_char_to_temporary_buffer(parser, '-');
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#comment-end-bang-state
static StateResult handle_comment_end_bang_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
    case '-':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_COMMENT_END_DASH);
      append_char_to_temporary_buffer(parser, '-');
      append_char_to_temporary_buffer(parser, '-');
      append_char_to_temporary_buffer(parser, '!');
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_INCORRECTLY_CLOSED_COMMENT);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_COMMENT);
      // Switch to data to emit EOF next.
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_comment(parser, output);
    default:
      reconsume_in_state(parser, GUMBO_LEX_COMMENT);
      append_char_to_temporary_buffer(parser, '-');
      append_char_to_temporary_buffer(parser, '-');
      append_char_to_temporary_buffer(parser, '!');
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
static StateResult handle_doctype_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  assert(temporary_buffer_is_empty(parser));
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_DOCTYPE_NAME);
      return CONTINUE;
    case '>':
      reconsume_in_state(parser, GUMBO_LEX_BEFORE_DOCTYPE_NAME);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      // Switch to data to emit EOF next.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME);
      reconsume_in_state(parser, GUMBO_LEX_BEFORE_DOCTYPE_NAME);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-name-state
static StateResult handle_before_doctype_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DOCTYPE_NAME);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_DOCTYPE_NAME);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      // Switch to data to emit EOF next.
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    default:
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DOCTYPE_NAME);
      append_char_to_temporary_buffer(parser, ensure_lowercase(c));
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
static StateResult handle_doctype_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_DOCTYPE_NAME);
      gumbo_free((void*) tokenizer->_doc_type_state.name);
      finish_temporary_buffer(parser, &tokenizer->_doc_type_state.name);
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      gumbo_free((void*) tokenizer->_doc_type_state.name);
      finish_temporary_buffer(parser, &tokenizer->_doc_type_state.name);
      return emit_doctype(parser, output);
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      gumbo_free((void*) tokenizer->_doc_type_state.name);
      finish_temporary_buffer(parser, &tokenizer->_doc_type_state.name);
      return emit_doctype(parser, output);
    default:
      append_char_to_temporary_buffer(parser, ensure_lowercase(c));
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
static StateResult handle_after_doctype_name_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      if (utf8iterator_maybe_consume_match(
              &tokenizer->_input, "PUBLIC", sizeof("PUBLIC") - 1, false)) {
        reconsume_in_state(parser, GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_KEYWORD);
      } else if (utf8iterator_maybe_consume_match(&tokenizer->_input, "SYSTEM",
                     sizeof("SYSTEM") - 1, false)) {
        reconsume_in_state(parser, GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_KEYWORD);
      } else {
        tokenizer_add_parse_error(
            parser, GUMBO_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME);
        reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
        tokenizer->_doc_type_state.force_quirks = true;
      }
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-keyword-state
static StateResult handle_after_doctype_public_keyword_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_DOCTYPE_PUBLIC_ID);
      return CONTINUE;
    case '"':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD);
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_PUBLIC_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD);
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_PUBLIC_ID_SINGLE_QUOTED);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-public-identifier-state
static StateResult handle_before_doctype_public_id_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '"':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_PUBLIC_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_PUBLIC_ID_SINGLE_QUOTED);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
static StateResult handle_doctype_public_id_double_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '"':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_ID);
      finish_doctype_public_id(parser);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_public_id(parser);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_public_id(parser);
      return emit_doctype(parser, output);
    default:
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(single-quoted)-state
static StateResult handle_doctype_public_id_single_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\'':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_ID);
      finish_doctype_public_id(parser);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_public_id(parser);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_public_id(parser);
      return emit_doctype(parser, output);
    default:
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
static StateResult handle_after_doctype_public_id_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_BETWEEN_DOCTYPE_PUBLIC_SYSTEM_ID);
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    case '"':
      tokenizer_add_parse_error (
        parser,
        GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS
      );
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      tokenizer_add_parse_error (
        parser,
        GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS
      );
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#between-doctype-public-and-system-identifiers-state
static StateResult handle_between_doctype_public_system_id_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    case '"':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED);
      return CONTINUE;
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-keyword-state
static StateResult handle_after_doctype_system_keyword_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_BEFORE_DOCTYPE_SYSTEM_ID);
      return CONTINUE;
    case '"':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD);
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD);
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-system-identifier-state
static StateResult handle_before_doctype_system_id_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '"':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED);
      return CONTINUE;
    case '\'':
      assert(temporary_buffer_is_empty(parser));
      gumbo_tokenizer_set_state(
          parser, GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      tokenizer->_doc_type_state.force_quirks = true;
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
static StateResult handle_doctype_system_id_double_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '"':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_ID);
      finish_doctype_system_id(parser);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_system_id(parser);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_system_id(parser);
      return emit_doctype(parser, output);
    default:
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(single-quoted)-state
static StateResult handle_doctype_system_id_single_quoted_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\'':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_ID);
      finish_doctype_system_id(parser);
      return CONTINUE;
    case '\0':
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
      append_char_to_temporary_buffer(parser, kUtf8ReplacementChar);
      return CONTINUE;
    case '>':
      tokenizer_add_parse_error(parser, GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER);
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_system_id(parser);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      finish_doctype_system_id(parser);
      return emit_doctype(parser, output);
    default:
      append_char_to_temporary_buffer(parser, c);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
static StateResult handle_after_doctype_system_id_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
    case '\t':
    case '\n':
    case '\f':
    case ' ':
      return CONTINUE;
    case '>':
      gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
      return emit_doctype(parser, output);
    case -1:
      tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_DOCTYPE);
      reconsume_in_state(parser, GUMBO_LEX_DATA);
      tokenizer->_doc_type_state.force_quirks = true;
      return emit_doctype(parser, output);
    default:
      tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER);
      reconsume_in_state(parser, GUMBO_LEX_BOGUS_DOCTYPE);
      return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
static StateResult handle_bogus_doctype_state (
  GumboParser* parser,
  GumboTokenizerState* UNUSED_ARG(tokenizer),
  int c,
  GumboToken* output
) {
  switch (c) {
  case '>':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_DATA);
    return emit_doctype(parser, output);
  case '\0':
    tokenizer_add_parse_error(parser, GUMBO_ERR_UNEXPECTED_NULL_CHARACTER);
    return CONTINUE;
  case -1:
    reconsume_in_state(parser, GUMBO_LEX_DATA);
    return emit_doctype(parser, output);
  default:
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
static StateResult handle_cdata_section_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
  case ']':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_CDATA_SECTION_BRACKET);
    set_mark(parser);
    return CONTINUE;
  case -1:
    tokenizer_add_parse_error(parser, GUMBO_ERR_EOF_IN_CDATA);
    return emit_eof(parser, output);
  default:
    return emit_char(parser, c, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
static StateResult handle_cdata_section_bracket_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
  case ']':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_CDATA_SECTION_END);
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_CDATA_SECTION);
    // Emit the ].
    return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
static StateResult handle_cdata_section_end_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  switch (c) {
  case ']':
  {
    // XXX: This is terrible. We want to emit a ] corresponding to the first
    // of the three in a row we've seen. So let's emit one token from the
    // temporary buffer (which will rewind 3 characters, emit the ] and
    // advance one). Next, let's clear the temporary buffer which will set the
    // mark to the middle of the three brackets. Finally, let's move to the
    // appropriate state.
    StateResult result = emit_from_mark(parser, output);
    tokenizer->_resume_pos = NULL;
    set_mark(parser);
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_CDATA_SECTION);
    return result;
  }
  case '>':
    // We're done with CDATA so move past the >, reset the token start point
    // to point after the >, and then reconsume in the data state.
    utf8iterator_next(&tokenizer->_input);
    reset_token_start_point(tokenizer);
    reconsume_in_state(parser, GUMBO_LEX_DATA);
    tokenizer->_is_in_cdata = false;
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_CDATA_SECTION);
    return emit_from_mark(parser, output);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
static StateResult handle_character_reference_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isalnum(c)) {
    reconsume_in_state(parser, GUMBO_LEX_NAMED_CHARACTER_REFERENCE);
    return CONTINUE;
  }
  if (c == '#') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE);
    return CONTINUE;
  }
  reconsume_in_state(parser, tokenizer->_return_state);
  return flush_code_points_consumed_as_character_reference(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
static StateResult handle_named_character_reference_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  const char *cur = utf8iterator_get_char_pointer(&tokenizer->_input);
  const char *end = utf8iterator_get_end_pointer(&tokenizer->_input);
  int code_point[2];
  size_t size = match_named_char_ref(cur, end - cur, code_point);

  if (size > 0) {
    utf8iterator_maybe_consume_match(&tokenizer->_input, cur, size, true);
    int next = utf8iterator_current(&tokenizer->_input);
    reconsume_in_state(parser, tokenizer->_return_state);
    if (character_reference_part_of_attribute(parser)
        && cur[size-1] != ';'
        && (next == '=' || gumbo_ascii_isalnum(next))) {
      GumboStringPiece str = { .data = cur, .length = size };
      append_string_to_temporary_buffer(parser, &str);
      return flush_code_points_consumed_as_character_reference(parser, output);
    }
    if (cur[size-1] != ';')
      tokenizer_add_char_ref_error(parser, GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE, -1);
    reconsume_in_state(parser, tokenizer->_return_state);
    return flush_char_ref(parser, code_point[0], code_point[1], output);
  }
  reconsume_in_state(parser, GUMBO_LEX_AMBIGUOUS_AMPERSAND);
  return flush_code_points_consumed_as_character_reference(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
static StateResult handle_ambiguous_ampersand_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isalnum(c)) {
    if (character_reference_part_of_attribute(parser)) {
      append_char_to_tag_buffer(parser, c, true);
      return CONTINUE;
    }
    return emit_char(parser, c, output);
  }
  if (c == ';') {
      tokenizer_add_char_ref_error(parser, GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE, -1);
    // fall through
  }
  reconsume_in_state(parser, tokenizer->_return_state);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
static StateResult handle_numeric_character_reference_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  tokenizer->_character_reference_code = 0;
  switch (c) {
  case 'x':
  case 'X':
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE_START);
    return CONTINUE;
  default:
    reconsume_in_state(parser, GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE_START);
    return CONTINUE;
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#hexademical-character-reference-start-state
static StateResult handle_hexadecimal_character_reference_start_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isxdigit(c)) {
    reconsume_in_state(parser, GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE);
    return CONTINUE;
  }
  tokenizer_add_char_ref_error (
    parser,
    GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE,
    -1
  );
  reconsume_in_state(parser, tokenizer->_return_state);
  return flush_code_points_consumed_as_character_reference(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
static StateResult handle_decimal_character_reference_start_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isdigit(c)) {
    reconsume_in_state(parser, GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE);
    return CONTINUE;
  }
  tokenizer_add_char_ref_error (
    parser,
    GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE,
    -1
  );
  reconsume_in_state(parser, tokenizer->_return_state);
  return flush_code_points_consumed_as_character_reference(parser, output);
}

// https://html.spec.whatwg.org/multipage/parsing.html#hexademical-character-reference-state
static StateResult handle_hexadecimal_character_reference_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isdigit(c)) {
    tokenizer->_character_reference_code =
      tokenizer->_character_reference_code * 16 + (c - 0x0030);
    if (tokenizer->_character_reference_code > kUtf8MaxChar)
      tokenizer->_character_reference_code = kUtf8MaxChar+1;
    return CONTINUE;
  }
  if (gumbo_ascii_isupper_xdigit(c)) {
    tokenizer->_character_reference_code =
      tokenizer->_character_reference_code * 16 + (c - 0x0037);
    if (tokenizer->_character_reference_code > kUtf8MaxChar)
      tokenizer->_character_reference_code = kUtf8MaxChar+1;
    return CONTINUE;
  }
  if (gumbo_ascii_islower_xdigit(c)) {
    tokenizer->_character_reference_code =
      tokenizer->_character_reference_code * 16 + (c - 0x0057);
    if (tokenizer->_character_reference_code > kUtf8MaxChar)
      tokenizer->_character_reference_code = kUtf8MaxChar+1;
    return CONTINUE;
  }
  if (c == ';') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END);
    return CONTINUE;
  }
  tokenizer_add_char_ref_error(
    parser,
    GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE,
    tokenizer->_character_reference_code
  );
  reconsume_in_state(parser, GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
static StateResult handle_decimal_character_reference_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  if (gumbo_ascii_isdigit(c)) {
    tokenizer->_character_reference_code =
      tokenizer->_character_reference_code * 10 + (c - 0x0030);
    if (tokenizer->_character_reference_code > kUtf8MaxChar)
      tokenizer->_character_reference_code = kUtf8MaxChar+1;
    return CONTINUE;
  }
  if (c == ';') {
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END);
    return CONTINUE;
  }
  tokenizer_add_char_ref_error(
    parser,
    GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE,
    tokenizer->_character_reference_code
  );
  reconsume_in_state(parser, GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END);
  return CONTINUE;
}

// https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
static StateResult handle_numeric_character_reference_end_state (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
) {
  c = tokenizer->_character_reference_code;
  if (c == 0) {
    tokenizer_add_char_ref_error(
      parser,
      GUMBO_ERR_NULL_CHARACTER_REFERENCE,
      c
    );
    c = kUtf8ReplacementChar;
  } else if (c > kUtf8MaxChar) {
    tokenizer_add_char_ref_error(
      parser,
      GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE,
      c
    );
    c = kUtf8ReplacementChar;
  } else if (utf8_is_surrogate(c)) {
    tokenizer_add_char_ref_error(
      parser,
      GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE,
      c
    );
    c = kUtf8ReplacementChar;
  } else if (utf8_is_noncharacter(c)) {
    tokenizer_add_char_ref_error(
      parser,
      GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE,
      c
    );
  } else if (c == 0x0D || (utf8_is_control(c) && !gumbo_ascii_isspace(c))) {
    tokenizer_add_char_ref_error(
      parser,
      GUMBO_ERR_CONTROL_CHARACTER_REFERENCE,
      c
    );
    switch (c) {
    case 0x80: c = 0x20AC; break;
    case 0x82: c = 0x201A; break;
    case 0x83: c = 0x0192; break;
    case 0x84: c = 0x201E; break;
    case 0x85: c = 0x2026; break;
    case 0x86: c = 0x2020; break;
    case 0x87: c = 0x2021; break;
    case 0x88: c = 0x02C6; break;
    case 0x89: c = 0x2030; break;
    case 0x8A: c = 0x0160; break;
    case 0x8B: c = 0x2039; break;
    case 0x8C: c = 0x0152; break;
    case 0x8E: c = 0x017D; break;
    case 0x91: c = 0x2018; break;
    case 0x92: c = 0x2019; break;
    case 0x93: c = 0x201C; break;
    case 0x94: c = 0x201D; break;
    case 0x95: c = 0x2022; break;
    case 0x96: c = 0x2013; break;
    case 0x97: c = 0x2014; break;
    case 0x98: c = 0x02DC; break;
    case 0x99: c = 0x2122; break;
    case 0x9A: c = 0x0161; break;
    case 0x9B: c = 0x203A; break;
    case 0x9C: c = 0x0153; break;
    case 0x9E: c = 0x017E; break;
    case 0x9F: c = 0x0178; break;
    }
  }
  reconsume_in_state(parser, tokenizer->_return_state);
  return flush_char_ref(parser, c, kGumboNoChar, output);
}

typedef StateResult (*GumboLexerStateFunction) (
  GumboParser* parser,
  GumboTokenizerState* tokenizer,
  int c,
  GumboToken* output
);

static GumboLexerStateFunction dispatch_table[] = {
  [GUMBO_LEX_DATA] = handle_data_state,
  [GUMBO_LEX_RCDATA] = handle_rcdata_state,
  [GUMBO_LEX_RAWTEXT] = handle_rawtext_state,
  [GUMBO_LEX_SCRIPT_DATA] = handle_script_data_state,
  [GUMBO_LEX_PLAINTEXT] = handle_plaintext_state,
  [GUMBO_LEX_TAG_OPEN] = handle_tag_open_state,
  [GUMBO_LEX_END_TAG_OPEN] = handle_end_tag_open_state,
  [GUMBO_LEX_TAG_NAME] = handle_tag_name_state,
  [GUMBO_LEX_RCDATA_LT] = handle_rcdata_lt_state,
  [GUMBO_LEX_RCDATA_END_TAG_OPEN] = handle_rcdata_end_tag_open_state,
  [GUMBO_LEX_RCDATA_END_TAG_NAME] = handle_rcdata_end_tag_name_state,
  [GUMBO_LEX_RAWTEXT_LT] = handle_rawtext_lt_state,
  [GUMBO_LEX_RAWTEXT_END_TAG_OPEN] = handle_rawtext_end_tag_open_state,
  [GUMBO_LEX_RAWTEXT_END_TAG_NAME] = handle_rawtext_end_tag_name_state,
  [GUMBO_LEX_SCRIPT_DATA_LT] = handle_script_data_lt_state,
  [GUMBO_LEX_SCRIPT_DATA_END_TAG_OPEN] = handle_script_data_end_tag_open_state,
  [GUMBO_LEX_SCRIPT_DATA_END_TAG_NAME] = handle_script_data_end_tag_name_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_START] = handle_script_data_escaped_start_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_START_DASH] = handle_script_data_escaped_start_dash_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED] = handle_script_data_escaped_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH] = handle_script_data_escaped_dash_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH_DASH] = handle_script_data_escaped_dash_dash_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_LT] = handle_script_data_escaped_lt_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_OPEN] = handle_script_data_escaped_end_tag_open_state,
  [GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_NAME] = handle_script_data_escaped_end_tag_name_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_START] = handle_script_data_double_escaped_start_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED] = handle_script_data_double_escaped_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH] = handle_script_data_double_escaped_dash_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH] = handle_script_data_double_escaped_dash_dash_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_LT] = handle_script_data_double_escaped_lt_state,
  [GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_END] = handle_script_data_double_escaped_end_state,
  [GUMBO_LEX_BEFORE_ATTR_NAME] = handle_before_attr_name_state,
  [GUMBO_LEX_ATTR_NAME] = handle_attr_name_state,
  [GUMBO_LEX_AFTER_ATTR_NAME] = handle_after_attr_name_state,
  [GUMBO_LEX_BEFORE_ATTR_VALUE] = handle_before_attr_value_state,
  [GUMBO_LEX_ATTR_VALUE_DOUBLE_QUOTED] = handle_attr_value_double_quoted_state,
  [GUMBO_LEX_ATTR_VALUE_SINGLE_QUOTED] = handle_attr_value_single_quoted_state,
  [GUMBO_LEX_ATTR_VALUE_UNQUOTED] = handle_attr_value_unquoted_state,
  [GUMBO_LEX_AFTER_ATTR_VALUE_QUOTED] = handle_after_attr_value_quoted_state,
  [GUMBO_LEX_SELF_CLOSING_START_TAG] = handle_self_closing_start_tag_state,
  [GUMBO_LEX_BOGUS_COMMENT] = handle_bogus_comment_state,
  [GUMBO_LEX_MARKUP_DECLARATION_OPEN] = handle_markup_declaration_open_state,
  [GUMBO_LEX_COMMENT_START] = handle_comment_start_state,
  [GUMBO_LEX_COMMENT_START_DASH] = handle_comment_start_dash_state,
  [GUMBO_LEX_COMMENT] = handle_comment_state,
  [GUMBO_LEX_COMMENT_LT] = handle_comment_lt_state,
  [GUMBO_LEX_COMMENT_LT_BANG] = handle_comment_lt_bang_state,
  [GUMBO_LEX_COMMENT_LT_BANG_DASH] = handle_comment_lt_bang_dash_state,
  [GUMBO_LEX_COMMENT_LT_BANG_DASH_DASH] = handle_comment_lt_bang_dash_dash_state,
  [GUMBO_LEX_COMMENT_END_DASH] = handle_comment_end_dash_state,
  [GUMBO_LEX_COMMENT_END] = handle_comment_end_state,
  [GUMBO_LEX_COMMENT_END_BANG] = handle_comment_end_bang_state,
  [GUMBO_LEX_DOCTYPE] = handle_doctype_state,
  [GUMBO_LEX_BEFORE_DOCTYPE_NAME] = handle_before_doctype_name_state,
  [GUMBO_LEX_DOCTYPE_NAME] = handle_doctype_name_state,
  [GUMBO_LEX_AFTER_DOCTYPE_NAME] = handle_after_doctype_name_state,
  [GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_KEYWORD] = handle_after_doctype_public_keyword_state,
  [GUMBO_LEX_BEFORE_DOCTYPE_PUBLIC_ID] = handle_before_doctype_public_id_state,
  [GUMBO_LEX_DOCTYPE_PUBLIC_ID_DOUBLE_QUOTED] = handle_doctype_public_id_double_quoted_state,
  [GUMBO_LEX_DOCTYPE_PUBLIC_ID_SINGLE_QUOTED] = handle_doctype_public_id_single_quoted_state,
  [GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_ID] = handle_after_doctype_public_id_state,
  [GUMBO_LEX_BETWEEN_DOCTYPE_PUBLIC_SYSTEM_ID] = handle_between_doctype_public_system_id_state,
  [GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_KEYWORD] = handle_after_doctype_system_keyword_state,
  [GUMBO_LEX_BEFORE_DOCTYPE_SYSTEM_ID] = handle_before_doctype_system_id_state,
  [GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED] = handle_doctype_system_id_double_quoted_state,
  [GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED] = handle_doctype_system_id_single_quoted_state,
  [GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_ID] = handle_after_doctype_system_id_state,
  [GUMBO_LEX_BOGUS_DOCTYPE] = handle_bogus_doctype_state,
  [GUMBO_LEX_CDATA_SECTION] = handle_cdata_section_state,
  [GUMBO_LEX_CDATA_SECTION_BRACKET] = handle_cdata_section_bracket_state,
  [GUMBO_LEX_CDATA_SECTION_END] = handle_cdata_section_end_state,
  [GUMBO_LEX_CHARACTER_REFERENCE] = handle_character_reference_state,
  [GUMBO_LEX_NAMED_CHARACTER_REFERENCE] = handle_named_character_reference_state,
  [GUMBO_LEX_AMBIGUOUS_AMPERSAND] = handle_ambiguous_ampersand_state,
  [GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE] = handle_numeric_character_reference_state,
  [GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE_START] = handle_hexadecimal_character_reference_start_state,
  [GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE_START] = handle_decimal_character_reference_start_state,
  [GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE] = handle_hexadecimal_character_reference_state,
  [GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE] = handle_decimal_character_reference_state,
  [GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END] = handle_numeric_character_reference_end_state,
};

void gumbo_lex(GumboParser* parser, GumboToken* output) {
  // Because of the spec requirements that...
  //
  // 1. Tokens be handled immediately by the parser upon emission.
  // 2. Some states (eg. CDATA, or various error conditions) require the
  // emission of multiple tokens in the same states.
  // 3. The tokenizer often has to reconsume the same character in a different
  // state.
  //
  // ...all state must be held in the GumboTokenizer struct instead of in local
  // variables in this function. That allows us to return from this method with
  // a token, and then immediately jump back to the same state with the same
  // input if we need to return a different token. The various emit_* functions
  // are responsible for changing state (eg. flushing the chardata buffer,
  // reading the next input character) to avoid an infinite loop.
  GumboTokenizerState* tokenizer = parser->_tokenizer_state;

  if (tokenizer->_buffered_emit_char != kGumboNoChar) {
    tokenizer->_reconsume_current_input = true;
    emit_char(parser, tokenizer->_buffered_emit_char, output);
    // And now that we've avoided advancing the input, make sure we set
    // _reconsume_current_input back to false to make sure the *next* character
    // isn't consumed twice.
    tokenizer->_reconsume_current_input = false;
    tokenizer->_buffered_emit_char = kGumboNoChar;
    return;
  }

  if (maybe_emit_from_mark(parser, output) == EMIT_TOKEN) {
    return;
  }

  while (1) {
    assert(!tokenizer->_resume_pos);
    assert(tokenizer->_buffered_emit_char == kGumboNoChar);
    int c = utf8iterator_current(&tokenizer->_input);
    GumboTokenizerEnum state = tokenizer->_state;
    gumbo_debug("Lexing character '%c' (%d) in state %u.\n", c, c, state);
    StateResult result = dispatch_table[state](parser, tokenizer, c, output);
    // We need to clear reconsume_current_input before returning to prevent
    // certain infinite loop states.
    bool should_advance = !tokenizer->_reconsume_current_input;
    tokenizer->_reconsume_current_input = false;

    if (result == EMIT_TOKEN)
      return;

    if (should_advance) {
      utf8iterator_next(&tokenizer->_input);
    }
  }
}

void gumbo_token_destroy(GumboToken* token) {
  if (!token) return;

  switch (token->type) {
    case GUMBO_TOKEN_DOCTYPE:
      gumbo_free((void*) token->v.doc_type.name);
      gumbo_free((void*) token->v.doc_type.public_identifier);
      gumbo_free((void*) token->v.doc_type.system_identifier);
      return;
    case GUMBO_TOKEN_START_TAG:
      for (unsigned int i = 0; i < token->v.start_tag.attributes.length; ++i) {
        GumboAttribute* attr = token->v.start_tag.attributes.data[i];
        if (attr) {
          // May have been nulled out if this token was merged with another.
          gumbo_destroy_attribute(attr);
        }
      }
      gumbo_free((void*) token->v.start_tag.attributes.data);
      if (token->v.start_tag.tag == GUMBO_TAG_UNKNOWN) {
        gumbo_free(token->v.start_tag.name);
        token->v.start_tag.name = NULL;
      }
      return;
    case GUMBO_TOKEN_END_TAG:
      if (token->v.end_tag.tag == GUMBO_TAG_UNKNOWN) {
        gumbo_free(token->v.end_tag.name);
        token->v.end_tag.name = NULL;
      }
      break;
    case GUMBO_TOKEN_COMMENT:
      gumbo_free((void*) token->v.text);
      return;
    default:
      return;
  }
}
