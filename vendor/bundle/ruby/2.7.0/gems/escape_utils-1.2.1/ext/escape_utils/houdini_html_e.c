#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "houdini.h"

/**
 * According to the OWASP rules:
 *
 * & --> &amp;
 * < --> &lt;
 * > --> &gt;
 * " --> &quot;
 * ' --> &#x27;     &apos; is not recommended
 * / --> &#x2F;     forward slash is included as it helps end an HTML entity
 *
 */
static const char HTML_ESCAPE_TABLE[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 0, 0, 2, 3, 0, 0, 0, 0, 0, 0, 0, 4, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 6, 0, 
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
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

static const char *HTML_ESCAPES[] = {
        "",
        "&quot;",
        "&amp;",
        "&#39;",
        "&#47;",
        "&lt;",
        "&gt;"
};

int
houdini_escape_html0(gh_buf *ob, const uint8_t *src, size_t size, int secure)
{
	size_t  i = 0, org, esc = 0;

	while (i < size) {
		org = i;
		while (i < size && (esc = HTML_ESCAPE_TABLE[src[i]]) == 0)
			i++;

		if (i > org) {
			if (unlikely(org == 0)) {
				if (i >= size)
					return 0;

				gh_buf_grow(ob, HOUDINI_ESCAPED_SIZE(size));
			}

			gh_buf_put(ob, src + org, i - org);
		}

		/* escaping */
		if (unlikely(i >= size))
			break;

		/* The forward slash is only escaped in secure mode */
		if (src[i] == '/' && !secure) {
			gh_buf_putc(ob, '/');
		} else {
			gh_buf_puts(ob, HTML_ESCAPES[esc]);
		}

		i++;
	}

	return 1;
}

int
houdini_escape_html(gh_buf *ob, const uint8_t *src, size_t size)
{
	return houdini_escape_html0(ob, src, size, 1);
}

