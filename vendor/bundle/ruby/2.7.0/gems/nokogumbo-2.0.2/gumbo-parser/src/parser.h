#ifndef GUMBO_PARSER_H_
#define GUMBO_PARSER_H_

#ifdef __cplusplus
extern "C" {
#endif

// Contains the definition of the top-level GumboParser structure that's
// threaded through basically every internal function in the library.

struct GumboInternalParserState;
struct GumboInternalOutput;
struct GumboInternalOptions;
struct GumboInternalTokenizerState;

// An overarching struct that's threaded through (nearly) all functions in the
// library, OOP-style. This gives each function access to the options and
// output, along with any internal state needed for the parse.
typedef struct GumboInternalParser {
  // Settings for this parse run.
  const struct GumboInternalOptions* _options;

  // Output for the parse.
  struct GumboInternalOutput* _output;

  // The internal tokenizer state, defined as a pointer to avoid a cyclic
  // dependency on html5tokenizer.h. The main parse routine is responsible for
  // initializing this on parse start, and destroying it on parse end.
  // End-users will never see a non-garbage value in this pointer.
  struct GumboInternalTokenizerState* _tokenizer_state;

  // The internal parser state. Initialized on parse start and destroyed on
  // parse end; end-users will never see a non-garbage value in this pointer.
  struct GumboInternalParserState* _parser_state;
} GumboParser;

#ifdef __cplusplus
}
#endif

#endif  // GUMBO_PARSER_H_
