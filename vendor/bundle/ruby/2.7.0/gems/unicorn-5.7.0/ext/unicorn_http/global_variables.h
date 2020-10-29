#ifndef global_variables_h
#define global_variables_h
static VALUE eHttpParserError;
static VALUE e413;
static VALUE e414;

static VALUE g_rack_url_scheme;
static VALUE g_request_method;
static VALUE g_request_uri;
static VALUE g_fragment;
static VALUE g_query_string;
static VALUE g_http_version;
static VALUE g_request_path;
static VALUE g_path_info;
static VALUE g_server_name;
static VALUE g_server_port;
static VALUE g_server_protocol;
static VALUE g_http_host;
static VALUE g_http_x_forwarded_proto;
static VALUE g_http_x_forwarded_ssl;
static VALUE g_http_transfer_encoding;
static VALUE g_content_length;
static VALUE g_http_trailer;
static VALUE g_http_connection;
static VALUE g_port_80;
static VALUE g_port_443;
static VALUE g_localhost;
static VALUE g_http;
static VALUE g_https;
static VALUE g_http_09;
static VALUE g_http_10;
static VALUE g_http_11;

/** Defines common length and error messages for input length validation. */
#define DEF_MAX_LENGTH(N, length) \
  static const size_t MAX_##N##_LENGTH = length; \
  static const char * const MAX_##N##_LENGTH_ERR = \
    "HTTP element " # N  " is longer than the " # length " allowed length."

NORETURN(static void parser_raise(VALUE klass, const char *));

/**
 * Validates the max length of given input and throws an HttpParserError
 * exception if over.
 */
#define VALIDATE_MAX_LENGTH(len, N) do { \
  if (len > MAX_##N##_LENGTH) \
    parser_raise(eHttpParserError, MAX_##N##_LENGTH_ERR); \
} while (0)

#define VALIDATE_MAX_URI_LENGTH(len, N) do { \
  if (len > MAX_##N##_LENGTH) \
    parser_raise(e414, MAX_##N##_LENGTH_ERR); \
} while (0)

/** Defines global strings in the init method. */
#define DEF_GLOBAL(N, val) do { \
  g_##N = rb_obj_freeze(rb_str_new(val, sizeof(val) - 1)); \
  rb_gc_register_mark_object(g_##N); \
} while (0)

/* Defines the maximum allowed lengths for various input elements.*/
DEF_MAX_LENGTH(FIELD_NAME, 256);
DEF_MAX_LENGTH(FIELD_VALUE, 80 * 1024);
DEF_MAX_LENGTH(REQUEST_URI, 1024 * 15);
DEF_MAX_LENGTH(FRAGMENT, 1024); /* Don't know if this length is specified somewhere or not */
DEF_MAX_LENGTH(REQUEST_PATH, 4096); /* common PATH_MAX on modern systems */
DEF_MAX_LENGTH(QUERY_STRING, (1024 * 10));

static void init_globals(void)
{
  DEF_GLOBAL(rack_url_scheme, "rack.url_scheme");
  DEF_GLOBAL(request_method, "REQUEST_METHOD");
  DEF_GLOBAL(request_uri, "REQUEST_URI");
  DEF_GLOBAL(fragment, "FRAGMENT");
  DEF_GLOBAL(query_string, "QUERY_STRING");
  DEF_GLOBAL(http_version, "HTTP_VERSION");
  DEF_GLOBAL(request_path, "REQUEST_PATH");
  DEF_GLOBAL(path_info, "PATH_INFO");
  DEF_GLOBAL(server_name, "SERVER_NAME");
  DEF_GLOBAL(server_port, "SERVER_PORT");
  DEF_GLOBAL(server_protocol, "SERVER_PROTOCOL");
  DEF_GLOBAL(http_x_forwarded_proto, "HTTP_X_FORWARDED_PROTO");
  DEF_GLOBAL(http_x_forwarded_ssl, "HTTP_X_FORWARDED_SSL");
  DEF_GLOBAL(port_80, "80");
  DEF_GLOBAL(port_443, "443");
  DEF_GLOBAL(localhost, "localhost");
  DEF_GLOBAL(http, "http");
  DEF_GLOBAL(https, "https");
  DEF_GLOBAL(http_11, "HTTP/1.1");
  DEF_GLOBAL(http_10, "HTTP/1.0");
  DEF_GLOBAL(http_09, "HTTP/0.9");
}

#undef DEF_GLOBAL

#endif /* global_variables_h */
