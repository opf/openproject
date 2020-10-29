#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "houdini.h"

static const char JS_ESCAPE[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

int
houdini_escape_js(gh_buf *ob, const uint8_t *src, size_t size)
{
	size_t  i = 0, org, ch;

	while (i < size) {
		org = i;
		while (i < size && JS_ESCAPE[src[i]] == 0)
			i++;

		if (likely(i > org)) {
			if (unlikely(org == 0)) {
				if (i >= size)
					return 0;

				gh_buf_grow(ob, HOUDINI_ESCAPED_SIZE(size));
			}

			gh_buf_put(ob, src + org, i - org);
		}

		/* escaping */
		if (i >= size)
			break;

		ch = src[i];
		
		switch (ch) {
		case '/':
			/*
			 * Escape only if preceded by a lt
			 */
			if (i && src[i - 1] == '<')
				gh_buf_putc(ob, '\\');

			gh_buf_putc(ob, ch);
			break;

		case '\r':
			/*
			 * Escape as \n, and skip the next \n if it's there
			 */
			if (i + 1 < size && src[i + 1] == '\n') i++;

		case '\n':
			/*
			 * Escape actually as '\','n', not as '\', '\n'
			 */
			ch = 'n';

		default:
			/*
			 * Normal escaping
			 */
			gh_buf_putc(ob, '\\');
			gh_buf_putc(ob, ch);
			break;
		}

		i++;
	}

	return 1;
}

