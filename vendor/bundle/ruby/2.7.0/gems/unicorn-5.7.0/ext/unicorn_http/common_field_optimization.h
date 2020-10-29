#ifndef common_field_optimization
#define common_field_optimization
#include "ruby.h"
#include "c_util.h"

struct common_field {
  const signed long len;
  const char *name;
  VALUE value;
};

/*
 * A list of common HTTP headers we expect to receive.
 * This allows us to avoid repeatedly creating identical string
 * objects to be used with rb_hash_aset().
 */
static struct common_field common_http_fields[] = {
# define f(N) { (sizeof(N) - 1), N, Qnil }
  f("ACCEPT"),
  f("ACCEPT_CHARSET"),
  f("ACCEPT_ENCODING"),
  f("ACCEPT_LANGUAGE"),
  f("ALLOW"),
  f("AUTHORIZATION"),
  f("CACHE_CONTROL"),
  f("CONNECTION"),
  f("CONTENT_ENCODING"),
  f("CONTENT_LENGTH"),
  f("CONTENT_TYPE"),
  f("COOKIE"),
  f("DATE"),
  f("EXPECT"),
  f("FROM"),
  f("HOST"),
  f("IF_MATCH"),
  f("IF_MODIFIED_SINCE"),
  f("IF_NONE_MATCH"),
  f("IF_RANGE"),
  f("IF_UNMODIFIED_SINCE"),
  f("KEEP_ALIVE"), /* Firefox sends this */
  f("MAX_FORWARDS"),
  f("PRAGMA"),
  f("PROXY_AUTHORIZATION"),
  f("RANGE"),
  f("REFERER"),
  f("TE"),
  f("TRAILER"),
  f("TRANSFER_ENCODING"),
  f("UPGRADE"),
  f("USER_AGENT"),
  f("VIA"),
  f("X_FORWARDED_FOR"), /* common for proxies */
  f("X_FORWARDED_PROTO"), /* common for proxies */
  f("X_REAL_IP"), /* common for proxies */
  f("WARNING")
# undef f
};

#define HTTP_PREFIX "HTTP_"
#define HTTP_PREFIX_LEN (sizeof(HTTP_PREFIX) - 1)
static ID id_uminus;

/* this dedupes under Ruby 2.5+ (December 2017) */
static VALUE str_dd_freeze(VALUE str)
{
  if (STR_UMINUS_DEDUPE)
    return rb_funcall(str, id_uminus, 0);

  /* freeze,since it speeds up older MRI slightly */
  OBJ_FREEZE(str);
  return str;
}

static VALUE str_new_dd_freeze(const char *ptr, long len)
{
  return str_dd_freeze(rb_str_new(ptr, len));
}

/* this function is not performance-critical, called only at load time */
static void init_common_fields(void)
{
  int i;
  struct common_field *cf = common_http_fields;
  char tmp[64];

  id_uminus = rb_intern("-@");
  memcpy(tmp, HTTP_PREFIX, HTTP_PREFIX_LEN);

  for(i = ARRAY_SIZE(common_http_fields); --i >= 0; cf++) {
    /* Rack doesn't like certain headers prefixed with "HTTP_" */
    if (!strcmp("CONTENT_LENGTH", cf->name) ||
        !strcmp("CONTENT_TYPE", cf->name)) {
      cf->value = str_new_dd_freeze(cf->name, cf->len);
    } else {
      memcpy(tmp + HTTP_PREFIX_LEN, cf->name, cf->len + 1);
      cf->value = str_new_dd_freeze(tmp, HTTP_PREFIX_LEN + cf->len);
    }
    rb_gc_register_mark_object(cf->value);
  }
}

/* this function is called for every header set */
static VALUE find_common_field(const char *field, size_t flen)
{
  int i;
  struct common_field *cf = common_http_fields;

  for(i = ARRAY_SIZE(common_http_fields); --i >= 0; cf++) {
    if (cf->len == (long)flen && !memcmp(cf->name, field, flen))
      return cf->value;
  }
  return Qnil;
}

/*
 * We got a strange header that we don't have a memoized value for.
 * Fallback to creating a new string to use as a hash key.
 */
static VALUE uncommon_field(const char *field, size_t flen)
{
  VALUE f = rb_str_new(NULL, HTTP_PREFIX_LEN + flen);
  memcpy(RSTRING_PTR(f), HTTP_PREFIX, HTTP_PREFIX_LEN);
  memcpy(RSTRING_PTR(f) + HTTP_PREFIX_LEN, field, flen);
  assert(*(RSTRING_PTR(f) + RSTRING_LEN(f)) == '\0' &&
         "string didn't end with \\0"); /* paranoia */
  return HASH_ASET_DEDUPE ? f : str_dd_freeze(f);
}

#endif /* common_field_optimization_h */
