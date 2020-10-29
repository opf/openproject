//
// nokogumbo.c defines the following:
//
//   class Nokogumbo
//     def parse(utf8_string) # returns Nokogiri::HTML5::Document
//   end
//
// Processing starts by calling gumbo_parse_with_options.  The resulting
// document tree is then walked:
//
//  * if Nokogiri and libxml2 headers are available at compile time,
//    (if NGLIB) then a parallel libxml2 tree is constructed, and the
//    final document is then wrapped using Nokogiri_wrap_xml_document.
//    This approach reduces memory and CPU requirements as Ruby objects
//    are only built when necessary.
//
//  * if the necessary headers are not available at compile time, Nokogiri
//    methods are called instead, producing the equivalent functionality.
//

#include <assert.h>
#include <ruby.h>
#include <ruby/version.h>

#include "gumbo.h"

// class constants
static VALUE Document;

// Interned symbols
static ID internal_subset;
static ID parent;

/* Backwards compatibility to Ruby 2.1.0 */
#if RUBY_API_VERSION_CODE < 20200
#define ONIG_ESCAPE_UCHAR_COLLISION 1
#include <ruby/encoding.h>

static VALUE rb_utf8_str_new(const char *str, long length) {
  return rb_enc_str_new(str, length, rb_utf8_encoding());
}

static VALUE rb_utf8_str_new_cstr(const char *str) {
  return rb_enc_str_new_cstr(str, rb_utf8_encoding());
}

static VALUE rb_utf8_str_new_static(const char *str, long length) {
  return rb_enc_str_new(str, length, rb_utf8_encoding());
}
#endif

#if NGLIB
#include <nokogiri.h>
#include <libxml/tree.h>
#include <libxml/HTMLtree.h>

#define NIL NULL
#else
#define NIL Qnil

// These are defined by nokogiri.h
static VALUE cNokogiriXmlSyntaxError;
static VALUE cNokogiriXmlElement;
static VALUE cNokogiriXmlText;
static VALUE cNokogiriXmlCData;
static VALUE cNokogiriXmlComment;

// Interned symbols.
static ID new;
static ID node_name_;

// Map libxml2 types to Ruby VALUE.
typedef VALUE xmlNodePtr;
typedef VALUE xmlDocPtr;
typedef VALUE xmlNsPtr;
typedef VALUE xmlDtdPtr;
typedef char xmlChar;
#define BAD_CAST

// Redefine libxml2 API as Ruby function calls.
static xmlNodePtr xmlNewDocNode(xmlDocPtr doc, xmlNsPtr ns, const xmlChar *name, const xmlChar *content) {
  assert(ns == NIL && content == NULL);
  return rb_funcall(cNokogiriXmlElement, new, 2, rb_utf8_str_new_cstr(name), doc);
}

static xmlNodePtr xmlNewDocText(xmlDocPtr doc, const xmlChar *content) {
  VALUE str = rb_utf8_str_new_cstr(content);
  return rb_funcall(cNokogiriXmlText, new, 2, str, doc);
}

static xmlNodePtr xmlNewCDataBlock(xmlDocPtr doc, const xmlChar *content, int len) {
  VALUE str = rb_utf8_str_new(content, len);
  // CDATA.new takes arguments in the opposite order from Text.new.
  return rb_funcall(cNokogiriXmlCData, new, 2, doc, str);
}

static xmlNodePtr xmlNewDocComment(xmlDocPtr doc, const xmlChar *content) {
  VALUE str = rb_utf8_str_new_cstr(content);
  return rb_funcall(cNokogiriXmlComment, new, 2, doc, str);
}

static xmlNodePtr xmlAddChild(xmlNodePtr parent, xmlNodePtr cur) {
  ID add_child;
  CONST_ID(add_child, "add_child");
  return rb_funcall(parent, add_child, 1, cur);
}

static void xmlSetNs(xmlNodePtr node, xmlNsPtr ns) {
  ID namespace_;
  CONST_ID(namespace_, "namespace=");
  rb_funcall(node, namespace_, 1, ns);
}

static void xmlFreeDoc(xmlDocPtr doc) { }

static VALUE Nokogiri_wrap_xml_document(VALUE klass, xmlDocPtr doc) {
  return doc;
}

