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

#include <assert.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include "ascii.h"
#include "error.h"
#include "gumbo.h"
#include "macros.h"
#include "parser.h"
#include "string_buffer.h"
#include "util.h"
#include "vector.h"

// Prints a formatted message to a StringBuffer. This automatically resizes the
// StringBuffer as necessary to fit the message. Returns the number of bytes
// written.
static int PRINTF(2) print_message (
  GumboStringBuffer* output,
  const char* format,
  ...
) {
  va_list args;
  int remaining_capacity = output->capacity - output->length;
  va_start(args, format);
  int bytes_written = vsnprintf (
    output->data + output->length,
    remaining_capacity,
    format,
    args
  );
  va_end(args);
#if _MSC_VER && _MSC_VER < 1900
  if (bytes_written == -1) {
    // vsnprintf returns -1 on older MSVC++ if there's not enough capacity,
    // instead of returning the number of bytes that would've been written had
    // there been enough. In this case, we'll double the buffer size and hope
    // it fits when we retry (letting it fail and returning 0 if it doesn't),
    // since there's no way to smartly resize the buffer.
    gumbo_string_buffer_reserve(output->capacity * 2, output);
    va_start(args, format);
    int result = vsnprintf (
      output->data + output->length,
      remaining_capacity,
      format,
      args
    );
    va_end(args);
    return result == -1 ? 0 : result;
  }
#else
  // -1 in standard C99 indicates an encoding error. Return 0 and do nothing.
  if (bytes_written == -1) {
    return 0;
  }
#endif

  if (bytes_written >= remaining_capacity) {
    gumbo_string_buffer_reserve(output->capacity + bytes_written, output);
    remaining_capacity = output->capacity - output->length;
    va_start(args, format);
    bytes_written = vsnprintf (
      output->data + output->length,
      remaining_capacity,
      format,
      args
    );
    va_end(args);
  }
  output->length += bytes_written;
  return bytes_written;
}

static void print_tag_stack (
  const GumboParserError* error,
  GumboStringBuffer* output
) {
  print_message(output, "  Currently open tags: ");
  for (unsigned int i = 0; i < error->tag_stack.length; ++i) {
    if (i) {
      print_message(output, ", ");
    }
    GumboTag tag = (GumboTag) error->tag_stack.data[i];
    print_message(output, "%s", gumbo_normalized_tagname(tag));
  }
  gumbo_string_buffer_append_codepoint('.', output);
}

