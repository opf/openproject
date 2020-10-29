/*
 Copyright 2017-2018 Craig Barnes.
 Copyright 2010 Google Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"
#include "gumbo.h"

void* gumbo_alloc(size_t size) {
  void* ptr = malloc(size);
  if (unlikely(ptr == NULL)) {
    perror(__func__);
    abort();
  }
  return ptr;
}

void* gumbo_realloc(void* ptr, size_t size) {
  ptr = realloc(ptr, size);
  if (unlikely(ptr == NULL)) {
    perror(__func__);
    abort();
  }
  return ptr;
}

void gumbo_free(void* ptr) {
  free(ptr);
}

char* gumbo_strdup(const char* str) {
  const size_t size = strlen(str) + 1;
  // The strdup(3) function isn't available in strict "-std=c99" mode
  // (it's part of POSIX, not C99), so use malloc(3) and memcpy(3)
  // instead:
  char* buffer = gumbo_alloc(size);
  return memcpy(buffer, str, size);
}

#ifdef GUMBO_DEBUG
#include <stdarg.h>
// Debug function to trace operation of the parser
// (define GUMBO_DEBUG to use).
void gumbo_debug(const char* format, ...) {
  va_list args;
  va_start(args, format);
  vprintf(format, args);
  va_end(args);
  fflush(stdout);
}
#else
void gumbo_debug(const char* UNUSED_ARG(format), ...) {}
#endif
