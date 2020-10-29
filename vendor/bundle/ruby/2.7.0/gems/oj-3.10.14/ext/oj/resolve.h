/* resolve.h
 * Copyright (c) 2011, Peter Ohler
 * All rights reserved.
 */

#ifndef OJ_RESOLVE_H
#define OJ_RESOLVE_H

#include "ruby.h"

extern VALUE	oj_name2class(ParseInfo pi, const char *name, size_t len, int auto_define, VALUE error_class);
extern VALUE	oj_name2struct(ParseInfo pi, VALUE nameVal, VALUE error_class);

#endif /* OJ_RESOLVE_H */
