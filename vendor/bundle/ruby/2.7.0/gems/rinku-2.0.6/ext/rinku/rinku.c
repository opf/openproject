/*
 * Copyright (c) 2016, GitHub, Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include "rinku.h"
#include "autolink.h"
#include "buffer.h"
#include "utf8.h"

typedef enum {
	HTML_TAG_NONE = 0,
	HTML_TAG_OPEN,
	HTML_TAG_CLOSE,
} html_tag;

typedef enum {
	AUTOLINK_ACTION_NONE = 0,
	AUTOLINK_ACTION_WWW,
	AUTOLINK_ACTION_EMAIL,
	AUTOLINK_ACTION_URL,
	AUTOLINK_ACTION_SKIP_TAG
} autolink_action;

typedef bool (*autolink_parse_cb)(
	struct autolink_pos *, const uint8_t *, size_t, size_t, unsigned int);

static autolink_parse_cb g_callbacks[] = {
	NULL,
	autolink__www,	/* 1 */
	autolink__email,/* 2 */
	autolink__url,	/* 3 */
};

static const char *g_hrefs[] = {
	NULL,
	"<a href=\"http://",
	"<a href=\"mailto:",
	"<a href=\"",
};

/*
 * Rinku assumes valid HTML encoding for all input, but there's still
 * the case where a link can contain a double quote `"` that allows XSS.
 *
 * We need to properly escape the character we use for the `href` attribute
 * declaration
 */
static void print_link(struct buf *ob, const uint8_t *link, size_t size)
{
	size_t i = 0, org;

	while (i < size) {
		org = i;

		while (i < size && link[i] != '"')
			i++;

		if (i > org)
			bufput(ob, link + org, i - org);

		if (i >= size)
			break;

		BUFPUTSL(ob, "&quot;");
		i++;
	}
}

/* From sundown/html/html.c */
static int
html_is_tag(const uint8_t *tag_data, size_t tag_size, const char *tagname)
{
	size_t i;
	int closed = 0;

	if (tag_size < 3 || tag_data[0] != '<')
		return HTML_TAG_NONE;

	i = 1;

	if (tag_data[i] == '/') {
		closed = 1;
		i++;
	}

	for (; i < tag_size; ++i, ++tagname) {
		if (*tagname == 0)
			break;

		if (tag_data[i] != *tagname)
			return HTML_TAG_NONE;
	}

	if (i == tag_size)
		return HTML_TAG_NONE;

	if (rinku_isspace(tag_data[i]) || tag_data[i] == '>')
		return closed ? HTML_TAG_CLOSE : HTML_TAG_OPEN;

	return HTML_TAG_NONE;
}

static size_t
autolink__skip_tag(
	struct buf *ob,
	const uint8_t *text,
	size_t size,
	const char **skip_tags)
{
	size_t i = 0;

	while (i < size && text[i] != '>')
		i++;

	while (*skip_tags != NULL) {
		if (html_is_tag(text, size, *skip_tags) == HTML_TAG_OPEN)
			break;

		skip_tags++;
	}

	if (*skip_tags != NULL) {
		for (;;) {
			while (i < size && text[i] != '<')
				i++;

			if (i == size)
				break;

			if (html_is_tag(text + i, size - i, *skip_tags) == HTML_TAG_CLOSE)
				break;

			i++;
		}

		while (i < size && text[i] != '>')
			i++;
	}

	return i;
}

int
rinku_autolink(
	struct buf *ob,
	const uint8_t *text,
	size_t size,
	autolink_mode mode,
	unsigned int flags,
	const char *link_attr,
	const char **skip_tags,
	void (*link_text_cb)(struct buf *, const uint8_t *, size_t, void *),
	void *payload)
{
	size_t i, end;
	char active_chars[256] = {0};
	int link_count = 0;

	if (!text || size == 0)
		return 0;

	active_chars['<'] = AUTOLINK_ACTION_SKIP_TAG;

	if (mode & AUTOLINK_EMAILS)
		active_chars['@'] = AUTOLINK_ACTION_EMAIL;

	if (mode & AUTOLINK_URLS) {
		active_chars['w'] = AUTOLINK_ACTION_WWW;
		active_chars['W'] = AUTOLINK_ACTION_WWW;
		active_chars[':'] = AUTOLINK_ACTION_URL;
	}

	if (link_attr != NULL) {
		while (rinku_isspace(*link_attr))
			link_attr++;
	}

	bufgrow(ob, size);

	i = end = 0;

	while (i < size) {
		struct autolink_pos link;
		bool link_found;
		char action = 0;

		while (end < size && (action = active_chars[text[end]]) == 0)
			end++;

		if (end == size) {
			if (link_count > 0)
				bufput(ob, text + i, end - i);
			break;
		}

		if (action == AUTOLINK_ACTION_SKIP_TAG) {
			end += autolink__skip_tag(ob,
				text + end, size - end, skip_tags);
			continue;
		}

		link_found = g_callbacks[(int)action](
			&link, text, end, size, flags);

		if (link_found && link.start >= i) {
			const uint8_t *link_str = text + link.start;
			const size_t link_len = link.end - link.start;

			bufput(ob, text + i, link.start - i);
			bufputs(ob, g_hrefs[(int)action]);
			print_link(ob, link_str, link_len);

			if (link_attr) {
				BUFPUTSL(ob, "\" ");
				bufputs(ob, link_attr);
				bufputc(ob, '>');
			} else {
				BUFPUTSL(ob, "\">");
			}

			if (link_text_cb) {
				link_text_cb(ob, link_str, link_len, payload);
			} else {
				bufput(ob, link_str, link_len);
			}

			BUFPUTSL(ob, "</a>");

			link_count++;
			end = i = link.end;
		} else {
			end = end + 1;
		}
	}

	return link_count;
}