static VALUE find_dummy_key(VALUE collection) {
  VALUE r_dummy = Qnil;
  char dummy[5] = "a";
  size_t len = 1;
  ID key_;
  CONST_ID(key_, "key?");
  while (len < sizeof dummy) {
    r_dummy = rb_utf8_str_new(dummy, len);
    if (rb_funcall(collection, key_, 1, r_dummy) == Qfalse)
      return r_dummy;
    for (size_t i = 0; ; ++i) {
      if (dummy[i] == 0) {
        dummy[i] = 'a';
        ++len;
        break;
      }
      if (dummy[i] == 'z')
        dummy[i] = 'a';
      else {
        ++dummy[i];
        break;
      }
    }
  }
  // This collection has 475254 elements?? Give up.
  rb_raise(rb_eArgError, "Failed to find a dummy key.");
}

// This should return an xmlAttrPtr, but we don't need it and it's easier to
// not get the result.
static void xmlNewNsProp (
  xmlNodePtr node,
  xmlNsPtr ns,
  const xmlChar *name,
  const xmlChar *value
) {
  ID set_attribute;
  CONST_ID(set_attribute, "set_attribute");

  VALUE rvalue = rb_utf8_str_new_cstr(value);

  if (RTEST(ns)) {
    // This is an easy case, we have a namespace so it's enough to do
    // node["#{ns.prefix}:#{name}"] = value
    ID prefix;
    CONST_ID(prefix, "prefix");
    VALUE ns_prefix = rb_funcall(ns, prefix, 0);
    VALUE qname = rb_sprintf("%" PRIsVALUE ":%s", ns_prefix, name);
    rb_funcall(node, set_attribute, 2, qname, rvalue);
    return;
  }

  size_t len = strlen(name);
  VALUE rname = rb_utf8_str_new(name, len);
  if (memchr(name, ':', len) == NULL) {
    // This is the easiest case. There's no colon so we can do
    // node[name] = value.
    rb_funcall(node, set_attribute, 2, rname, rvalue);
    return;
  }

  // Nokogiri::XML::Node#set_attribute calls xmlSetProp(node, name, value)
  // which behaves roughly as
  // if name is a QName prefix:local
  //   if node->doc has a namespace ns corresponding to prefix
  //     return xmlSetNsProp(node, ns, local, value)
  // return xmlSetNsProp(node, NULL, name, value)
  //
  // If the prefix is "xml", then the namespace lookup will create it.
  //
  // By contrast, xmlNewNsProp does not do this parsing and creates an attribute
  // with the name and value exactly as given. This is the behavior that we
  // want.
  //
  // Thus, for attribute names like "xml:lang", #set_attribute will create an
  // attribute with namespace "xml" and name "lang". This is incorrect for
  // html elements (but correct for foreign elements).
  //
  // Work around this by inserting a dummy attribute and then changing the
  // name, if needed.

  // Find a dummy attribute string that doesn't already exist.
  VALUE dummy = find_dummy_key(node);
  // Add the dummy attribute.
  rb_funcall(node, set_attribute, 2, dummy, rvalue);

  // Remove the old attribute, if it exists.
  ID remove_attribute;
  CONST_ID(remove_attribute, "remove_attribute");
  rb_funcall(node, remove_attribute, 1, rname);

  // Rename the dummy
  ID attribute;
  CONST_ID(attribute, "attribute");
  VALUE attr = rb_funcall(node, attribute, 1, dummy);
  rb_funcall(attr, node_name_, 1, rname);
}
#endif

