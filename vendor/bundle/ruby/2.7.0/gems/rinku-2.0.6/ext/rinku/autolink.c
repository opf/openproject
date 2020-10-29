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
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

#include "buffer.h"
#include "autolink.h"
#include "utf8.h"

#if defined(_WIN32)
#define strncasecmp	_strnicmp
#endif

static int
is_valid_hostchar(const uint8_t *link, size_t link_len)
{
	size_t pos = 0;
	int32_t ch = utf8proc_next(link, &pos);
	return !utf8proc_is_space(ch) && !utf8proc_is_punctuation(ch);
}

bool
autolink_issafe(const uint8_t *link, size_t link_len)
{
	static const size_t valid_uris_count = 5;
	static const char *valid_uris[] = {
		"/", "http://", "https://", "ftp://", "mailto:"
	};

	size_t i;

	for (i = 0; i < valid_uris_count; ++i) {
		size_t len = strlen(valid_uris[i]);

		if (link_len > len &&
			strncasecmp((char *)link, valid_uris[i], len) == 0 &&
			rinku_isalnum(link[len]))
			return true;
	}

	return false;
}

static bool
autolink_delim(const uint8_t *data, struct autolink_pos *link)
{
	int32_t cclose, copen = 0;
	size_t i;

	for (i = link->start; i < link->end; ++i)
		if (data[i] == '<') {
			link->end = i;
			break;
		}

	while (link->end > link->start) {
		if (strchr("?!.,:", data[link->end - 1]) != NULL)
			link->end--;

		else if (data[link->end - 1] == ';') {
			size_t new_end = link->end - 2;

			while (new_end > 0 && rinku_isalnum(data[new_end]))
				new_end--;

			if (new_end < link->end - 2) {
				if (new_end > 0 && data[new_end] == '#')
					new_end--;

				if (data[new_end] == '&') {
					link->end = new_end;
					continue;
				}
			}
			link->end--;
		}
		else break;
	}

	if (link->end == link->start)
		return false;

	cclose = utf8proc_rewind(data, link->end);
	copen = utf8proc_open_paren_character(cclose);

	if (copen != 0) {
		/* Try to close the final punctuation sign in this link; if
		 * there's more closing than opening punctuation symbols in the
		 * URL, we conservatively remove one closing punctuation from
		 * the end of the URL.
		 *
		 * Examples:
		 *
		 *	foo http://www.pokemon.com/Pikachu_(Electric) bar
		 *		=> http://www.pokemon.com/Pikachu_(Electric)
		 *
		 *	foo (http://www.pokemon.com/Pikachu_(Electric)) bar
		 *		=> http://www.pokemon.com/Pikachu_(Electric)
		 *
		 *	foo http://www.pokemon.com/Pikachu_(Electric)) bar
		 *		=> http://www.pokemon.com/Pikachu_(Electric)
		 *
		 *	(foo http://www.pokemon.com/Pikachu_(Electric)) bar
		 *		=> http://www.pokemon.com/Pikachu_(Electric)
		 */

		size_t closing = 0;
		size_t opening = 0;
		size_t i = link->start;

		while (i < link->end) {
			int32_t c = utf8proc_next(data, &i);
			if (c == copen)
				opening++;
			else if (c == cclose)
				closing++;
		}

		if (copen == cclose) {
			if (opening > 0)
				utf8proc_back(data, &link->end);
		}
		else {
			if (closing > opening)
				utf8proc_back(data, &link->end);
		}
	}

	return true;
}

static bool
autolink_delim_iter(const uint8_t *data, struct autolink_pos *link)
{
	size_t prev_link_end;
	int iterations = 0;

	while(link->end != 0) {
		prev_link_end = link->end;
		if (!autolink_delim(data, link))
			return false;
		if (prev_link_end == link->end || iterations > 5) {
			break;
		}
		iterations++;
	}

	return true;
}

static bool
check_domain(const uint8_t *data, size_t size,
		struct autolink_pos *link, bool allow_short)
{
	size_t i, np = 0, uscore1 = 0, uscore2 = 0;

	if (!rinku_isalnum(data[link->start]))
		return false;

	for (i = link->start + 1; i < size - 1; ++i) {
		if (data[i] == '_') {
			uscore2++;
		} else if (data[i] == '.') {
			uscore1 = uscore2;
			uscore2 = 0;
			np++;
		} else if (!is_valid_hostchar(data + i, size - i) && data[i] != '-')
			break;
	}

	if (uscore1 > 0 || uscore2 > 0)
		return false;

	link->end = i;

	if (allow_short) {
		/* We don't need a valid domain in the strict sense (with
		 * least one dot; so just make sure it's composed of valid
		 * domain characters and return the length of the the valid
		 * sequence. */
		return true;
	} else {
		/* a valid domain needs to have at least a dot.
		 * that's as far as we get */
		return (np > 0);
	}
}

bool
autolink__www(
	struct autolink_pos *link,
	const uint8_t *data,
	size_t pos,
	size_t size,
	unsigned int flags)
{
	int32_t boundary;
	assert(data[pos] == 'w' || data[pos] == 'W');

	if ((size - pos) < 4 ||
		(data[pos + 1] != 'w' && data[pos + 1] != 'W') ||
		(data[pos + 2] != 'w' && data[pos + 2] != 'W') ||
		data[pos + 3] != '.')
		return false;

	boundary = utf8proc_rewind(data, pos);
	if (boundary &&
		!utf8proc_is_space(boundary) &&
		!utf8proc_is_punctuation(boundary))
		return false;

	link->start = pos;
	link->end = 0;

	if (!check_domain(data, size, link, false))
		return false;

	link->end = utf8proc_find_space(data, link->end, size);
	return autolink_delim_iter(data, link);
}

bool
autolink__email(
	struct autolink_pos *link,
	const uint8_t *data,
	size_t pos,
	size_t size,
	unsigned int flags)
{
	int nb = 0, np = 0;
	assert(data[pos] == '@');

	link->start = pos;
	link->end = pos;

	for (; link->start > 0; link->start--) {
		uint8_t c = data[link->start - 1];

		if (rinku_isalnum(c))
			continue;

		if (strchr(".+-_%", c) != NULL)
			continue;

		break;
	}

	if (link->start == pos)
		return false;

	for (; link->end < size; link->end++) {
		uint8_t c = data[link->end];

		if (rinku_isalnum(c))
			continue;

		if (c == '@')
			nb++;
		else if (c == '.' && link->end < size - 1)
			np++;
		else if (c != '-' && c != '_')
			break;
	}

	if ((link->end - pos) < 2 || nb != 1 || np == 0 || (np == 1 && data[link->end - 1] == '.'))
		return false;

	return autolink_delim(data, link);
}

bool
autolink__url(
	struct autolink_pos *link,
	const uint8_t *data,
	size_t pos,
	size_t size,
	unsigned int flags)
{
	assert(data[pos] == ':');

	if ((size - pos) < 4 || data[pos + 1] != '/' || data[pos + 2] != '/')
		return false;

	link->start = pos + 3;
	link->end = 0;

	if (!check_domain(data, size, link, flags & AUTOLINK_SHORT_DOMAINS))
		return false;

	link->start = pos;
	link->end = utf8proc_find_space(data, link->end, size);

	while (link->start && rinku_isalpha(data[link->start - 1]))
		link->start--;

	if (!autolink_issafe(data + link->start, size - link->start))
		return false;

	return autolink_delim_iter(data, link);
}
