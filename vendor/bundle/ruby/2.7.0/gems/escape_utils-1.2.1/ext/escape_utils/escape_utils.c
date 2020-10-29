// tell rbx not to use it's caching compat layer
// by doing this we're making a promise to RBX that
// we'll never modify the pointers we get back from RSTRING_PTR
#define RSTRING_NOT_MODIFIED

#include <ruby.h>
#include <ruby/encoding.h>
#include "houdini.h"

static VALUE rb_eEncodingCompatibilityError;

static VALUE eu_new_str(const char *str, size_t len)
{
	return rb_enc_str_new(str, len, rb_utf8_encoding());
}

static void check_utf8_encoding(VALUE str)
{
	static rb_encoding *_cached[3] = {NULL, NULL, NULL};
	rb_encoding *enc;

	if (_cached[0] == NULL) {
		_cached[0] = rb_utf8_encoding();
		_cached[1] = rb_usascii_encoding();
		_cached[2] = rb_ascii8bit_encoding();
	}

	enc = rb_enc_get(str);
	if (enc != _cached[0] && enc != _cached[1] && enc != _cached[2]) {
		rb_raise(rb_eEncodingCompatibilityError,
			"Input must be UTF-8 or US-ASCII, %s given", rb_enc_name(enc));
	}
}

typedef int (*houdini_cb)(gh_buf *, const uint8_t *, size_t);

static VALUE rb_mEscapeUtils;
static ID ID_at_html_safe, ID_new;

/**
 * html_secure instance variable
 */
static int g_html_secure = 1;

static VALUE rb_eu_set_html_secure(VALUE self, VALUE val)
{
	g_html_secure = RTEST(val);
	rb_ivar_set(self, rb_intern("@html_secure"), val);
	return val;
}

/**
* html_safe_string_class instance variable
*/
static VALUE rb_html_safe_string_class;
static VALUE rb_html_safe_string_template_object;

static VALUE rb_eu_set_html_safe_string_class(VALUE self, VALUE val)
{
	Check_Type(val, T_CLASS);

	if (rb_funcall(val, rb_intern("<="), 1, rb_cString) == Qnil)
		rb_raise(rb_eArgError, "%s must be a descendent of String", rb_class2name(val));

	rb_html_safe_string_class = val;
	rb_html_safe_string_template_object = rb_class_new_instance(0, NULL, rb_html_safe_string_class);
	OBJ_FREEZE(rb_html_safe_string_template_object);
	rb_ivar_set(self, rb_intern("@html_safe_string_class"), val);
	return val;
}

/**
 * Generic template
 */
static VALUE
rb_eu__generic(VALUE str, houdini_cb do_escape)
{
	gh_buf buf = GH_BUF_INIT;

	if (NIL_P(str))
		return eu_new_str("", 0);

	Check_Type(str, T_STRING);
	check_utf8_encoding(str);

	if (do_escape(&buf, (const uint8_t *)RSTRING_PTR(str), RSTRING_LEN(str))) {
		VALUE result = eu_new_str(buf.ptr, buf.size);
		gh_buf_free(&buf);
		return result;
	}

	return str;
}


/**
 * HTML methods
 */
static VALUE new_html_safe_string(const char *ptr, size_t len)
{
	return rb_str_new_with_class(rb_html_safe_string_template_object, ptr, len);
}

static VALUE rb_eu_escape_html_as_html_safe(VALUE self, VALUE str)
{
	VALUE result;
	int secure = g_html_secure;
	gh_buf buf = GH_BUF_INIT;

	Check_Type(str, T_STRING);
	check_utf8_encoding(str);

	if (houdini_escape_html0(&buf, (const uint8_t *)RSTRING_PTR(str), RSTRING_LEN(str), secure)) {
		result = new_html_safe_string(buf.ptr, buf.size);
		gh_buf_free(&buf);
	} else {
		result = new_html_safe_string(RSTRING_PTR(str), RSTRING_LEN(str));
	}

	rb_ivar_set(result, ID_at_html_safe, Qtrue);
	rb_enc_associate(result, rb_enc_get(str));

	return result;
}

