/*
 Copyright 2018 Craig Barnes.
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

#include <stddef.h>
#include <string.h>
#include "gumbo.h"
#include "ascii.h"

bool gumbo_string_equals (
  const GumboStringPiece* str1,
  const GumboStringPiece* str2
) {
  return
    str1->length == str2->length
    && !memcmp(str1->data, str2->data, str1->length);
}

bool gumbo_string_equals_ignore_case (
  const GumboStringPiece* str1,
  const GumboStringPiece* str2
) {
  return
    str1->length == str2->length
    && !gumbo_ascii_strncasecmp(str1->data, str2->data, str1->length);
}

bool gumbo_string_prefix_ignore_case (
  const GumboStringPiece* prefix,
  const GumboStringPiece* str
) {
  return
    prefix->length <= str->length
    && !gumbo_ascii_strncasecmp(prefix->data, str->data, prefix->length);
}
