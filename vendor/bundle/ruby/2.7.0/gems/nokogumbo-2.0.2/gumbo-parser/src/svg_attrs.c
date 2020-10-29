/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: gperf -m100 lib/svg_attrs.gperf  */
/* Computed positions: -k'1,10,$' */
/* Filtered by: mk/gperf-filter.sed */

#include "replacement.h"
#include "macros.h"
#include "ascii.h"
#include <string.h>

#define TOTAL_KEYWORDS 58
#define MIN_WORD_LENGTH 4
#define MAX_WORD_LENGTH 19
#define MIN_HASH_VALUE 5
#define MAX_HASH_VALUE 77
/* maximum key range = 73, duplicates = 0 */



static inline unsigned int
hash (register const char *str, register size_t len)
{
  static const unsigned char asso_values[] =
    {
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78,  5, 78, 39, 14,  1,
      31, 31, 13, 13, 78, 78, 22, 25, 10,  2,
       7, 78, 22,  0,  1,  3,  1, 78,  0, 36,
      14, 17, 20, 78, 78, 78, 78,  5, 78, 39,
      14,  1, 31, 31, 13, 13, 78, 78, 22, 25,
      10,  2,  7, 78, 22,  0,  1,  3,  1, 78,
       0, 36, 14, 17, 20, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78, 78, 78,
      78, 78, 78, 78, 78, 78, 78, 78
    };
  register unsigned int hval = len;

  switch (hval)
    {
      default:
        hval += asso_values[(unsigned char)str[9]];
      /*FALLTHROUGH*/
      case 9:
      case 8:
      case 7:
      case 6:
      case 5:
      case 4:
      case 3:
      case 2:
      case 1:
        hval += asso_values[(unsigned char)str[0]+2];
        break;
    }
  return hval + asso_values[(unsigned char)str[len - 1]];
}

const StringReplacement *
gumbo_get_svg_attr_replacement (register const char *str, register size_t len)
{
  static const unsigned char lengthtable[] =
    {
       0,  0,  0,  0,  0,  4,  0,  7,  7,  0,  8,  9, 10, 11,
      11, 11, 11, 10, 16, 18, 16, 12, 16, 11, 13, 11, 12, 11,
      16,  0, 17,  9,  9,  8,  9, 10, 13, 10, 12, 14,  8,  4,
      12, 19,  7,  9, 12, 12, 11, 14, 10, 19,  8, 16, 13, 16,
      16, 15, 10, 12,  0,  0, 13, 13, 13,  0,  0,  9, 16,  0,
       0,  0,  0,  0,  0,  0,  0, 17
    };
  static const StringReplacement wordlist[] =
    {
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0},
      {"refx", "refX"},
      {(char*)0,(char*)0},
      {"viewbox", "viewBox"},
      {"targetx", "targetX"},
      {(char*)0,(char*)0},
      {"calcmode", "calcMode"},
      {"maskunits", "maskUnits"},
      {"viewtarget", "viewTarget"},
      {"tablevalues", "tableValues"},
      {"markerunits", "markerUnits"},
      {"stitchtiles", "stitchTiles"},
      {"startoffset", "startOffset"},
      {"numoctaves", "numOctaves"},
      {"requiredfeatures", "requiredFeatures"},
      {"requiredextensions", "requiredExtensions"},
      {"specularexponent", "specularExponent"},
      {"surfacescale", "surfaceScale"},
      {"specularconstant", "specularConstant"},
      {"repeatcount", "repeatCount"},
      {"clippathunits", "clipPathUnits"},
      {"filterunits", "filterUnits"},
      {"lengthadjust", "lengthAdjust"},
      {"markerwidth", "markerWidth"},
      {"maskcontentunits", "maskContentUnits"},
      {(char*)0,(char*)0},
      {"limitingconeangle", "limitingConeAngle"},
      {"pointsatx", "pointsAtX"},
      {"repeatdur", "repeatDur"},
      {"keytimes", "keyTimes"},
      {"keypoints", "keyPoints"},
      {"keysplines", "keySplines"},
      {"gradientunits", "gradientUnits"},
      {"textlength", "textLength"},
      {"stddeviation", "stdDeviation"},
      {"primitiveunits", "primitiveUnits"},
      {"edgemode", "edgeMode"},
      {"refy", "refY"},
      {"spreadmethod", "spreadMethod"},
      {"preserveaspectratio", "preserveAspectRatio"},
      {"targety", "targetY"},
      {"pointsatz", "pointsAtZ"},
      {"markerheight", "markerHeight"},
      {"patternunits", "patternUnits"},
      {"baseprofile", "baseProfile"},
      {"systemlanguage", "systemLanguage"},
      {"zoomandpan", "zoomAndPan"},
      {"patterncontentunits", "patternContentUnits"},
      {"glyphref", "glyphRef"},
      {"xchannelselector", "xChannelSelector"},
      {"attributetype", "attributeType"},
      {"kernelunitlength", "kernelUnitLength"},
      {"ychannelselector", "yChannelSelector"},
      {"diffuseconstant", "diffuseConstant"},
      {"pathlength", "pathLength"},
      {"kernelmatrix", "kernelMatrix"},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {"preservealpha", "preserveAlpha"},
      {"attributename", "attributeName"},
      {"basefrequency", "baseFrequency"},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {"pointsaty", "pointsAtY"},
      {"patterntransform", "patternTransform"},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {(char*)0,(char*)0}, {(char*)0,(char*)0},
      {"gradienttransform", "gradientTransform"}
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
