#ifndef GUMBO_ERROR_H_
#define GUMBO_ERROR_H_

#include <stdint.h>

#include "gumbo.h"
#include "insertion_mode.h"
#include "string_buffer.h"
#include "token_type.h"
#include "tokenizer_states.h"

#ifdef __cplusplus
extern "C" {
#endif

struct GumboInternalParser;

typedef enum {
  // Defined errors.
  // https://html.spec.whatwg.org/multipage/parsing.html#parse-errors
  GUMBO_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT,
  GUMBO_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER,
  GUMBO_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER,
  GUMBO_ERR_ABSENCE_OF_DIGITS_IN_NUMERIC_CHARACTER_REFERENCE,
  GUMBO_ERR_CDATA_IN_HTML_CONTENT,
  GUMBO_ERR_CHARACTER_REFERENCE_OUTSIDE_UNICODE_RANGE,
  GUMBO_ERR_CONTROL_CHARACTER_IN_INPUT_STREAM,
  GUMBO_ERR_CONTROL_CHARACTER_REFERENCE,
  GUMBO_ERR_END_TAG_WITH_ATTRIBUTES,
  GUMBO_ERR_DUPLICATE_ATTRIBUTE,
  GUMBO_ERR_END_TAG_WITH_TRAILING_SOLIDUS,
  GUMBO_ERR_EOF_BEFORE_TAG_NAME,
  GUMBO_ERR_EOF_IN_CDATA,
  GUMBO_ERR_EOF_IN_COMMENT,
  GUMBO_ERR_EOF_IN_DOCTYPE,
  GUMBO_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT,
  GUMBO_ERR_EOF_IN_TAG,
  GUMBO_ERR_INCORRECTLY_CLOSED_COMMENT,
  GUMBO_ERR_INCORRECTLY_OPENED_COMMENT,
  GUMBO_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME,
  GUMBO_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME,
  GUMBO_ERR_MISSING_ATTRIBUTE_VALUE,
  GUMBO_ERR_MISSING_DOCTYPE_NAME,
  GUMBO_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER,
  GUMBO_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER,
  GUMBO_ERR_MISSING_END_TAG_NAME,
  GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER,
  GUMBO_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER,
  GUMBO_ERR_MISSING_SEMICOLON_AFTER_CHARACTER_REFERENCE,
  GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD,
  GUMBO_ERR_MISSING_WHITESPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD,
  GUMBO_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME,
  GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES,
  GUMBO_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS,
  GUMBO_ERR_NESTED_COMMENT,
  GUMBO_ERR_NONCHARACTER_CHARACTER_REFERENCE,
  GUMBO_ERR_NONCHARACTER_IN_INPUT_STREAM,
  GUMBO_ERR_NON_VOID_HTML_ELEMENT_START_TAG_WITH_TRAILING_SOLIDUS,
  GUMBO_ERR_NULL_CHARACTER_REFERENCE,
  GUMBO_ERR_SURROGATE_CHARACTER_REFERENCE,
  GUMBO_ERR_SURROGATE_IN_INPUT_STREAM,
  GUMBO_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER,
  GUMBO_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME,
  GUMBO_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE,
  GUMBO_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME,
  GUMBO_ERR_UNEXPECTED_NULL_CHARACTER,
  GUMBO_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME,
  GUMBO_ERR_UNEXPECTED_SOLIDUS_IN_TAG,
  GUMBO_ERR_UNKNOWN_NAMED_CHARACTER_REFERENCE,

  // Encoding errors.
  GUMBO_ERR_UTF8_INVALID,
  GUMBO_ERR_UTF8_TRUNCATED,

  // Generic parser error.
  GUMBO_ERR_PARSER,
} GumboErrorType;

// Additional data for tokenizer errors.
// This records the current state and codepoint encountered - this is usually
// enough to reconstruct what went wrong and provide a friendly error message.
typedef struct GumboInternalTokenizerError {
  // The bad codepoint encountered.
  int codepoint;

  // The state that the tokenizer was in at the time.
  GumboTokenizerEnum state;
} GumboTokenizerError;

// Additional data for parse errors.
typedef struct GumboInternalParserError {
  // The type of input token that resulted in this error.
  GumboTokenType input_type;

  // The HTML tag of the input token. TAG_UNKNOWN if this was not a tag token.
  GumboTag input_tag;

  // The insertion mode that the parser was in at the time.
  GumboInsertionMode parser_state;

  // The tag stack at the point of the error. Note that this is an GumboVector
  // of GumboTag's *stored by value* - cast the void* to an GumboTag directly to
  // get at the tag.
  GumboVector /* GumboTag */ tag_stack;
} GumboParserError;

// The overall error struct representing an error in decoding/tokenizing/parsing
// the HTML. This contains an enumerated type flag, a source position, and then
// a union of fields containing data specific to the error.
struct GumboInternalError {
  // The type of error.
  GumboErrorType type;

  // The position within the source file where the error occurred.
  GumboSourcePosition position;

  // The piece of text that caused the error.
  GumboStringPiece original_text;

  // Type-specific error information.
  union {
    // Tokenizer errors.
    GumboTokenizerError tokenizer;

    // Parser errors.
    GumboParserError parser;
  } v;
};

// Adds a new error to the parser's error list, and returns a pointer to it so
// that clients can fill out the rest of its fields. May return NULL if we're
// already over the max_errors field specified in GumboOptions.
GumboError* gumbo_add_error(struct GumboInternalParser* parser);

// Initializes the errors vector in the parser.
void gumbo_init_errors(struct GumboInternalParser* errors);

// Frees all the errors in the 'errors_' field of the parser.
void gumbo_destroy_errors(struct GumboInternalParser* errors);

// Frees the memory used for a single GumboError.
void gumbo_error_destroy(GumboError* error);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_ERROR_H_
