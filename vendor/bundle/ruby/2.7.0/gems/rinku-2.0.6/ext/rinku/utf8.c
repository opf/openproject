#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <stdbool.h>

#include "utf8.h"

/** 1 = space, 2 = punct, 3 = digit, 4 = alpha, 0 = other
 */
static const uint8_t ctype_class[256] = {
    /*      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f */
    /* 0 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0,
    /* 1 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 2 */ 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    /* 3 */ 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2,
    /* 4 */ 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    /* 5 */ 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2,
    /* 6 */ 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    /* 7 */ 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2, 2, 0,
    /* 8 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* 9 */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* a */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* b */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* c */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* d */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* e */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    /* f */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

bool rinku_isspace(char c) { return ctype_class[(uint8_t)c] == 1; }
bool rinku_ispunct(char c) { return ctype_class[(uint8_t)c] == 2; }
bool rinku_isdigit(char c) { return ctype_class[(uint8_t)c] == 3; }
bool rinku_isalpha(char c) { return ctype_class[(uint8_t)c] == 4; }
bool rinku_isalnum(char c)
{
	uint8_t cls = ctype_class[(uint8_t)c];
	return (cls == 3 || cls == 4);
}

static const int8_t utf8proc_utf8class[256] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0};

static int32_t read_cp(const uint8_t *str, int8_t length)
{
	switch (length) {
	case 1:
		return str[0];
	case 2:
		return ((str[0] & 0x1F) << 6) + (str[1] & 0x3F);
	case 3:
		return ((str[0] & 0x0F) << 12) + ((str[1] & 0x3F) << 6) +
			(str[2] & 0x3F);
	case 4:
		return ((str[0] & 0x07) << 18) + ((str[1] & 0x3F) << 12) +
			((str[2] & 0x3F) << 6) + (str[3] & 0x3F);
	default:
		return 0xFFFD; // replacement character
	}
}

int32_t utf8proc_next(const uint8_t *str, size_t *pos)
{
	const size_t p = *pos;
	const int8_t length = utf8proc_utf8class[str[p]];
	(*pos) += length;
	return read_cp(str + p, length);
}

int32_t utf8proc_back(const uint8_t *str, size_t *pos)
{
	const size_t p = *pos;
	int8_t length = 0;

	if (!p)
		return 0x0;

	if ((str[p - 1] & 0x80) == 0x0) {
		(*pos) -= 1;
		return str[p - 1];
	}

	if (p > 1 && utf8proc_utf8class[str[p - 2]] == 2)
		length = 2;
	else if (p > 2 && utf8proc_utf8class[str[p - 3]] == 3)
		length = 3;
	else if (p > 3 && utf8proc_utf8class[str[p - 4]] == 4)
		length = 4;

	(*pos) -= length;
	return read_cp(&str[*pos], length);
}

size_t utf8proc_find_space(const uint8_t *str, size_t pos, size_t size)
{
	while (pos < size) {
		const size_t last = pos;
		int32_t uc = utf8proc_next(str, &pos);
		if (uc == 0xFFFD)
			return size;
		else if (utf8proc_is_space(uc))
			return last;
	}
	return size;
}

int32_t utf8proc_rewind(const uint8_t *data, size_t pos)
{
	int8_t length = 0;

	if (!pos)
		return 0x0;

	if ((data[pos - 1] & 0x80) == 0x0)
		return data[pos - 1];

	if (pos > 1 && utf8proc_utf8class[data[pos - 2]] == 2)
		length = 2;
	else if (pos > 2 && utf8proc_utf8class[data[pos - 3]] == 3)
		length = 3;
	else if (pos > 3 && utf8proc_utf8class[data[pos - 4]] == 4)
		length = 4;

	return read_cp(&data[pos - length], length);
}

int32_t utf8proc_open_paren_character(int32_t cclose)
{
	switch (cclose) {
	case '"': return '"';
	case '\'':  return '\'';
	case ')': return '(';
	case ']': return '[';
	case '}': return '{';
	case 65289: return 65288; /* （） */
	case 12305: return 12304; /* 【】 */
	case 12303: return 12302; /* 『』 */
	case 12301: return 12300; /* 「」 */
	case 12299: return 12298; /* 《》 */
	case 12297: return 12296; /* 〈〉 */
	}
	return 0;
}

bool utf8proc_is_space(int32_t uc)
{
	return (uc == 9 || uc == 10 || uc == 12 || uc == 13 ||
			uc == 32 || uc == 160 || uc == 5760 ||
			(uc >= 8192 && uc <= 8202) || uc == 8239 ||
			uc == 8287 || uc == 12288);
}