// URI = system id
// external id = public id
static xmlDocPtr new_html_doc(const char *dtd_name, const char *system, const char *public)
{
#if NGLIB
  // These two libxml2 functions take the public and system ids in
  // opposite orders.
  htmlDocPtr doc = htmlNewDocNoDtD(/* URI */ NULL, /* ExternalID */NULL);
  assert(doc);
  if (dtd_name)
    xmlCreateIntSubset(doc, BAD_CAST dtd_name, BAD_CAST public, BAD_CAST system);
  return doc;
#else
  // remove internal subset from newly created documents
  VALUE doc;
  // If system and public are both NULL, Document#new is going to set default
  // values for them so we're going to have to remove the internal subset
  // which seems to leak memory in Nokogiri, so leak as little as possible.
  if (system == NULL && public == NULL) {
    ID remove;
    CONST_ID(remove, "remove");
    doc = rb_funcall(Document, new, 2, /* URI */ Qnil, /* external_id */ rb_utf8_str_new_static("", 0));
    rb_funcall(rb_funcall(doc, internal_subset, 0), remove, 0);
    if (dtd_name) {
      // We need to create an internal subset now.
      ID create_internal_subset;
      CONST_ID(create_internal_subset, "create_internal_subset");
      rb_funcall(doc, create_internal_subset, 3, rb_utf8_str_new_cstr(dtd_name), Qnil, Qnil);
    }
  } else {
    assert(dtd_name);
    // Rather than removing and creating the internal subset as we did above,
    // just create and then rename one.
    VALUE r_system = system ? rb_utf8_str_new_cstr(system) : Qnil;
    VALUE r_public = public ? rb_utf8_str_new_cstr(public) : Qnil;
    doc = rb_funcall(Document, new, 2, r_system, r_public);
    rb_funcall(rb_funcall(doc, internal_subset, 0), node_name_, 1, rb_utf8_str_new_cstr(dtd_name));
  }
  return doc;
#endif
}

static xmlNodePtr get_parent(xmlNodePtr node) {
#if NGLIB
  return node->parent;
#else
  if (!rb_respond_to(node, parent))
    return Qnil;
  return rb_funcall(node, parent, 0);
#endif
}

static GumboOutput *perform_parse(const GumboOptions *options, VALUE input) {
  assert(RTEST(input));
  Check_Type(input, T_STRING);
  GumboOutput *output = gumbo_parse_with_options (
    options,
    RSTRING_PTR(input),
    RSTRING_LEN(input)
  );

  const char *status_string = gumbo_status_to_string(output->status);
  switch (output->status) {
  case GUMBO_STATUS_OK:
    break;
  case GUMBO_STATUS_TREE_TOO_DEEP:
    gumbo_destroy_output(output);
    rb_raise(rb_eArgError, "%s", status_string);
  case GUMBO_STATUS_OUT_OF_MEMORY:
    gumbo_destroy_output(output);
    rb_raise(rb_eNoMemError, "%s", status_string);
  }
  return output;
}

static xmlNsPtr lookup_or_add_ns (
  xmlDocPtr doc,
  xmlNodePtr root,
  const char *href,
  const char *prefix
) {
#if NGLIB
  xmlNsPtr ns = xmlSearchNs(doc, root, BAD_CAST prefix);
  if (ns)
    return ns;
  return xmlNewNs(root, BAD_CAST href, BAD_CAST prefix);
#else
  ID add_namespace_definition;
  CONST_ID(add_namespace_definition, "add_namespace_definition");
  VALUE rprefix = rb_utf8_str_new_cstr(prefix);
  VALUE rhref = rb_utf8_str_new_cstr(href);
  return rb_funcall(root, add_namespace_definition, 2, rprefix, rhref);
#endif
}

static void set_line(xmlNodePtr node, size_t line) {
#if NGLIB
  // libxml2 uses 65535 to mean look elsewhere for the line number on some
  // nodes.
  if (line < 65535)
    node->line = (unsigned short)line;
#else
  // XXX: If Nokogiri gets a `#line=` method, we'll use that.
#endif
}

