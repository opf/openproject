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
#ifndef RINKU_UTF8_H
#define RINKU_UTF8_H

#include <stdint.h>
#include <stdbool.h>

bool rinku_isspace(char c);
bool rinku_ispunct(char c);
bool rinku_isdigit(char c);
bool rinku_isalpha(char c);
bool rinku_isalnum(char c);

int32_t utf8proc_rewind(const uint8_t *data, size_t pos);
int32_t utf8proc_next(const uint8_t *str, size_t *pos);
int32_t utf8proc_back(const uint8_t *data, size_t *pos);
size_t utf8proc_find_space(const uint8_t *str, size_t pos, size_t size);

int32_t utf8proc_open_paren_character(int32_t cclose);
bool utf8proc_is_space(int32_t uc);
bool utf8proc_is_punctuation(int32_t uc);

#endif
