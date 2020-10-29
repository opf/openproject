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

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "attribute.h"
#include "ascii.h"
#include "util.h"

GumboAttribute* gumbo_get_attribute (
  const GumboVector* attributes,
  const char* name
) {
  for (unsigned int i = 0; i < attributes->length; ++i) {
    GumboAttribute* attr = attributes->data[i];
    if (!gumbo_ascii_strcasecmp(attr->name, name)) {
      return attr;
    }
  }
  return NULL;
}

void gumbo_destroy_attribute(GumboAttribute* attribute) {
  gumbo_free((void*) attribute->name);
  gumbo_free((void*) attribute->value);
  gumbo_free((void*) attribute);
}
