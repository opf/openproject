#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "houdini.h"

int
houdini_unescape_js(gh_buf *ob, const uint8_t *src, size_t size)
{
	size_t  i = 0, org, ch;

	while (i < size) {
		org = i;
		while (i < size && src[i] != '\\')
			i++;

		if (likely(i > org)) {
			if (unlikely(org == 0)) {
				if (i >= size)
					return 0;

				gh_buf_grow(ob, HOUDINI_UNESCAPED_SIZE(size));
			}

			gh_buf_put(ob, src + org, i - org);
		}

		/* escaping */
		if (i == size)
			break;

		if (++i == size) {
			gh_buf_putc(ob, '\\');
			break;
		}

		ch = src[i];

		switch (ch) {
		case 'n':
			ch = '\n';
			/* pass through */

		case '\\':
		case '\'':
		case '\"':
		case '/':
			gh_buf_putc(ob, ch);
			i++;
			break;

		default:
			gh_buf_putc(ob, '\\');
			break;
		}
	}

	return 1;
}