static VALUE rb_eu_escape_html(int argc, VALUE *argv, VALUE self)
{
	VALUE str, rb_secure;
	gh_buf buf = GH_BUF_INIT;
	int secure = g_html_secure;

	if (rb_scan_args(argc, argv, "11", &str, &rb_secure) == 2) {
		if (rb_secure == Qfalse) {
			secure = 0;
		}
	}

	Check_Type(str, T_STRING);
	check_utf8_encoding(str);

	if (houdini_escape_html0(&buf, (const uint8_t *)RSTRING_PTR(str), RSTRING_LEN(str), secure)) {
		VALUE result = eu_new_str(buf.ptr, buf.size);
		gh_buf_free(&buf);
		return result;
	}

	return str;
}

static VALUE rb_eu_unescape_html(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_unescape_html);
}


/**
 * XML methods
 */
static VALUE rb_eu_escape_xml(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_escape_xml);
}


/**
 * JavaScript methods
 */
static VALUE rb_eu_escape_js(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_escape_js);
}

static VALUE rb_eu_unescape_js(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_unescape_js);
}


/**
 * URL methods
 */
static VALUE rb_eu_escape_url(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_escape_url);
}

static VALUE rb_eu_unescape_url(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_unescape_url);
}


/**
 * URI methods
 */
static VALUE rb_eu_escape_uri(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_escape_uri);
}

static VALUE rb_eu_unescape_uri(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_unescape_uri);
}

/**
 * URI component methods
 */
static VALUE rb_eu_escape_uri_component(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_escape_uri_component);
}

static VALUE rb_eu_unescape_uri_component(VALUE self, VALUE str)
{
	return rb_eu__generic(str, &houdini_unescape_uri_component);
}


/**
 * Ruby Extension initializer
 */
__attribute__((visibility("default")))
void Init_escape_utils()
{
	rb_eEncodingCompatibilityError = rb_const_get(rb_cEncoding, rb_intern("CompatibilityError"));

	ID_new = rb_intern("new");
	ID_at_html_safe = rb_intern("@html_safe");
	rb_global_variable(&rb_html_safe_string_class);
	rb_global_variable(&rb_html_safe_string_template_object);

	rb_mEscapeUtils = rb_define_module("EscapeUtils");
	rb_define_method(rb_mEscapeUtils, "escape_html_as_html_safe", rb_eu_escape_html_as_html_safe, 1);
	rb_define_method(rb_mEscapeUtils, "escape_html", rb_eu_escape_html, -1);
	rb_define_method(rb_mEscapeUtils, "unescape_html", rb_eu_unescape_html, 1);
	rb_define_method(rb_mEscapeUtils, "escape_xml", rb_eu_escape_xml, 1);
	rb_define_method(rb_mEscapeUtils, "escape_javascript", rb_eu_escape_js, 1);
	rb_define_method(rb_mEscapeUtils, "unescape_javascript", rb_eu_unescape_js, 1);
	rb_define_method(rb_mEscapeUtils, "escape_url", rb_eu_escape_url, 1);
	rb_define_method(rb_mEscapeUtils, "unescape_url", rb_eu_unescape_url, 1);
	rb_define_method(rb_mEscapeUtils, "escape_uri", rb_eu_escape_uri, 1);
	rb_define_method(rb_mEscapeUtils, "unescape_uri", rb_eu_unescape_uri, 1);
	rb_define_method(rb_mEscapeUtils, "escape_uri_component", rb_eu_escape_uri_component, 1);
	rb_define_method(rb_mEscapeUtils, "unescape_uri_component", rb_eu_unescape_uri_component, 1);

	rb_define_singleton_method(rb_mEscapeUtils, "html_secure=", rb_eu_set_html_secure, 1);
	rb_define_singleton_method(rb_mEscapeUtils, "html_safe_string_class=", rb_eu_set_html_safe_string_class, 1);
}

