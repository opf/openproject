/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 -n lib/foreign_attrs.gperf  */
/* Computed positions: -k'2,8' */
/* Filtered by: mk/gperf-filter.sed */

#include "replacement.h"
#include "macros.h"
#include <string.h>

#define TOTAL_KEYWORDS 11
#define MIN_WORD_LENGTH 5
#define MAX_WORD_LENGTH 13
#define MIN_HASH_VALUE 0
#define MAX_HASH_VALUE 10
/* maximum key range = 11, duplicates = 0 */

static inline unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11,  2,
      11, 10, 11,  9,  7,  6, 11, 11,  1,  0,
      11,  5, 11, 11,  4, 11, 11, 11, 11, 11,
      11,  3, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
      11, 11, 11, 11, 11, 11
    };
  register unsigned int hval = 0;

  switch (len)
    {
      default:
        hval += asso_values[(unsigned char)str[7]];
      /*FALLTHROUGH*/
      case 7:
      case 6:
      case 5:
      case 4:
      case 3:
      case 2:
        hval += asso_values[(unsigned char)str[1]];
        break;
    }
  return hval;
}

const ForeignAttrReplacement *
gumbo_get_foreign_attr_replacement (register const char *str, register size_t len)
{
  static const unsigned char lengthtable[] =
    {
       5, 11,  9, 13, 10, 10, 10, 11, 10,  8,  8
    };
  static const ForeignAttrReplacement wordlist[] =
    {
      {"xmlns", "xmlns", GUMBO_ATTR_NAMESPACE_XMLNS},
      {"xmlns:xlink", "xlink", GUMBO_ATTR_NAMESPACE_XMLNS},
      {"xml:space", "space", GUMBO_ATTR_NAMESPACE_XML},
      {"xlink:actuate", "actuate", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:type", "type", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:href", "href", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:role", "role", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:title", "title", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xlink:show", "show", GUMBO_ATTR_NAMESPACE_XLINK},
      {"xml:lang", "lang", GUMBO_ATTR_NAMESPACE_XML},
      {"xml:base", "base", GUMBO_ATTR_NAMESPACE_XML}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].from;

            if (s && *str == *s && !memcmp (str + 1, s + 1, len - 1))
              return &wordlist[key];
          }
    }
  return 0;
}