// Construct an XML tree rooted at xml_output_node from the Gumbo tree rooted
// at gumbo_node.
static void build_tree (
  xmlDocPtr doc,
  xmlNodePtr xml_output_node,
  const GumboNode *gumbo_node
) {
  xmlNodePtr xml_root = NIL;
  xmlNodePtr xml_node = xml_output_node;
  size_t child_index = 0;

  while (true) {
    assert(gumbo_node != NULL);
    const GumboVector *children = gumbo_node->type == GUMBO_NODE_DOCUMENT?
      &gumbo_node->v.document.children : &gumbo_node->v.element.children;
    if (child_index >= children->length) {
      // Move up the tree and to the next child.
      if (xml_node == xml_output_node) {
        // We've built as much of the tree as we can.
        return;
      }
      child_index = gumbo_node->index_within_parent + 1;
      gumbo_node = gumbo_node->parent;
      xml_node = get_parent(xml_node);
      // Children of fragments don't share the same root, so reset it and
      // it'll be set below. In the non-fragment case, this will only happen
      // after the html element has been finished at which point there are no
      // further elements.
      if (xml_node == xml_output_node)
        xml_root = NIL;
      continue;
    }
    const GumboNode *gumbo_child = children->data[child_index++];
    xmlNodePtr xml_child;

    switch (gumbo_child->type) {
      case GUMBO_NODE_DOCUMENT:
        abort(); // Bug in Gumbo.

      case GUMBO_NODE_TEXT:
      case GUMBO_NODE_WHITESPACE:
        xml_child = xmlNewDocText(doc, BAD_CAST gumbo_child->v.text.text);
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_CDATA:
        xml_child = xmlNewCDataBlock(doc, BAD_CAST gumbo_child->v.text.text,
                                     (int) strlen(gumbo_child->v.text.text));
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_COMMENT:
        xml_child = xmlNewDocComment(doc, BAD_CAST gumbo_child->v.text.text);
        set_line(xml_child, gumbo_child->v.text.start_pos.line);
        xmlAddChild(xml_node, xml_child);
        break;

      case GUMBO_NODE_TEMPLATE:
        // XXX: Should create a template element and a new DocumentFragment
      case GUMBO_NODE_ELEMENT:
      {
        xml_child = xmlNewDocNode(doc, NIL, BAD_CAST gumbo_child->v.element.name, NULL);
        set_line(xml_child, gumbo_child->v.element.start_pos.line);
        if (xml_root == NIL)
          xml_root = xml_child;
        xmlNsPtr ns = NIL;
        switch (gumbo_child->v.element.tag_namespace) {
        case GUMBO_NAMESPACE_HTML:
          break;
        case GUMBO_NAMESPACE_SVG:
          ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/2000/svg", "svg");
          break;
        case GUMBO_NAMESPACE_MATHML:
          ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/1998/Math/MathML", "math");
          break;
        }
        if (ns != NIL)
          xmlSetNs(xml_child, ns);
        xmlAddChild(xml_node, xml_child);

        // Add the attributes.
        const GumboVector* attrs = &gumbo_child->v.element.attributes;
        for (size_t i=0; i < attrs->length; i++) {
          const GumboAttribute *attr = attrs->data[i];

          switch (attr->attr_namespace) {
            case GUMBO_ATTR_NAMESPACE_XLINK:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/1999/xlink", "xlink");
              break;

            case GUMBO_ATTR_NAMESPACE_XML:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/XML/1998/namespace", "xml");
              break;

            case GUMBO_ATTR_NAMESPACE_XMLNS:
              ns = lookup_or_add_ns(doc, xml_root, "http://www.w3.org/2000/xmlns/", "xmlns");
              break;

            default:
              ns = NIL;
          }
          xmlNewNsProp(xml_child, ns, BAD_CAST attr->name, BAD_CAST attr->value);
        }

        // Add children for this element.
        child_index = 0;
        gumbo_node = gumbo_child;
        xml_node = xml_child;
      }
    }
  }
}

static void add_errors(const GumboOutput *output, VALUE rdoc, VALUE input, VALUE url) {
  const char *input_str = RSTRING_PTR(input);
  size_t input_len = RSTRING_LEN(input);

  // Add parse errors to rdoc.
  if (output->errors.length) {
    const GumboVector *errors = &output->errors;
    VALUE rerrors = rb_ary_new2(errors->length);

    for (size_t i=0; i < errors->length; i++) {
      GumboError *err = errors->data[i];
      GumboSourcePosition position = gumbo_error_position(err);
      char *msg;
      size_t size = gumbo_caret_diagnostic_to_string(err, input_str, input_len, &msg);
      VALUE err_str = rb_utf8_str_new(msg, size);
      free(msg);
      VALUE syntax_error = rb_class_new_instance(1, &err_str, cNokogiriXmlSyntaxError);
      const char *error_code = gumbo_error_code(err);
      VALUE str1 = error_code? rb_utf8_str_new_static(error_code, strlen(error_code)) : Qnil;
      rb_iv_set(syntax_error, "@domain", INT2NUM(1)); // XML_FROM_PARSER
      rb_iv_set(syntax_error, "@code", INT2NUM(1));   // XML_ERR_INTERNAL_ERROR
      rb_iv_set(syntax_error, "@level", INT2NUM(2));  // XML_ERR_ERROR
      rb_iv_set(syntax_error, "@file", url);
      rb_iv_set(syntax_error, "@line", INT2NUM(position.line));
      rb_iv_set(syntax_error, "@str1", str1);
      rb_iv_set(syntax_error, "@str2", Qnil);
      rb_iv_set(syntax_error, "@str3", Qnil);
      rb_iv_set(syntax_error, "@int1", INT2NUM(0));
      rb_iv_set(syntax_error, "@column", INT2NUM(position.column));
      rb_ary_push(rerrors, syntax_error);
    }
    rb_iv_set(rdoc, "@errors", rerrors);
  }
}

