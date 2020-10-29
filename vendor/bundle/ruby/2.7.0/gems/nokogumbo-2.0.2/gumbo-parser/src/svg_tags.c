/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 lib/svg_tags.gperf  */
/* Computed positions: -k'3,7' */
/* Filtered by: mk/gperf-filter.sed */

#include "replacement.h"
#include "macros.h"
#include "ascii.h"
#include <string.h>

#define TOTAL_KEYWORDS 36
#define MIN_WORD_LENGTH 6
#define MAX_WORD_LENGTH 19
#define MIN_HASH_VALUE 6
#define MAX_HASH_VALUE 42
/* maximum key range = 37, duplicates = 0 */



static inline unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 12,  2, 10, 22,
       1, 28, 15,  1, 43, 43, 43,  0,  9, 26,
       3, 17,  1, 11,  0, 22,  5, 43,  3,  2,
      43, 43, 43, 43, 43, 43, 43, 43, 12,  2,
      10, 22,  1, 28, 15,  1, 43, 43, 43,  0,
       9, 26,  3, 17,  1, 11,  0, 22,  5, 43,
       3,  2, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
      43, 43, 43, 43, 43, 43, 43
    };
  register unsigned int hval = len;

  switch (hval)
    {
      default:
        hval += asso_values[(unsigned char)str[6]+1];
      /*FALLTHROUGH*/
      case 6:
      case 5:
      case 4:
      case 3:
        hval += asso_values[(unsigned char)str[2]];
        break;
    }
  return hval;
}

const StringReplacement *
gumbo_get_svg_tag_replacement (register const char *str, register size_t len)
{
  static const unsigned char lengthtable[] =
    {
       0,  0,  0,  0,  0,  0,  6,  0,  7,  7,  7,  8, 11, 12,
      12, 13, 11, 12, 16,  7,  7, 16, 11,  7, 19,  8, 13, 17,
      11, 12,  7,  8, 17,  8, 18,  8, 14, 12, 14, 14, 13,  7,
      14
    };
  static const StringReplacement wordlist[] =
    {
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {"fetile", "feTile"},
      {(char*)0,(char*)0},
      {"femerge", "feMerge"},
      {"feimage", "feImage"},
      {"fefuncb", "feFuncB"},
      {"glyphref", "glyphRef"},
      {"femergenode", "feMergeNode"},
      {"femorphology", "feMorphology"},
      {"animatecolor", "animateColor"},
      {"animatemotion", "animateMotion"},
      {"fecomposite", "feComposite"},
      {"feturbulence", "feTurbulence"},
      {"animatetransform", "animateTransform"},
      {"fefuncr", "feFuncR"},
      {"fefunca", "feFuncA"},
      {"feconvolvematrix", "feConvolveMatrix"},
      {"fespotlight", "feSpotLight"},
      {"fefuncg", "feFuncG"},
      {"fecomponenttransfer", "feComponentTransfer"},
      {"altglyph", "altGlyph"},
      {"fecolormatrix", "feColorMatrix"},
      {"fedisplacementmap", "feDisplacementMap"},
      {"altglyphdef", "altGlyphDef"},
      {"altglyphitem", "altGlyphItem"},
      {"feflood", "feFlood"},
      {"clippath", "clipPath"},
      {"fediffuselighting", "feDiffuseLighting"},
      {"textpath", "textPath"},
      {"fespecularlighting", "feSpecularLighting"},
      {"feoffset", "feOffset"},
      {"fedistantlight", "feDistantLight"},
      {"fepointlight", "fePointLight"},
      {"lineargradient", "linearGradient"},
      {"radialgradient", "radialGradient"},
      {"foreignobject", "foreignObject"},
      {"feblend", "feBlend"},
      {"fegaussianblur", "feGaussianBlur"}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        if (len == lengthtable[key])
          {
            register const char *s = wordlist[key].from;

            if (s && (((unsigned char)*str ^ (unsigned char)*s) & ~32) == 0 && !gumbo_ascii_strncasecmp(str, s, len))
              return &wordlist[key];
          }
    }
  return 0;
}
