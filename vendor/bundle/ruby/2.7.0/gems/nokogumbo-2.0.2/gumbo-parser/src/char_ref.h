#ifndef GUMBO_CHAR_REF_H_
#define GUMBO_CHAR_REF_H_

#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Value that indicates no character was produced.
#define kGumboNoChar (-1)

// On input, str points to the start of the string to match and size is the
// size of the string.
//
// Returns the length of the match or 0 if there is no match.
// output[0] contains the first codepoint and output[1] contains the second if
// there are two, otherwise output[1] contains kGumboNoChar.
size_t match_named_char_ref (
  const char *str,
  size_t size,
  int output[2]
);

#ifdef __cplusplus
}
#endif

#endif // GUMBO_CHAR_REF_H_