typedef struct {
  GumboOutput *output;
  VALUE input;
  VALUE url_or_frag;
  xmlDocPtr doc;
} ParseArgs;

static VALUE parse_cleanup(ParseArgs *args) {
  gumbo_destroy_output(args->output);
  if (args->doc != NIL)
    xmlFreeDoc(args->doc);
  return Qnil;
}


static VALUE parse_continue(ParseArgs *args);

// Parse a string using gumbo_parse into a Nokogiri document
static VALUE parse(VALUE self, VALUE input, VALUE url, VALUE max_errors, VALUE max_depth) {
  GumboOptions options = kGumboDefaultOptions;
  options.max_errors = NUM2INT(max_errors);
  options.max_tree_depth = NUM2INT(max_depth);

  GumboOutput *output = perform_parse(&options, input);
  ParseArgs args = {
    .output = output,
    .input = input,
    .url_or_frag = url,
    .doc = NIL,
  };
  return rb_ensure(parse_continue, (VALUE)&args, parse_cleanup, (VALUE)&args);
}

static VALUE parse_continue(ParseArgs *args) {
  GumboOutput *output = args->output;
  xmlDocPtr doc;
  if (output->document->v.document.has_doctype) {
    const char *name   = output->document->v.document.name;
    const char *public = output->document->v.document.public_identifier;
    const char *system = output->document->v.document.system_identifier;
    public = public[0] ? public : NULL;
    system = system[0] ? system : NULL;
    doc = new_html_doc(name, system, public);
  } else {
    doc = new_html_doc(NULL, NULL, NULL);
  }
  args->doc = doc; // Make sure doc gets cleaned up if an error is thrown.
  build_tree(doc, (xmlNodePtr)doc, output->document);
  VALUE rdoc = Nokogiri_wrap_xml_document(Document, doc);
  args->doc = NIL; // The Ruby runtime now owns doc so don't delete it.
  add_errors(output, rdoc, args->input, args->url_or_frag);
  return rdoc;
}

static int lookup_namespace(VALUE node, bool require_known_ns) {
  ID namespace, href;
  CONST_ID(namespace, "namespace");
  CONST_ID(href, "href");
  VALUE ns = rb_funcall(node, namespace, 0);

  if (NIL_P(ns))
    return GUMBO_NAMESPACE_HTML;
  ns = rb_funcall(ns, href, 0);
  assert(RTEST(ns));
  Check_Type(ns, T_STRING);

  const char *href_ptr = RSTRING_PTR(ns);
  size_t href_len = RSTRING_LEN(ns);
#define NAMESPACE_P(uri) (href_len == sizeof uri - 1 && !memcmp(href_ptr, uri, href_len))
  if (NAMESPACE_P("http://www.w3.org/1999/xhtml"))
    return GUMBO_NAMESPACE_HTML;
  if (NAMESPACE_P("http://www.w3.org/1998/Math/MathML"))
    return GUMBO_NAMESPACE_MATHML;
  if (NAMESPACE_P("http://www.w3.org/2000/svg"))
    return GUMBO_NAMESPACE_SVG;
#undef NAMESPACE_P
  if (require_known_ns)
    rb_raise(rb_eArgError, "Unexpected namespace URI \"%*s\"", (int)href_len, href_ptr);
  return -1;
}

