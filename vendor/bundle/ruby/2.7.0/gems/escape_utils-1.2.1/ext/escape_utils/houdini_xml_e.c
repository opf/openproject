#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "houdini.h"

/**
 * & --> &amp;
 * < --> &lt;
 * > --> &gt;
 * " --> &quot;
 * ' --> &apos;
 */
static const char *LOOKUP_CODES[] = {
	"", /* reserved: use literal single character */
	"", /* unused */
	"", /* reserved: 2 character UTF-8 */
	"", /* reserved: 3 character UTF-8 */
	"", /* reserved: 4 character UTF-8 */
	"?", /* invalid UTF-8 character */
	"&quot;",
	"&amp;",
	"&apos;",
	"&lt;",
	"&gt;"
};

static const char CODE_INVALID = 5;

static const char XML_LOOKUP_TABLE[] = {
	/* ASCII: 0xxxxxxx */
	5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 5, 5, 0, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	0, 0, 6, 0, 0, 0, 7, 8, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0,10, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

	/* Invalid UTF-8 char start: 10xxxxxx */
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,

	/* Multibyte UTF-8 */

	/* 2 bytes: 110xxxxx */
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,

	/* 3 bytes: 1110xxxx */
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,

	/* 4 bytes: 11110xxx */
	4, 4, 4, 4, 4, 4, 4, 4,

	/* Invalid UTF-8: 11111xxx */
	5, 5, 5, 5, 5, 5, 5, 5,
};

int
houdini_escape_xml(gh_buf *ob, const uint8_t *src, size_t size)
{
	size_t i = 0;
	unsigned char code = 0;

	gh_buf_grow(ob, HOUDINI_ESCAPED_SIZE(size));

	while (i < size) {
		size_t start, end;

		start = end = i;

		while (i < size) {
			unsigned int byte;

			byte = src[i++];
			code = XML_LOOKUP_TABLE[byte];

			if (!code) {
				/* single character used literally */
			} else if (code >= CODE_INVALID) {
				break; /* insert lookup code string */
			} else if (code > size - end) {
				code = CODE_INVALID; /* truncated UTF-8 character */
				break;
			} else {
				unsigned int chr = byte & (0xff >> code);

				while (--code) {
					byte = src[i++];
					if ((byte & 0xc0) != 0x80) {
						code = CODE_INVALID;
						break;
					}
					chr = (chr << 6) + (byte & 0x3f);
				}

				switch (i - end) {
					case 2:
						if (chr < 0x80)
							code = CODE_INVALID;
						break;
					case 3:
						if (chr < 0x800 ||
						    (chr > 0xd7ff && chr < 0xe000) ||
							chr > 0xfffd)
							code = CODE_INVALID;
						break;
					case 4:
						if (chr < 0x10000 || chr > 0x10ffff)
							code = CODE_INVALID;
						break;
					default:
						break;
				}
				if (code == CODE_INVALID)
					break;
			}
			end = i;
		}

		if (end > start)
			gh_buf_put(ob, src + start, end - start);

		/* escaping */
		if (end >= size)
			break;

		gh_buf_puts(ob, LOOKUP_CODES[code]);
	}

	return 1;
}
