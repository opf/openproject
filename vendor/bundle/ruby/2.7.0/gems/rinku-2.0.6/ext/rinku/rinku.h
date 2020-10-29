#ifndef _RINKU_H
#define _RINKU_H

#include <stdint.h>
#include "buffer.h"

typedef enum {
	AUTOLINK_URLS = (1 << 0),
	AUTOLINK_EMAILS = (1 << 1),
	AUTOLINK_ALL = AUTOLINK_URLS|AUTOLINK_EMAILS
} autolink_mode;

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
	void *payload);
	
#endif