static void handle_tokenizer_error (
  const GumboError* error,
  GumboStringBuffer* output
) {
  switch (error->type) {
  case GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT:
      print_message(output, "Empty comment abruptly closed by '%s', use '-->'.",
                    error->v.tokenizer.state == GUMBO_LEX_COMMENT_START? ">" : "->");
    break;
  case GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER:
    print_message (
      output,
      "DOCTYPE public identifier missing closing %s.",
      error->v.tokenizer.state == GUMBO_LEX_DOCTYPE_PUBLIC_ID_DOUBLE_QUOTED?
        "quotation mark (\")" : "apostrophe (')"
    );
    break;
  case GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER:
    print_message (
      output,
      "DOCTYPE system identifier missing closing %s.",
      error->v.tokenizer.state == GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED?
        "quotation mark (\")" : "apostrophe (')"
    );
    break;
  case GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE:
    print_message (
      output,
      "Numeric character reference '%.*s' does not contain any %sdigits.",
      (int)error->original_text.length, error->original_text.data,
      error->v.tokenizer.state == GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE_START? "hexadecimal " : ""
    );
    break;
  case GUMBO_ERR_CDATA_IN_HTML_CONTENT:
    print_message(output, "CDATA section outside foreign (SVG or MathML) content.");
    break;
  case GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE:
    print_message (
      output,
      "Numeric character reference '%.*s' references a code point that is outside the valid Unicode range.",
      (int)error->original_text.length, error->original_text.data
    );
    break;
  case GUMBO_ERR_CONTROL_CHARACTER_IN_INPUT_STREAM:
    print_message (
      output,
      "Input contains prohibited control code point U+%04X.",
      error->v.tokenizer.codepoint
    );
    break;
  case GUMBO_ERR_CONTROL_CHARACTER_REFERENCE:
    print_message (
      output,
      "Numeric character reference '%.*s' references prohibited control code point U+%04X.",
      (int)error->original_text.length, error->original_text.data,
      error->v.tokenizer.codepoint
    );
    break;
  case GUMBO_ERR_END_TAG_WITH_ATTRIBUTES:
    print_message(output, "End tag contains attributes.");
    break;
  case GUMBO_ERR_DUPLICATE_ATTRIBUTE:
    print_message(output, "Tag contains multiple attributes with the same name.");
    break;
  case GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS:
    print_message(output, "End tag ends with '/>', use '>'.");
    break;
  case GUMBO_ERR_EOF_BEFORE_TAG_NAME:
    print_message(output, "End of input where a tag name is expected.");
    break;
  case GUMBO_ERR_EOF_IN_CDATA:
    print_message(output, "End of input in CDATA section.");
    break;
  case GUMBO_ERR_EOF_IN_COMMENT:
    print_message(output, "End of input in comment.");
    break;
  case GUMBO_ERR_EOF_IN_DOCTYPE:
    print_message(output, "End of input in DOCTYPE.");
    break;
  case GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT:
    print_message(output, "End of input in text that resembles an HTML comment inside script element content.");
    break;
  case GUMBO_ERR_EOF_IN_TAG:
    print_message(output, "End of input in tag.");
    break;
  case GUMBO_ERR_INCORRECTLY_CLOSED_COMMENT:
    print_message(output, "Comment closed incorrectly by '--!>', use '-->'.");
    break;
  case GUMBO_ERR_INCORRECTLY_OPENED_COMMENT:
    print_message(output, "Comment, DOCTYPE, or CDATA opened incorrectly, use '<!--', '<!DOCTYPE', or '<![CDATA['.");
    break;
  case GUMBO_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME:
    print_message(output, "Invalid character sequence after DOCTYPE name, expected 'PUBLIC', 'SYSTEM', or '>'.");
    break;
  case GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME:
    if (gumbo_ascii_isascii(error->v.tokenizer.codepoint)
        && !gumbo_ascii_iscntrl(error->v.tokenizer.codepoint))
      print_message(output, "Invalid first character of tag name '%c'.", error->v.tokenizer.codepoint);
    else
      print_message(output, "Invalid first code point of tag name U+%04X.", error->v.tokenizer.codepoint);
    break;
  case GUMBO_ERR_MISSING_ATTRIBUTE_VALUE:
    print_message(output, "Missing attribute value.");
    break;
  case GUMBO_ERR_MISSING_DOCTYPE_NAME:
    print_message(output, "Missing DOCTYPE name.");
    break;
  case GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER:
    print_message(output, "Missing DOCTYPE public identifier.");
    break;
  case GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER:
    print_message(output, "Missing DOCTYPE system identifier.");
    break;
  case GUMBO_ERR_MISSING_END_TAG_NAME:
    print_message(output, "Missing end tag name.");
    break;
  case GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER:
    print_message(output, "Missing quote before DOCTYPE public identifier.");
    break;
  case GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER:
    print_message(output, "Missing quote before DOCTYPE system identifier.");
    break;
  case GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE:
    print_message(output, "Missing semicolon after character reference '%.*s'.",
                  (int)error->original_text.length, error->original_text.data);
    break;
  case GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD:
    print_message(output, "Missing whitespace after 'PUBLIC' keyword.");
    break;
  case GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD:
    print_message(output, "Missing whitespace after 'SYSTEM' keyword.");
    break;
  case GUMBO_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME:
    print_message(output, "Missing whitespace between 'DOCTYPE' keyword and DOCTYPE name.");
    break;
  case GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES:
    print_message(output, "Missing whitespace between attributes.");
    break;
  case GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS:
    print_message(output, "Missing whitespace between DOCTYPE public and system identifiers.");
    break;
  case GUMBO_ERR_NESTED_COMMENT:
    print_message(output, "Nested comment.");
    break;
  case GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE:
    print_message (
      output,
      "Numeric character reference '%.*s' references noncharacter U+%04X.",
      (int)error->original_text.length, error->original_text.data,
      error->v.tokenizer.codepoint
    );
    break;
  case GUMBO_ERR_NONCHARACTER_IN_INPUT_STREAM:
    print_message(output, "Input contains noncharacter U+%04X.", error->v.tokenizer.codepoint);
    break;
  case GUMBO_ERR_NON_VOID_HTML_ELEMENT_START_TAG_WITH_TRAILING_SOLIDUS:
    print_message(output, "Start tag of nonvoid HTML element ends with '/>', use '>'.");
    break;
  case GUMBO_ERR_NULL_CHARACTER_REFERENCE:
    print_message(output, "Numeric character reference '%.*s' references U+0000.",
                  (int)error->original_text.length, error->original_text.data);
    break;
  case GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE:
    print_message (
      output,
      "Numeric character reference '%.*s' references surrogate U+%4X.",
      (int)error->original_text.length, error->original_text.data,
      error->v.tokenizer.codepoint
    );
    break;
  case GUMBO_ERR_SURROGATE_IN_INPUT_STREAM:
    print_message(output, "Input contains surrogate U+%04X.", error->v.tokenizer.codepoint);
    break;
  case GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER:
    print_message(output, "Unexpected character after DOCTYPE system identifier.");
    break;
  case GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME:
    print_message(output, "Unexpected character (%c) in attribute name.", error->v.tokenizer.codepoint);
    break;
  case GUMBO_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE:
    print_message(output, "Unexpected character (%c) in unquoted attribute value.", error->v.tokenizer.codepoint);
    break;
  case GUMBO_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME:
    print_message(output, "Unexpected '=' before an attribute name.");
    break;
  case GUMBO_ERR_UNEXPECTED_NULL_CHARACTER:
    print_message(output, "Input contains unexpected U+0000.");
    break;
  case GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME:
    print_message(output, "Unexpected '?' where start tag name is expected.");
    break;
  case GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG:
    print_message(output, "Unexpected '/' in tag.");
    break;
  case GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE:
    print_message(output, "Unknown named character reference '%.*s'.",
                  (int)error->original_text.length, error->original_text.data);
    break;
  case GUMBO_ERR_UTF8_INVALID:
    print_message(output, "Invalid UTF8 encoding.");
    break;
  case GUMBO_ERR_UTF8_TRUNCATED:
    print_message(output, "UTF8 character truncated.");
    break;
  case GUMBO_ERR_PARSER:
    assert(0 && "Unreachable.");
  }
}
static void handle_parser_error (
  const GumboParserError* error,
  GumboStringBuffer* output
) {
  if (
    error->parser_state == GUMBO_INSERTION_MODE_INITIAL
    && error->input_type != GUMBO_TOKEN_DOCTYPE
  ) {
    print_message (
      output,
      "Expected a doctype token"
    );
    return;
  }

  switch (error->input_type) {
    case GUMBO_TOKEN_DOCTYPE:
      print_message(output, "This is not a legal doctype");
      return;
    case GUMBO_TOKEN_COMMENT:
      // Should never happen; comments are always legal.
      assert(0);
      // But just in case...
      print_message(output, "Comments aren't legal here");
      return;
    case GUMBO_TOKEN_CDATA:
    case GUMBO_TOKEN_WHITESPACE:
    case GUMBO_TOKEN_CHARACTER:
      print_message(output, "Character tokens aren't legal here");
      return;
    case GUMBO_TOKEN_NULL:
      print_message(output, "Null bytes are not allowed in HTML5");
      return;
    case GUMBO_TOKEN_EOF:
      if (error->parser_state == GUMBO_INSERTION_MODE_INITIAL) {
        print_message(output, "You must provide a doctype");
      } else {
        print_message(output, "Premature end of file");
        print_tag_stack(error, output);
      }
      return;
    case GUMBO_TOKEN_START_TAG:
    case GUMBO_TOKEN_END_TAG:
      print_message(output, "That tag isn't allowed here");
      print_tag_stack(error, output);
      // TODO(jdtang): Give more specific messaging.
      return;
  }
}

