/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/param.h>

#include "buffer.h"

/* Used as default value for gh_buf->ptr so that people can always
 * assume ptr is non-NULL and zero terminated even for new gh_bufs.
 */
char gh_buf__initbuf[1];
char gh_buf__oom[1];

#define ENSURE_SIZE(b, d) \
	if ((d) > buf->asize && gh_buf_grow(b, (d)) < 0)\
		return -1;

void gh_buf_init(gh_buf *buf, size_t initial_size)
{
	buf->asize = 0;
	buf->size = 0;
	buf->ptr = gh_buf__initbuf;

	if (initial_size)
		gh_buf_grow(buf, initial_size);
}

int gh_buf_try_grow(gh_buf *buf, size_t target_size, bool mark_oom)
{
	char *new_ptr;
	size_t new_size;

	if (buf->ptr == gh_buf__oom)
		return -1;

	if (target_size <= buf->asize)
		return 0;

	if (buf->asize == 0) {
		new_size = target_size;
		new_ptr = NULL;
	} else {
		new_size = buf->asize;
		new_ptr = buf->ptr;
	}

	/* grow the buffer size by 1.5, until it's big enough
	 * to fit our target size */
	while (new_size < target_size)
		new_size = (new_size << 1) - (new_size >> 1);

	/* round allocation up to multiple of 8 */
	new_size = (new_size + 7) & ~7;

	new_ptr = realloc(new_ptr, new_size);

	if (!new_ptr) {
		if (mark_oom)
			buf->ptr = gh_buf__oom;
		return -1;
	}

	buf->asize = new_size;
	buf->ptr   = new_ptr;

	/* truncate the existing buffer size if necessary */
	if (buf->size >= buf->asize)
		buf->size = buf->asize - 1;
	buf->ptr[buf->size] = '\0';

	return 0;
}

void gh_buf_free(gh_buf *buf)
{
	if (!buf) return;

	if (buf->ptr != gh_buf__initbuf && buf->ptr != gh_buf__oom)
		free(buf->ptr);

	gh_buf_init(buf, 0);
}

void gh_buf_clear(gh_buf *buf)
{
	buf->size = 0;
	if (buf->asize > 0)
		buf->ptr[0] = '\0';
}

int gh_buf_set(gh_buf *buf, const char *data, size_t len)
{
	if (len == 0 || data == NULL) {
		gh_buf_clear(buf);
	} else {
		if (data != buf->ptr) {
			ENSURE_SIZE(buf, len + 1);
			memmove(buf->ptr, data, len);
		}
		buf->size = len;
		buf->ptr[buf->size] = '\0';
	}
	return 0;
}

int gh_buf_sets(gh_buf *buf, const char *string)
{
	return gh_buf_set(buf, string, string ? strlen(string) : 0);
}

int gh_buf_putc(gh_buf *buf, char c)
{
	ENSURE_SIZE(buf, buf->size + 2);
	buf->ptr[buf->size++] = c;
	buf->ptr[buf->size] = '\0';
	return 0;
}

int gh_buf_put(gh_buf *buf, const void *data, size_t len)
{
	ENSURE_SIZE(buf, buf->size + len + 1);
	memmove(buf->ptr + buf->size, data, len);
	buf->size += len;
	buf->ptr[buf->size] = '\0';
	return 0;
}

int gh_buf_puts(gh_buf *buf, const char *string)
{
	assert(string);
	return gh_buf_put(buf, string, strlen(string));
}

int gh_buf_vprintf(gh_buf *buf, const char *format, va_list ap)
{
	int len;
	const size_t expected_size = buf->size + (strlen(format) * 2);

	ENSURE_SIZE(buf, expected_size);

	while (1) {
		va_list args;
		va_copy(args, ap);

		len = vsnprintf(
			buf->ptr + buf->size,
			buf->asize - buf->size,
			format, args
		);

		if (len < 0) {
			free(buf->ptr);
			buf->ptr = gh_buf__oom;
			return -1;
		}

		if ((size_t)len + 1 <= buf->asize - buf->size) {
			buf->size += len;
			break;
		}

		ENSURE_SIZE(buf, buf->size + len + 1);
	}

	return 0;
}

int gh_buf_printf(gh_buf *buf, const char *format, ...)
{
	int r;
	va_list ap;

	va_start(ap, format);
	r = gh_buf_vprintf(buf, format, ap);
	va_end(ap);

	return r;
}

void gh_buf_copy_cstr(char *data, size_t datasize, const gh_buf *buf)
{
	size_t copylen;

	assert(data && datasize && buf);

	data[0] = '\0';

	if (buf->size == 0 || buf->asize <= 0)
		return;

	copylen = buf->size;
	if (copylen > datasize - 1)
		copylen = datasize - 1;
	memmove(data, buf->ptr, copylen);
	data[copylen] = '\0';
}

void gh_buf_swap(gh_buf *buf_a, gh_buf *buf_b)
{
	gh_buf t = *buf_a;
	*buf_a = *buf_b;
	*buf_b = t;
}

char *gh_buf_detach(gh_buf *buf)
{
	char *data = buf->ptr;

	if (buf->asize == 0 || buf->ptr == gh_buf__oom)
		return NULL;

	gh_buf_init(buf, 0);

	return data;
}

void gh_buf_attach(gh_buf *buf, char *ptr, size_t asize)
{
	gh_buf_free(buf);

	if (ptr) {
		buf->ptr = ptr;
		buf->size = strlen(ptr);
		if (asize)
			buf->asize = (asize < buf->size) ? buf->size + 1 : asize;
		else /* pass 0 to fall back on strlen + 1 */
			buf->asize = buf->size + 1;
	} else {
		gh_buf_grow(buf, asize);
	}
}

int gh_buf_cmp(const gh_buf *a, const gh_buf *b)
{
	int result = memcmp(a->ptr, b->ptr, MIN(a->size, b->size));
	return (result != 0) ? result :
		(a->size < b->size) ? -1 : (a->size > b->size) ? 1 : 0;
}

