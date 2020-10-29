#ifndef GUMBO_ASCII_H_
#define GUMBO_ASCII_H_

#include <stddef.h>
#include "macros.h"

#ifdef __cplusplus
extern "C" {
#endif

PURE NONNULL_ARGS
int gumbo_ascii_strcasecmp(const char *s1, const char *s2);

PURE NONNULL_ARGS
int gumbo_ascii_strncasecmp(const char *s1, const char *s2, size_t n);

// If these values change, then _gumbo_ascii_table needs to be regenerated.
#define GUMBO_ASCII_CNTRL 1
#define GUMBO_ASCII_SPACE 2
#define GUMBO_ASCII_DIGIT 4
#define GUMBO_ASCII_UPPER_XDIGIT 8
#define GUMBO_ASCII_LOWER_XDIGIT 16
#define GUMBO_ASCII_UPPER_ALPHA 32
#define GUMBO_ASCII_LOWER_ALPHA 64
#define GUMBO_ASCII_XDIGIT (GUMBO_ASCII_LOWER_XDIGIT | GUMBO_ASCII_UPPER_XDIGIT)
#define GUMBO_ASCII_ALPHA (GUMBO_ASCII_UPPER_ALPHA | GUMBO_ASCII_LOWER_ALPHA)
#define GUMBO_ASCII_ALNUM (GUMBO_ASCII_DIGIT | GUMBO_ASCII_ALPHA)

extern const unsigned char _gumbo_ascii_table[0x80];

CONST_FN
static inline int gumbo_ascii_isascii(int c) {
  return ((unsigned int)c & ~0x7fu) == 0;
}

// 0x00 -- 0x1F (A C0 control)
CONST_FN
static inline int gumbo_ascii_iscntrl(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_CNTRL);
}

// 0x09, 0x0a, 0x0c, 0x0d, 0x20
CONST_FN
static inline int gumbo_ascii_isspace(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_SPACE);
}

CONST_FN
static inline int gumbo_ascii_istab_or_newline(int c) {
  return c == 0x09 || c == 0x0a || c == 0x0d;
}


CONST_FN
static inline int gumbo_ascii_isdigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

CONST_FN
static inline int gumbo_ascii_isalpha(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_ALPHA);
}

CONST_FN
static inline int gumbo_ascii_isxdigit(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_XDIGIT);
}

CONST_FN
static inline int gumbo_ascii_isupper_xdigit(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_UPPER_XDIGIT);
}

CONST_FN
static inline int gumbo_ascii_islower_xdigit(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_LOWER_XDIGIT);
}

CONST_FN
static inline int gumbo_ascii_isupper(int c) {
  return ((unsigned)(c) - 'A') < 26;
}

CONST_FN
static inline int gumbo_ascii_islower(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_LOWER_ALPHA);
}

CONST_FN
static inline int gumbo_ascii_isalnum(int c) {
  return gumbo_ascii_isascii(c)
         && (_gumbo_ascii_table[c] & GUMBO_ASCII_ALNUM);
}
  

CONST_FN
static inline int gumbo_ascii_tolower(int c) {
  if (gumbo_ascii_isupper(c)) {
    return c | 32;
  }
  return c;
}

#ifdef __cplusplus
}
#endif

#endif // GUMBO_ASCII_H_