// Finds the preceding newline in an original source buffer from a given byte
// location. Returns a character pointer to the character after that, or a
// pointer to the beginning of the string if this is the first line.
static const char* find_prev_newline (
  const char* source_text,
  size_t source_length,
  const char* error_location
) {
  const char* source_end = source_text + source_length;
  assert(error_location >= source_text);
  assert(error_location <= source_end);
  const char* c = error_location;
  if (c != source_text && (error_location == source_end || *c == '\n'))
    --c;
  while (c != source_text && *c != '\n')
    --c;
  return c == source_text ? c : c + 1;
}

// Finds the next newline in the original source buffer from a given byte
// location. Returns a character pointer to that newline, or a pointer to
// source_text + source_length if this is the last line.
static const char* find_next_newline(
  const char* source_text,
  size_t source_length,
  const char* error_location
) {
  const char* source_end = source_text + source_length;
  assert(error_location >= source_text);
  assert(error_location <= source_end);
  const char* c = error_location;
  while (c != source_end && *c != '\n')
    ++c;
  return c;
}

GumboError* gumbo_add_error(GumboParser* parser) {
  parser->_output->document_error = true;

  int max_errors = parser->_options->max_errors;
  if (max_errors >= 0 && parser->_output->errors.length >= (unsigned int) max_errors) {
    return NULL;
  }
  GumboError* error = gumbo_alloc(sizeof(GumboError));
  gumbo_vector_add(error, &parser->_output->errors);
  return error;
}