bool utf8proc_is_punctuation(int32_t uc)
{
	if (uc < 128)
		return rinku_ispunct(uc);

	return 
		(uc == 161 || uc == 167 || uc == 171 || uc == 182 ||
		 uc == 183 || uc == 187 || uc == 191 || uc == 894 ||
		 uc == 903 || (uc >= 1370 && uc <= 1375) || uc == 1417 ||
		 uc == 1418 || uc == 1470 || uc == 1472 || uc == 1475 ||
		 uc == 1478 || uc == 1523 || uc == 1524 || uc == 1545 ||
		 uc == 1546 || uc == 1548 || uc == 1549 || uc == 1563 ||
		 uc == 1566 || uc == 1567 || (uc >= 1642 && uc <= 1645) ||
		 uc == 1748 || (uc >= 1792 && uc <= 1805) ||
		 (uc >= 2039 && uc <= 2041) || (uc >= 2096 && uc <= 2110) ||
		 uc == 2142 || uc == 2404 || uc == 2405 || uc == 2416 ||
		 uc == 2800 || uc == 3572 || uc == 3663 || uc == 3674 ||
		 uc == 3675 || (uc >= 3844 && uc <= 3858) || uc == 3860 ||
		 (uc >= 3898 && uc <= 3901) || uc == 3973 ||
		 (uc >= 4048 && uc <= 4052) || uc == 4057 || uc == 4058 ||
		 (uc >= 4170 && uc <= 4175) || uc == 4347 ||
		 (uc >= 4960 && uc <= 4968) || uc == 5120 || uc == 5741 ||
		 uc == 5742 || uc == 5787 || uc == 5788 ||
		 (uc >= 5867 && uc <= 5869) || uc == 5941 || uc == 5942 ||
		 (uc >= 6100 && uc <= 6102) || (uc >= 6104 && uc <= 6106) ||
		 (uc >= 6144 && uc <= 6154) || uc == 6468 || uc == 6469 ||
		 uc == 6686 || uc == 6687 || (uc >= 6816 && uc <= 6822) ||
		 (uc >= 6824 && uc <= 6829) || (uc >= 7002 && uc <= 7008) ||
		 (uc >= 7164 && uc <= 7167) || (uc >= 7227 && uc <= 7231) ||
		 uc == 7294 || uc == 7295 || (uc >= 7360 && uc <= 7367) ||
		 uc == 7379 || (uc >= 8208 && uc <= 8231) ||
		 (uc >= 8240 && uc <= 8259) || (uc >= 8261 && uc <= 8273) ||
		 (uc >= 8275 && uc <= 8286) || uc == 8317 || uc == 8318 ||
		 uc == 8333 || uc == 8334 || (uc >= 8968 && uc <= 8971) ||
		 uc == 9001 || uc == 9002 || (uc >= 10088 && uc <= 10101) ||
		 uc == 10181 || uc == 10182 || (uc >= 10214 && uc <= 10223) ||
		 (uc >= 10627 && uc <= 10648) || (uc >= 10712 && uc <= 10715) ||
		 uc == 10748 || uc == 10749 || (uc >= 11513 && uc <= 11516) ||
		 uc == 11518 || uc == 11519 || uc == 11632 ||
		 (uc >= 11776 && uc <= 11822) || (uc >= 11824 && uc <= 11842) ||
		 (uc >= 12289 && uc <= 12291) || (uc >= 12296 && uc <= 12305) ||
		 (uc >= 12308 && uc <= 12319) || uc == 12336 || uc == 12349 ||
		 uc == 12448 || uc == 12539 || uc == 42238 || uc == 42239 ||
		 (uc >= 42509 && uc <= 42511) || uc == 42611 || uc == 42622 ||
		 (uc >= 42738 && uc <= 42743) || (uc >= 43124 && uc <= 43127) ||
		 uc == 43214 || uc == 43215 || (uc >= 43256 && uc <= 43258) ||
		 uc == 43310 || uc == 43311 || uc == 43359 ||
		 (uc >= 43457 && uc <= 43469) || uc == 43486 || uc == 43487 ||
		 (uc >= 43612 && uc <= 43615) || uc == 43742 || uc == 43743 ||
		 uc == 43760 || uc == 43761 || uc == 44011 || uc == 64830 ||
		 uc == 64831 || (uc >= 65040 && uc <= 65049) ||
		 (uc >= 65072 && uc <= 65106) || (uc >= 65108 && uc <= 65121) ||
		 uc == 65123 || uc == 65128 || uc == 65130 || uc == 65131 ||
		 (uc >= 65281 && uc <= 65283) || (uc >= 65285 && uc <= 65290) ||
		 (uc >= 65292 && uc <= 65295) || uc == 65306 || uc == 65307 ||
		 uc == 65311 || uc == 65312 || (uc >= 65339 && uc <= 65341) ||
		 uc == 65343 || uc == 65371 || uc == 65373 ||
		 (uc >= 65375 && uc <= 65381) || (uc >= 65792 && uc <= 65794) ||
		 uc == 66463 || uc == 66512 || uc == 66927 || uc == 67671 ||
		 uc == 67871 || uc == 67903 || (uc >= 68176 && uc <= 68184) ||
		 uc == 68223 || (uc >= 68336 && uc <= 68342) ||
		 (uc >= 68409 && uc <= 68415) || (uc >= 68505 && uc <= 68508) ||
		 (uc >= 69703 && uc <= 69709) || uc == 69819 || uc == 69820 ||
		 (uc >= 69822 && uc <= 69825) || (uc >= 69952 && uc <= 69955) ||
		 uc == 70004 || uc == 70005 || (uc >= 70085 && uc <= 70088) ||
		 uc == 70093 || (uc >= 70200 && uc <= 70205) || uc == 70854 ||
		 (uc >= 71105 && uc <= 71113) || (uc >= 71233 && uc <= 71235) ||
		 (uc >= 74864 && uc <= 74868) || uc == 92782 || uc == 92783 ||
		 uc == 92917 || (uc >= 92983 && uc <= 92987) || uc == 92996 ||
		 uc == 113823);
}