static xmlNodePtr extract_xml_node(VALUE node) {
#if NGLIB
  xmlNodePtr xml_node;
  Data_Get_Struct(node, xmlNode, xml_node);
  return xml_node;
#else
  return node;
#endif
}

static VALUE fragment_continue(ParseArgs *args);

static VALUE fragment (
  VALUE self,
  VALUE doc_fragment,
  VALUE tags,
  VALUE ctx,
  VALUE max_errors,
  VALUE max_depth
) {
  ID name = rb_intern_const("name");
  const char *ctx_tag;
  GumboNamespaceEnum ctx_ns;
  GumboQuirksModeEnum quirks_mode;
  bool form = false;
  const char *encoding = NULL;

  if (NIL_P(ctx)) {
    ctx_tag = "body";
    ctx_ns = GUMBO_NAMESPACE_HTML;
  } else if (TYPE(ctx) == T_STRING) {
    ctx_tag = StringValueCStr(ctx);
    ctx_ns = GUMBO_NAMESPACE_HTML;
    size_t len = RSTRING_LEN(ctx);
    const char *colon = memchr(ctx_tag, ':', len);
    if (colon) {
      switch (colon - ctx_tag) {
      case 3:
        if (st_strncasecmp(ctx_tag, "svg", 3) != 0)
          goto error;
        ctx_ns = GUMBO_NAMESPACE_SVG;
        break;
      case 4:
        if (st_strncasecmp(ctx_tag, "html", 4) == 0)
          ctx_ns = GUMBO_NAMESPACE_HTML;
        else if (st_strncasecmp(ctx_tag, "math", 4) == 0)
          ctx_ns = GUMBO_NAMESPACE_MATHML;
        else
          goto error;
        break;
      default:
      error:
        rb_raise(rb_eArgError, "Invalid context namespace '%*s'", (int)(colon - ctx_tag), ctx_tag);
      }
      ctx_tag = colon+1;
    } else {
      // For convenience, put 'svg' and 'math' in their namespaces.
      if (len == 3 && st_strncasecmp(ctx_tag, "svg", 3) == 0)
        ctx_ns = GUMBO_NAMESPACE_SVG;
      else if (len == 4 && st_strncasecmp(ctx_tag, "math", 4) == 0)
        ctx_ns = GUMBO_NAMESPACE_MATHML;
    }

    // Check if it's a form.
    form = ctx_ns == GUMBO_NAMESPACE_HTML && st_strcasecmp(ctx_tag, "form") == 0;
  } else {
    ID element_ = rb_intern_const("element?");

    // Context fragment name.
    VALUE tag_name = rb_funcall(ctx, name, 0);
    assert(RTEST(tag_name));
    Check_Type(tag_name, T_STRING);
    ctx_tag = StringValueCStr(tag_name);

    // Context fragment namespace.
    ctx_ns = lookup_namespace(ctx, true);

    // Check for a form ancestor, including self.
    for (VALUE node = ctx;
         !NIL_P(node);
         node = rb_respond_to(node, parent) ? rb_funcall(node, parent, 0) : Qnil) {
      if (!RTEST(rb_funcall(node, element_, 0)))
        continue;
      VALUE element_name = rb_funcall(node, name, 0);
      if (RSTRING_LEN(element_name) == 4
          && !st_strcasecmp(RSTRING_PTR(element_name), "form")
          && lookup_namespace(node, false) == GUMBO_NAMESPACE_HTML) {
        form = true;
        break;
      }
    }

    // Encoding.
    if (RSTRING_LEN(tag_name) == 14
        && !st_strcasecmp(ctx_tag, "annotation-xml")) {
      VALUE enc = rb_funcall(ctx, rb_intern_const("[]"),
                             rb_utf8_str_new_static("encoding", 8));
      if (RTEST(enc)) {
        Check_Type(enc, T_STRING);
        encoding = StringValueCStr(enc);
      }
    }
  }

  // Quirks mode.
  VALUE doc = rb_funcall(doc_fragment, rb_intern_const("document"), 0);
  VALUE dtd = rb_funcall(doc, internal_subset, 0);
  if (NIL_P(dtd)) {
    quirks_mode = GUMBO_DOCTYPE_NO_QUIRKS;
  } else {
    VALUE dtd_name = rb_funcall(dtd, name, 0);
    VALUE pubid = rb_funcall(dtd, rb_intern_const("external_id"), 0);
    VALUE sysid = rb_funcall(dtd, rb_intern_const("system_id"), 0);
    quirks_mode = gumbo_compute_quirks_mode (
      NIL_P(dtd_name)? NULL:StringValueCStr(dtd_name),
      NIL_P(pubid)? NULL:StringValueCStr(pubid),
      NIL_P(sysid)? NULL:StringValueCStr(sysid)
    );
  }

  // Perform a fragment parse.
  int depth = NUM2INT(max_depth);
  GumboOptions options = kGumboDefaultOptions;
  options.max_errors = NUM2INT(max_errors);
  // Add one to account for the HTML element.
  options.max_tree_depth = depth < 0 ? -1 : (depth + 1);
  options.fragment_context = ctx_tag;
  options.fragment_namespace = ctx_ns;
  options.fragment_encoding = encoding;
  options.quirks_mode = quirks_mode;
  options.fragment_context_has_form_ancestor = form;

  GumboOutput *output = perform_parse(&options, tags);
  ParseArgs args = {
    .output = output,
    .input = tags,
    .url_or_frag = doc_fragment,
    .doc = (xmlDocPtr)extract_xml_node(doc),
  };
  rb_ensure(fragment_continue, (VALUE)&args, parse_cleanup, (VALUE)&args);
  return Qnil;
}