GumboSourcePosition gumbo_error_position(const GumboError* error) {
  return error->position;
}

const char* gumbo_error_code(const GumboError* error) {
  switch (error->type) {
  // Defined tokenizer errors.
  case GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT:
    return "abrupt-closing-of-empty-comment";
  case GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER:
    return "abrupt-doctype-public-identifier";
  case GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER:
    return "abrupt-doctype-system-identifier";
  case GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE:
    return "absence-of-digits-in-numeric-character-reference";
  case GUMBO_ERR_CDATA_IN_HTML_CONTENT:
    return "cdata-in-html-content";
  case GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE:
    return "character-reference-outside-unicode-range";
  case GUMBO_ERR_CONTROL_CHARACTER_IN_INPUT_STREAM:
    return "control-character-in-input-stream";
  case GUMBO_ERR_CONTROL_CHARACTER_REFERENCE:
    return "control-character-reference";
  case GUMBO_ERR_END_TAG_WITH_ATTRIBUTES:
    return "end-tag-with-attributes";
  case GUMBO_ERR_DUPLICATE_ATTRIBUTE:
    return "duplicate-attribute";
  case GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS:
    return "end-tag-with-trailing-solidus";
  case GUMBO_ERR_EOF_BEFORE_TAG_NAME:
    return "eof-before-tag-name";
  case GUMBO_ERR_EOF_IN_CDATA:
    return "eof-in-cdata";
  case GUMBO_ERR_EOF_IN_COMMENT:
    return "eof-in-comment";
  case GUMBO_ERR_EOF_IN_DOCTYPE:
    return "eof-in-doctype";
  case GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT:
    return "eof-in-script-html-comment-like-text";
  case GUMBO_ERR_EOF_IN_TAG:
    return "eof-in-tag";
  case GUMBO_ERR_INCORRECTLY_CLOSED_COMMENT:
    return "incorrectly-closed-comment";
  case GUMBO_ERR_INCORRECTLY_OPENED_COMMENT:
    return "incorrectly-opened-comment";
  case GUMBO_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME:
    return "invalid-character-sequence-after-doctype-name";
  case GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME:
    return "invalid-first-character-of-tag-name";
  case GUMBO_ERR_MISSING_ATTRIBUTE_VALUE:
    return "missing-attribute-value";
  case GUMBO_ERR_MISSING_DOCTYPE_NAME:
    return "missing-doctype-name";
  case GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER:
    return "missing-doctype-public-identifier";
  case GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER:
    return "missing-doctype-system-identifier";
  case GUMBO_ERR_MISSING_END_TAG_NAME:
    return "missing-end-tag-name";
  case GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER:
    return "missing-quote-before-doctype-public-identifier";
  case GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER:
    return "missing-quote-before-doctype-system-identifier";
  case GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE:
    return "missing-semicolon-after-character-reference";
  case GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD:
    return "missing-whitespace-after-doctype-public-keyword";
  case GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD:
    return "missing-whitespace-after-doctype-system-keyword";
  case GUMBO_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME:
    return "missing-whitespace-before-doctype-name";
  case GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES:
    return "missing-whitespace-between-attributes";
  case GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS:
    return "missing-whitespace-between-doctype-public-and-system-identifiers";
  case GUMBO_ERR_NESTED_COMMENT:
    return "nested-comment";
  case GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE:
    return "noncharacter-character-reference";
  case GUMBO_ERR_NONCHARACTER_IN_INPUT_STREAM:
    return "noncharacter-in-input-stream";
  case GUMBO_ERR_NON_VOID_HTML_ELEMENT_START_TAG_WITH_TRAILING_SOLIDUS:
    return "non-void-html-element-start-tag-with-trailing-solidus";
  case GUMBO_ERR_NULL_CHARACTER_REFERENCE:
    return "null-character-reference";
  case GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE:
    return "surrogate-character-reference";
  case GUMBO_ERR_SURROGATE_IN_INPUT_STREAM:
    return "surrogate-in-input-stream";
  case GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER:
    return "unexpected-character-after-doctype-system-identifier";
  case GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME:
    return "unexpected-character-in-attribute-name";
  case GUMBO_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE:
    return "unexpected-character-in-unquoted-attribute-value";
  case GUMBO_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME:
    return "unexpected-equals-sign-before-attribute-name";
  case GUMBO_ERR_UNEXPECTED_NULL_CHARACTER:
    return "unexpected-null-character";
  case GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME:
    return "unexpected-question-mark-instead-of-tag-name";
  case GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG:
    return "unexpected-solidus-in-tag";
  case GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE:
    return "unknown-named-character-reference";

  // Encoding errors.
  case GUMBO_ERR_UTF8_INVALID:
    return "utf8-invalid";
  case GUMBO_ERR_UTF8_TRUNCATED:
    return "utf8-truncated";

  // Generic parser error.
  case GUMBO_ERR_PARSER:
    return "generic-parser";
  }
  // Silence warning about control reaching end of non-void function.
  // All errors _should_ be handled in the switch statement.
  return "generic-parser";
}