static VALUE fragment_continue(ParseArgs *args) {
  GumboOutput *output = args->output;
  VALUE doc_fragment = args->url_or_frag;
  xmlDocPtr xml_doc = args->doc;

  args->doc = NIL; // The Ruby runtime owns doc so make sure we don't delete it.
  xmlNodePtr xml_frag = extract_xml_node(doc_fragment);
  build_tree(xml_doc, xml_frag, output->root);
  add_errors(output, doc_fragment, args->input, rb_utf8_str_new_static("#fragment", 9));
  return Qnil;
}

// Initialize the Nokogumbo class and fetch constants we will use later.
void Init_nokogumbo() {
  rb_funcall(rb_mKernel, rb_intern_const("gem"), 1, rb_utf8_str_new_static("nokogiri", 8));
  rb_require("nokogiri");

  VALUE line_supported = Qtrue;

#if !NGLIB
  // Class constants.
  VALUE mNokogiri = rb_const_get(rb_cObject, rb_intern_const("Nokogiri"));
  VALUE mNokogiriXml = rb_const_get(mNokogiri, rb_intern_const("XML"));
  cNokogiriXmlSyntaxError = rb_const_get(mNokogiriXml, rb_intern_const("SyntaxError"));
  cNokogiriXmlElement = rb_const_get(mNokogiriXml, rb_intern_const("Element"));
  cNokogiriXmlText = rb_const_get(mNokogiriXml, rb_intern_const("Text"));
  cNokogiriXmlCData = rb_const_get(mNokogiriXml, rb_intern_const("CDATA"));
  cNokogiriXmlComment = rb_const_get(mNokogiriXml, rb_intern_const("Comment"));

  // Interned symbols.
  new = rb_intern_const("new");
  node_name_ = rb_intern_const("node_name=");

  // #line is not supported (returns 0)
  line_supported = Qfalse;
#endif

  // Class constants.
  VALUE HTML5 = rb_const_get(mNokogiri, rb_intern_const("HTML5"));
  Document = rb_const_get(HTML5, rb_intern_const("Document"));

  // Interned symbols.
  internal_subset = rb_intern_const("internal_subset");
  parent = rb_intern_const("parent");

  // Define Nokogumbo module with parse and fragment methods.
  VALUE Gumbo = rb_define_module("Nokogumbo");
  rb_define_singleton_method(Gumbo, "parse", parse, 4);
  rb_define_singleton_method(Gumbo, "fragment", fragment, 5);

  // Add private constant for testing.
  rb_define_const(Gumbo, "LINE_SUPPORTED", line_supported);
  rb_funcall(Gumbo, rb_intern_const("private_constant"), 1,
             rb_utf8_str_new_cstr("LINE_SUPPORTED"));
}

// vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