static void error_to_string (
  const GumboError* error,
  GumboStringBuffer* output
) {
  if (error->type < GUMBO_ERR_PARSER)
    handle_tokenizer_error(error, output);
  else
    handle_parser_error(&error->v.parser, output);
}

size_t gumbo_error_to_string(const GumboError* error, char** output) {
  GumboStringBuffer sb;
  gumbo_string_buffer_init(&sb);
  error_to_string(error, &sb);
  *output = sb.data;
  return sb.length;
}

void caret_diagnostic_to_string (
  const GumboError* error,
  const char* source_text,
  size_t source_length,
  GumboStringBuffer* output
) {
  error_to_string(error, output);

  const char* error_text = error->original_text.data;
  const char* line_start = find_prev_newline(source_text, source_length, error_text);
  const char* line_end = find_next_newline(source_text, source_length, error_text);
  GumboStringPiece original_line;
  original_line.data = line_start;
  original_line.length = line_end - line_start;

  gumbo_string_buffer_append_codepoint('\n', output);
  gumbo_string_buffer_append_string(&original_line, output);
  gumbo_string_buffer_append_codepoint('\n', output);
  gumbo_string_buffer_reserve(output->length + error->position.column, output);
  if (error->position.column >= 2) {
    size_t num_spaces = error->position.column - 1;
    memset(output->data + output->length, ' ', num_spaces);
    output->length += num_spaces;
  }
  gumbo_string_buffer_append_codepoint('^', output);
  gumbo_string_buffer_append_codepoint('\n', output);
}

size_t gumbo_caret_diagnostic_to_string (
  const GumboError* error,
  const char* source_text,
  size_t source_length,
  char **output
) {
  GumboStringBuffer sb;
  gumbo_string_buffer_init(&sb);
  caret_diagnostic_to_string(error, source_text, source_length, &sb);
  *output = sb.data;
  return sb.length;
}

void gumbo_print_caret_diagnostic (
  const GumboError* error,
  const char* source_text,
  size_t source_length
) {
  GumboStringBuffer text;
  gumbo_string_buffer_init(&text);
  print_message (
    &text,
    "%lu:%lu: ",
    (unsigned long)error->position.line,
    (unsigned long)error->position.column
  );

  caret_diagnostic_to_string(error, source_text, source_length, &text);
  printf("%.*s", (int) text.length, text.data);
  gumbo_string_buffer_destroy(&text);
}

void gumbo_error_destroy(GumboError* error) {
  if (error->type == GUMBO_ERR_PARSER) {
    gumbo_vector_destroy(&error->v.parser.tag_stack);
  }
  gumbo_free(error);
}

void gumbo_init_errors(GumboParser* parser) {
  gumbo_vector_init(5, &parser->_output->errors);
}

void gumbo_destroy_errors(GumboParser* parser) {
  for (unsigned int i = 0; i < parser->_output->errors.length; ++i) {
    gumbo_error_destroy(parser->_output->errors.data[i]);
  }
  gumbo_vector_destroy(&parser->_output->errors);
}
