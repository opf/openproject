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

#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "ascii.h"
#include "attribute.h"
#include "error.h"
#include "gumbo.h"
#include "insertion_mode.h"
#include "macros.h"
#include "parser.h"
#include "replacement.h"
#include "tokenizer.h"
#include "tokenizer_states.h"
#include "token_buffer.h"
#include "utf8.h"
#include "util.h"
#include "vector.h"

typedef uint8_t TagSet[GUMBO_TAG_LAST + 1];
#define TAG(tag) [GUMBO_TAG_##tag] = (1 << GUMBO_NAMESPACE_HTML)
#define TAG_SVG(tag) [GUMBO_TAG_##tag] = (1 << GUMBO_NAMESPACE_SVG)
#define TAG_MATHML(tag) [GUMBO_TAG_##tag] = (1 << GUMBO_NAMESPACE_MATHML)

#define GUMBO_EMPTY_SOURCE_POSITION_INIT { .line = 0, .column = 0, .offset = 0 }
#define kGumboEmptySourcePosition (const GumboSourcePosition) \
  GUMBO_EMPTY_SOURCE_POSITION_INIT

const GumboOptions kGumboDefaultOptions = {
  .tab_stop = 8,
  .stop_on_first_error = false,
  .max_tree_depth = 400,
  .max_errors = -1,
  .fragment_context = NULL,
  .fragment_namespace = GUMBO_NAMESPACE_HTML,
  .fragment_encoding = NULL,
  .quirks_mode = GUMBO_DOCTYPE_NO_QUIRKS,
  .fragment_context_has_form_ancestor = false,
};

#define STRING(s) {.data = s, .length = sizeof(s) - 1}
#define TERMINATOR {.data = NULL, .length = 0}

// The doctype arrays have an explicit terminator because we want to pass them
// to a helper function, and passing them as a pointer discards sizeof
// information. The SVG arrays are used only by one-off functions, and so loops
// over them use sizeof directly instead of a terminator.

static const GumboStringPiece kQuirksModePublicIdPrefixes[] = {
  STRING("+//Silmaril//dtd html Pro v0r11 19970101//"),
  STRING("-//AdvaSoft Ltd//DTD HTML 3.0 asWedit + extensions//"),
  STRING("-//AS//DTD HTML 3.0 asWedit + extensions//"),
  STRING("-//IETF//DTD HTML 2.0 Level 1//"),
  STRING("-//IETF//DTD HTML 2.0 Level 2//"),
  STRING("-//IETF//DTD HTML 2.0 Strict Level 1//"),
  STRING("-//IETF//DTD HTML 2.0 Strict Level 2//"),
  STRING("-//IETF//DTD HTML 2.0 Strict//"),
  STRING("-//IETF//DTD HTML 2.0//"),
  STRING("-//IETF//DTD HTML 2.1E//"),
  STRING("-//IETF//DTD HTML 3.0//"),
  STRING("-//IETF//DTD HTML 3.2 Final//"),
  STRING("-//IETF//DTD HTML 3.2//"),
  STRING("-//IETF//DTD HTML 3//"),
  STRING("-//IETF//DTD HTML Level 0//"),
  STRING("-//IETF//DTD HTML Level 1//"),
  STRING("-//IETF//DTD HTML Level 2//"),
  STRING("-//IETF//DTD HTML Level 3//"),
  STRING("-//IETF//DTD HTML Strict Level 0//"),
  STRING("-//IETF//DTD HTML Strict Level 1//"),
  STRING("-//IETF//DTD HTML Strict Level 2//"),
  STRING("-//IETF//DTD HTML Strict Level 3//"),
  STRING("-//IETF//DTD HTML Strict//"),
  STRING("-//IETF//DTD HTML//"),
  STRING("-//Metrius//DTD Metrius Presentational//"),
  STRING("-//Microsoft//DTD Internet Explorer 2.0 HTML Strict//"),
  STRING("-//Microsoft//DTD Internet Explorer 2.0 HTML//"),
  STRING("-//Microsoft//DTD Internet Explorer 2.0 Tables//"),
  STRING("-//Microsoft//DTD Internet Explorer 3.0 HTML Strict//"),
  STRING("-//Microsoft//DTD Internet Explorer 3.0 HTML//"),
  STRING("-//Microsoft//DTD Internet Explorer 3.0 Tables//"),
  STRING("-//Netscape Comm. Corp.//DTD HTML//"),
  STRING("-//Netscape Comm. Corp.//DTD Strict HTML//"),
  STRING("-//O'Reilly and Associates//DTD HTML 2.0//"),
  STRING("-//O'Reilly and Associates//DTD HTML Extended 1.0//"),
  STRING("-//O'Reilly and Associates//DTD HTML Extended Relaxed 1.0//"),
  STRING(
    "-//SoftQuad Software//DTD HoTMetaL PRO 6.0::19990601::)"
    "extensions to HTML 4.0//"),
  STRING(
    "-//SoftQuad//DTD HoTMetaL PRO 4.0::19971010::"
    "extensions to HTML 4.0//"),
  STRING("-//Spyglass//DTD HTML 2.0 Extended//"),
  STRING("-//SQ//DTD HTML 2.0 HoTMetaL + extensions//"),
  STRING("-//Sun Microsystems Corp.//DTD HotJava HTML//"),
  STRING("-//Sun Microsystems Corp.//DTD HotJava Strict HTML//"),
  STRING("-//W3C//DTD HTML 3 1995-03-24//"),
  STRING("-//W3C//DTD HTML 3.2 Draft//"),
  STRING("-//W3C//DTD HTML 3.2 Final//"),
  STRING("-//W3C//DTD HTML 3.2//"),
  STRING("-//W3C//DTD HTML 3.2S Draft//"),
  STRING("-//W3C//DTD HTML 4.0 Frameset//"),
  STRING("-//W3C//DTD HTML 4.0 Transitional//"),
  STRING("-//W3C//DTD HTML Experimental 19960712//"),
  STRING("-//W3C//DTD HTML Experimental 970421//"),
  STRING("-//W3C//DTD W3 HTML//"),
  STRING("-//W3O//DTD W3 HTML 3.0//"),
  STRING("-//WebTechs//DTD Mozilla HTML 2.0//"),
  STRING("-//WebTechs//DTD Mozilla HTML//"),
  TERMINATOR
};

static const GumboStringPiece kQuirksModePublicIdExactMatches[] = {
  STRING("-//W3O//DTD W3 HTML Strict 3.0//EN//"),
  STRING("-/W3C/DTD HTML 4.0 Transitional/EN"),
  STRING("HTML"),
  TERMINATOR
};

static const GumboStringPiece kQuirksModeSystemIdExactMatches[] = {
  STRING("http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd"),
  TERMINATOR
};

static const GumboStringPiece kLimitedQuirksPublicIdPrefixes[] = {
  STRING("-//W3C//DTD XHTML 1.0 Frameset//"),
  STRING("-//W3C//DTD XHTML 1.0 Transitional//"),
  TERMINATOR
};

static const GumboStringPiece kSystemIdDependentPublicIdPrefixes[] = {
  STRING("-//W3C//DTD HTML 4.01 Frameset//"),
  STRING("-//W3C//DTD HTML 4.01 Transitional//"),
  TERMINATOR
};

// Indexed by GumboNamespaceEnum; keep in sync with that.
static const char* kLegalXmlns[] = {
  "http://www.w3.org/1999/xhtml",
  "http://www.w3.org/2000/svg",
  "http://www.w3.org/1998/Math/MathML"
};

// The "scope marker" for the list of active formatting elements. We use a
// pointer to this as a generic marker element, since the particular element
// scope doesn't matter.
static const GumboNode kActiveFormattingScopeMarker;

// The tag_is and tag_in function use true & false to denote start & end tags,
// but for readability, we define constants for them here.
static const bool kStartTag = true;
static const bool kEndTag = false;

// Because GumboStringPieces are immutable, we can't insert a character directly
// into a text node. Instead, we accumulate all pending characters here and
// flush them out to a text node whenever a new element is inserted.
//
// https://html.spec.whatwg.org/multipage/parsing.html#insert-a-character
typedef struct _TextNodeBufferState {
  // The accumulated text to be inserted into the current text node.
  GumboStringBuffer _buffer;

  // A pointer to the original text represented by this text node. Note that
  // because of foster parenting and other strange DOM manipulations, this may
  // include other non-text HTML tags in it; it is defined as the span of
  // original text from the first character in this text node to the last
  // character in this text node.
  const char* _start_original_text;

  // The source position of the start of this text node.
  GumboSourcePosition _start_position;

  // The type of node that will be inserted (TEXT, CDATA, or WHITESPACE).
  GumboNodeType _type;
} TextNodeBufferState;

typedef struct GumboInternalParserState {
  // https://html.spec.whatwg.org/multipage/parsing.html#insertion-mode
  GumboInsertionMode _insertion_mode;

  // Used for run_generic_parsing_algorithm, which needs to switch back to the
  // original insertion mode at its conclusion.
  GumboInsertionMode _original_insertion_mode;

  // https://html.spec.whatwg.org/multipage/parsing.html#the-stack-of-open-elements
  GumboVector /*GumboNode*/ _open_elements;

  // https://html.spec.whatwg.org/multipage/parsing.html#the-list-of-active-formatting-elements
  GumboVector /*GumboNode*/ _active_formatting_elements;

  // The stack of template insertion modes.
  // https://html.spec.whatwg.org/multipage/parsing.html#the-insertion-mode
  GumboVector /*InsertionMode*/ _template_insertion_modes;

  // https://html.spec.whatwg.org/multipage/parsing.html#the-element-pointers
  GumboNode* _head_element;
  GumboNode* _form_element;

  // The element used as fragment context when parsing in fragment mode
  GumboNode* _fragment_ctx;

  // The flag for when the spec says "Reprocess the current token in..."
  bool _reprocess_current_token;

  // The flag for "acknowledge the token's self-closing flag".
  bool _self_closing_flag_acknowledged;

  // The "frameset-ok" flag from the spec.
  bool _frameset_ok;

  // The flag for "If the next token is a LINE FEED, ignore that token...".
  bool _ignore_next_linefeed;

  // The flag for "whenever a node would be inserted into the current node, it
  // must instead be foster parented". This is used for misnested table
  // content, which needs to be handled according to "in body" rules yet foster
  // parented outside of the table.
  // It would perhaps be more explicit to have this as a parameter to
  // handle_in_body and insert_element, but given how special-purpose this is
  // and the number of call-sites that would need to take the extra parameter,
  // it's easier just to have a state flag.
  bool _foster_parent_insertions;

  // The accumulated text node buffer state.
  TextNodeBufferState _text_node;

  // The accumulated character tokens in tables for error purposes.
  GumboCharacterTokenBuffer _table_character_tokens;

  // The current token.
  GumboToken* _current_token;

  // The way that the spec is written, the </body> and </html> tags are *always*
  // implicit, because encountering one of those tokens merely switches the
  // insertion mode out of "in body". So we have individual state flags for
  // those end tags that are then inspected by pop_current_node when the <body>
  // and <html> nodes are popped to set the GUMBO_INSERTION_IMPLICIT_END_TAG
  // flag appropriately.
  bool _closed_body_tag;
  bool _closed_html_tag;
} GumboParserState;

static bool token_has_attribute(const GumboToken* token, const char* name) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  return gumbo_get_attribute(&token->v.start_tag.attributes, name) != NULL;
}

// Checks if the value of the specified attribute is a case-insensitive match
// for the specified string.
static bool attribute_matches (
  const GumboVector* attributes,
  const char* name,
  const char* value
) {
  const GumboAttribute* attr = gumbo_get_attribute(attributes, name);
  return attr ? gumbo_ascii_strcasecmp(value, attr->value) == 0 : false;
}

// Checks if the value of the specified attribute is a case-sensitive match
// for the specified string.
static bool attribute_matches_case_sensitive (
  const GumboVector* attributes,
  const char* name,
  const char* value
) {
  const GumboAttribute* attr = gumbo_get_attribute(attributes, name);
  return attr ? strcmp(value, attr->value) == 0 : false;
}

// Checks if the specified attribute vectors are identical.
static bool all_attributes_match (
  const GumboVector* attr1,
  const GumboVector* attr2
) {
  unsigned int num_unmatched_attr2_elements = attr2->length;
  for (unsigned int i = 0; i < attr1->length; ++i) {
    const GumboAttribute* attr = attr1->data[i];
    if (attribute_matches_case_sensitive(attr2, attr->name, attr->value)) {
      --num_unmatched_attr2_elements;
    } else {
      return false;
    }
  }
  return num_unmatched_attr2_elements == 0;
}

static void set_frameset_not_ok(GumboParser* parser) {
  gumbo_debug("Setting frameset_ok to false.\n");
  parser->_parser_state->_frameset_ok = false;
}

static GumboNode* create_node(GumboNodeType type) {
  GumboNode* node = gumbo_alloc(sizeof(GumboNode));
  node->parent = NULL;
  node->index_within_parent = -1;
  node->type = type;
  node->parse_flags = GUMBO_INSERTION_NORMAL;
  return node;
}

static GumboNode* new_document_node() {
  GumboNode* document_node = create_node(GUMBO_NODE_DOCUMENT);
  document_node->parse_flags = GUMBO_INSERTION_BY_PARSER;
  gumbo_vector_init(1, &document_node->v.document.children);

  // Must be initialized explicitly, as there's no guarantee that we'll see a
  // doc type token.
  GumboDocument* document = &document_node->v.document;
  document->has_doctype = false;
  document->name = NULL;
  document->public_identifier = NULL;
  document->system_identifier = NULL;
  document->doc_type_quirks_mode = GUMBO_DOCTYPE_NO_QUIRKS;
  return document_node;
}

static void output_init(GumboParser* parser) {
  GumboOutput* output = gumbo_alloc(sizeof(GumboOutput));
  output->root = NULL;
  output->document = new_document_node();
  output->document_error = false;
  output->status = GUMBO_STATUS_OK;
  parser->_output = output;
  gumbo_init_errors(parser);
}

static void parser_state_init(GumboParser* parser) {
  GumboParserState* parser_state = gumbo_alloc(sizeof(GumboParserState));
  parser_state->_insertion_mode = GUMBO_INSERTION_MODE_INITIAL;
  parser_state->_reprocess_current_token = false;
  parser_state->_frameset_ok = true;
  parser_state->_ignore_next_linefeed = false;
  parser_state->_foster_parent_insertions = false;
  parser_state->_text_node._type = GUMBO_NODE_WHITESPACE;
  gumbo_string_buffer_init(&parser_state->_text_node._buffer);
  gumbo_character_token_buffer_init(&parser_state->_table_character_tokens);
  gumbo_vector_init(10, &parser_state->_open_elements);
  gumbo_vector_init(5, &parser_state->_active_formatting_elements);
  gumbo_vector_init(5, &parser_state->_template_insertion_modes);
  parser_state->_head_element = NULL;
  parser_state->_form_element = NULL;
  parser_state->_fragment_ctx = NULL;
  parser_state->_current_token = NULL;
  parser_state->_closed_body_tag = false;
  parser_state->_closed_html_tag = false;
  parser->_parser_state = parser_state;
}

typedef void (*TreeTraversalCallback)(GumboNode* node);

static void tree_traverse(GumboNode* node, TreeTraversalCallback callback) {
  GumboNode* current_node = node;
  unsigned int offset = 0;

tailcall:
  switch (current_node->type) {
    case GUMBO_NODE_DOCUMENT:
    case GUMBO_NODE_TEMPLATE:
    case GUMBO_NODE_ELEMENT: {
      GumboVector* children = (current_node->type == GUMBO_NODE_DOCUMENT)
        ? &current_node->v.document.children
        : &current_node->v.element.children
      ;
      if (offset >= children->length) {
        assert(offset == children->length);
        break;
      } else {
        current_node = children->data[offset];
        offset = 0;
        goto tailcall;
      }
    }
    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_COMMENT:
    case GUMBO_NODE_WHITESPACE:
      assert(offset == 0);
      break;
  }

  offset = current_node->index_within_parent + 1;
  GumboNode* next_node = current_node->parent;
  callback(current_node);
  if (current_node == node) {
    return;
  }
  current_node = next_node;
  goto tailcall;
}

static void destroy_node_callback(GumboNode* node) {
  switch (node->type) {
    case GUMBO_NODE_DOCUMENT: {
      GumboDocument* doc = &node->v.document;
      gumbo_free((void*) doc->children.data);
      gumbo_free((void*) doc->name);
      gumbo_free((void*) doc->public_identifier);
      gumbo_free((void*) doc->system_identifier);
    } break;
    case GUMBO_NODE_TEMPLATE:
    case GUMBO_NODE_ELEMENT:
      for (unsigned int i = 0; i < node->v.element.attributes.length; ++i) {
        gumbo_destroy_attribute(node->v.element.attributes.data[i]);
      }
      gumbo_free(node->v.element.attributes.data);
      gumbo_free(node->v.element.children.data);
      if (node->v.element.tag == GUMBO_TAG_UNKNOWN)
        gumbo_free((void *)node->v.element.name);
      break;
    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_COMMENT:
    case GUMBO_NODE_WHITESPACE:
      gumbo_free((void*) node->v.text.text);
      break;
  }
  gumbo_free(node);
}

static void destroy_node(GumboNode* node) {
  tree_traverse(node, &destroy_node_callback);
}

static void destroy_fragment_ctx_element(GumboNode* ctx);

static void parser_state_destroy(GumboParser* parser) {
  GumboParserState* state = parser->_parser_state;
  if (state->_fragment_ctx) {
    destroy_fragment_ctx_element(state->_fragment_ctx);
  }
  gumbo_vector_destroy(&state->_active_formatting_elements);
  gumbo_vector_destroy(&state->_open_elements);
  gumbo_vector_destroy(&state->_template_insertion_modes);
  gumbo_string_buffer_destroy(&state->_text_node._buffer);
  gumbo_character_token_buffer_destroy(&state->_table_character_tokens);
  gumbo_free(state);
}

static GumboNode* get_document_node(const GumboParser* parser) {
  return parser->_output->document;
}

static bool is_fragment_parser(const GumboParser* parser) {
  return !!parser->_parser_state->_fragment_ctx;
}

// Returns the node at the bottom of the stack of open elements, or NULL if no
// elements have been added yet.
static GumboNode* get_current_node(const GumboParser* parser) {
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  if (open_elements->length == 0) {
    assert(!parser->_output->root);
    return NULL;
  }
  assert(open_elements->length > 0);
  assert(open_elements->data != NULL);
  return open_elements->data[open_elements->length - 1];
}

static GumboNode* get_adjusted_current_node(const GumboParser* parser) {
  const GumboParserState* state = parser->_parser_state;
  if (state->_open_elements.length == 1 && state->_fragment_ctx) {
    return state->_fragment_ctx;
  }
  return get_current_node(parser);
}

// Returns true if the given needle is in the given array of literal
// GumboStringPieces. If exact_match is true, this requires that they match
// exactly; otherwise, this performs a prefix match to check if any of the
// elements in haystack start with needle. This always performs a
// case-insensitive match.
static bool is_in_static_list (
  const GumboStringPiece* needle,
  const GumboStringPiece* haystack,
  bool exact_match
) {
  if (needle->length == 0)
    return false;
  if (exact_match) {
    for (size_t i = 0; haystack[i].data; ++i) {
      if (gumbo_string_equals_ignore_case(needle, &haystack[i]))
        return true;
    }
  } else {
    for (size_t i = 0; haystack[i].data; ++i) {
      if (gumbo_string_prefix_ignore_case(&haystack[i], needle))
        return true;
    }
  }
  return false;
}

static void set_insertion_mode(GumboParser* parser, GumboInsertionMode mode) {
  parser->_parser_state->_insertion_mode = mode;
}

static void push_template_insertion_mode (
  GumboParser* parser,
  GumboInsertionMode mode
) {
  gumbo_vector_add (
    (void*) mode,
    &parser->_parser_state->_template_insertion_modes
  );
}

static void pop_template_insertion_mode(GumboParser* parser) {
  gumbo_vector_pop(&parser->_parser_state->_template_insertion_modes);
}

// Returns the current template insertion mode. If the stack of template
// insertion modes is empty, this returns GUMBO_INSERTION_MODE_INITIAL.
static GumboInsertionMode get_current_template_insertion_mode (
  const GumboParser* parser
) {
  GumboVector* modes = &parser->_parser_state->_template_insertion_modes;
  if (modes->length == 0) {
    return GUMBO_INSERTION_MODE_INITIAL;
  }
  return (GumboInsertionMode) modes->data[(modes->length - 1)];
}

// Returns true if the specified token is either a start or end tag
// (specified by is_start) with one of the tag types in the TagSet.
static bool tag_in (
  const GumboToken* token,
  bool is_start,
  const TagSet* tags
) {
  GumboTag token_tag;
  if (is_start && token->type == GUMBO_TOKEN_START_TAG) {
    token_tag = token->v.start_tag.tag;
  } else if (!is_start && token->type == GUMBO_TOKEN_END_TAG) {
    token_tag = token->v.end_tag.tag;
  } else {
    return false;
  }
  return (*tags)[(unsigned) token_tag] != 0u;
}

// Like tag_in, but for the single-tag case.
static bool tag_is(const GumboToken* token, bool is_start, GumboTag tag) {
  if (is_start && token->type == GUMBO_TOKEN_START_TAG) {
    return token->v.start_tag.tag == tag;
  }
  if (!is_start && token->type == GUMBO_TOKEN_END_TAG) {
    return token->v.end_tag.tag == tag;
  }
  return false;
}

static inline bool tagset_includes (
  const TagSet* tagset,
  GumboNamespaceEnum ns,
  GumboTag tag
) {
  return ((*tagset)[(unsigned) tag] & (1u << (unsigned) ns)) != 0u;
}

// Like tag_in, but checks for the tag of a node, rather than a token.
static bool node_tag_in_set(const GumboNode* node, const TagSet* tags) {
  assert(node != NULL);
  if (node->type != GUMBO_NODE_ELEMENT && node->type != GUMBO_NODE_TEMPLATE) {
    return false;
  }
  return tagset_includes (
    tags,
    node->v.element.tag_namespace,
    node->v.element.tag
  );
}

static bool node_qualified_tagname_is (
  const GumboNode* node,
  GumboNamespaceEnum ns,
  GumboTag tag,
  const char *name
) {
  assert(node);
  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  assert(node->v.element.name);
  assert(tag != GUMBO_TAG_UNKNOWN || name);
  GumboTag element_tag = node->v.element.tag;
  const char *element_name = node->v.element.name;
  assert(element_tag != GUMBO_TAG_UNKNOWN || element_name);
  if (node->v.element.tag_namespace != ns || element_tag != tag)
    return false;
  if (tag != GUMBO_TAG_UNKNOWN)
    return true;
  return !gumbo_ascii_strcasecmp(element_name, name);
}

static bool node_html_tagname_is (
  const GumboNode* node,
  GumboTag tag,
  const char *name
) {
  return node_qualified_tagname_is(node, GUMBO_NAMESPACE_HTML, tag, name);
}

static bool node_tagname_is (
  const GumboNode* node,
  GumboTag tag,
  const char *name
) {
  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  return node_qualified_tagname_is(node, node->v.element.tag_namespace, tag, name);
}

// Like node_tag_in, but for the single-tag case.
static bool node_qualified_tag_is (
  const GumboNode* node,
  GumboNamespaceEnum ns,
  GumboTag tag
) {
  assert(node);
  assert(tag != GUMBO_TAG_UNKNOWN);
  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  return
    node->v.element.tag == tag
    && node->v.element.tag_namespace == ns;
}

// Like node_tag_in, but for the single-tag case in the HTML namespace
static bool node_html_tag_is(const GumboNode* node, GumboTag tag) {
  return node_qualified_tag_is(node, GUMBO_NAMESPACE_HTML, tag);
}

// https://html.spec.whatwg.org/multipage/parsing.html#reset-the-insertion-mode-appropriately
// This is a helper function that returns the appropriate insertion mode instead
// of setting it. Returns GUMBO_INSERTION_MODE_INITIAL as a sentinel value to
// indicate that there is no appropriate insertion mode, and the loop should
// continue.
static GumboInsertionMode get_appropriate_insertion_mode (
  const GumboParser* parser,
  int index
) {
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  const GumboNode* node = open_elements->data[index];
  const bool is_last = index == 0;

  if (is_last && is_fragment_parser(parser)) {
    node = parser->_parser_state->_fragment_ctx;
  }

  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  if (node->v.element.tag_namespace != GUMBO_NAMESPACE_HTML) {
    return is_last ? GUMBO_INSERTION_MODE_IN_BODY : GUMBO_INSERTION_MODE_INITIAL;
  }

  switch (node->v.element.tag) {
    case GUMBO_TAG_SELECT: {
      if (is_last) {
        return GUMBO_INSERTION_MODE_IN_SELECT;
      }
      for (int i = index; i > 0; --i) {
        const GumboNode* ancestor = open_elements->data[i];
        if (node_html_tag_is(ancestor, GUMBO_TAG_TEMPLATE)) {
          return GUMBO_INSERTION_MODE_IN_SELECT;
        }
        if (node_html_tag_is(ancestor, GUMBO_TAG_TABLE)) {
          return GUMBO_INSERTION_MODE_IN_SELECT_IN_TABLE;
        }
      }
      return GUMBO_INSERTION_MODE_IN_SELECT;
    }
    case GUMBO_TAG_TD:
    case GUMBO_TAG_TH:
      if (!is_last) return GUMBO_INSERTION_MODE_IN_CELL;
      break;
    case GUMBO_TAG_TR:
      return GUMBO_INSERTION_MODE_IN_ROW;
    case GUMBO_TAG_TBODY:
    case GUMBO_TAG_THEAD:
    case GUMBO_TAG_TFOOT:
      return GUMBO_INSERTION_MODE_IN_TABLE_BODY;
    case GUMBO_TAG_CAPTION:
      return GUMBO_INSERTION_MODE_IN_CAPTION;
    case GUMBO_TAG_COLGROUP:
      return GUMBO_INSERTION_MODE_IN_COLUMN_GROUP;
    case GUMBO_TAG_TABLE:
      return GUMBO_INSERTION_MODE_IN_TABLE;
    case GUMBO_TAG_TEMPLATE:
      return get_current_template_insertion_mode(parser);
    case GUMBO_TAG_HEAD:
      if (!is_last) return GUMBO_INSERTION_MODE_IN_HEAD;
      break;
    case GUMBO_TAG_BODY:
      return GUMBO_INSERTION_MODE_IN_BODY;
    case GUMBO_TAG_FRAMESET:
      return GUMBO_INSERTION_MODE_IN_FRAMESET;
    case GUMBO_TAG_HTML:
      return parser->_parser_state->_head_element
        ? GUMBO_INSERTION_MODE_AFTER_HEAD
        : GUMBO_INSERTION_MODE_BEFORE_HEAD;
    default:
      break;
  }
  return is_last ? GUMBO_INSERTION_MODE_IN_BODY : GUMBO_INSERTION_MODE_INITIAL;
}

// This performs the actual "reset the insertion mode" loop.
static void reset_insertion_mode_appropriately(GumboParser* parser) {
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (int i = open_elements->length; --i >= 0;) {
    GumboInsertionMode mode = get_appropriate_insertion_mode(parser, i);
    if (mode != GUMBO_INSERTION_MODE_INITIAL) {
      set_insertion_mode(parser, mode);
      return;
    }
  }
  // Should never get here, because is_last will be set on the last iteration
  // and will force GUMBO_INSERTION_MODE_IN_BODY.
  assert(0);
}

static void parser_add_parse_error (
  GumboParser* parser,
  const GumboToken* token
) {
  gumbo_debug("Adding parse error.\n");
  GumboError* error = gumbo_add_error(parser);
  if (!error) {
    return;
  }
  error->type = GUMBO_ERR_PARSER;
  error->position = token->position;
  error->original_text = token->original_text;
  GumboParserError* extra_data = &error->v.parser;
  extra_data->input_type = token->type;
  extra_data->input_tag = GUMBO_TAG_UNKNOWN;
  if (token->type == GUMBO_TOKEN_START_TAG) {
    extra_data->input_tag = token->v.start_tag.tag;
  } else if (token->type == GUMBO_TOKEN_END_TAG) {
    extra_data->input_tag = token->v.end_tag.tag;
  }
  const GumboParserState* state = parser->_parser_state;
  extra_data->parser_state = state->_insertion_mode;
  gumbo_vector_init(state->_open_elements.length, &extra_data->tag_stack);
  for (unsigned int i = 0; i < state->_open_elements.length; ++i) {
    const GumboNode* node = state->_open_elements.data[i];
    assert (
      node->type == GUMBO_NODE_ELEMENT
      || node->type == GUMBO_NODE_TEMPLATE
    );
    gumbo_vector_add (
      (void*) node->v.element.tag,
      &extra_data->tag_stack
    );
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#mathml-text-integration-point
static bool is_mathml_integration_point(const GumboNode* node) {
  static const TagSet mathml_integration_point_tags = {
    TAG_MATHML(MI), TAG_MATHML(MO), TAG_MATHML(MN),
    TAG_MATHML(MS), TAG_MATHML(MTEXT)
  };
  return node_tag_in_set(node, &mathml_integration_point_tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#html-integration-point
static bool is_html_integration_point(const GumboNode* node) {
  static const TagSet html_integration_point_svg_tags = {
      TAG_SVG(FOREIGNOBJECT), TAG_SVG(DESC), TAG_SVG(TITLE)
  };
  if (node_tag_in_set(node, &html_integration_point_svg_tags)) {
    return true;
  }

  const bool is_mathml_annotation_xml_element = node_qualified_tag_is (
    node,
    GUMBO_NAMESPACE_MATHML,
    GUMBO_TAG_ANNOTATION_XML
  );
  const GumboVector* attributes = &node->v.element.attributes;
  if (
    is_mathml_annotation_xml_element
    && (
      attribute_matches(attributes, "encoding", "text/html")
      || attribute_matches(attributes, "encoding", "application/xhtml+xml")
    )
  ) {
    return true;
  }

  return false;
}

// This represents a place to insert a node, consisting of a target parent and a
// child index within that parent. If the node should be inserted at the end of
// the parent's child, index will be -1.
typedef struct {
  GumboNode* target;
  int index;
} InsertionLocation;

static InsertionLocation get_appropriate_insertion_location (
  const GumboParser* parser,
  GumboNode* override_target
) {
  InsertionLocation retval = {override_target, -1};
  if (retval.target == NULL) {
    // No override target; default to the current node, but special-case the
    // root node since get_current_node() assumes the stack of open elements is
    // non-empty.
    retval.target = (parser->_output->root != NULL)
      ? get_current_node(parser)
      : get_document_node(parser)
    ;
  }
  if (
    !parser->_parser_state->_foster_parent_insertions
    || !node_tag_in_set(retval.target, &(const TagSet) {
      TAG(TABLE), TAG(TBODY), TAG(TFOOT), TAG(THEAD), TAG(TR)
    })
  ) {
    return retval;
  }

  // Foster-parenting case.
  int last_template_index = -1;
  int last_table_index = -1;
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (unsigned int i = 0; i < open_elements->length; ++i) {
    if (node_html_tag_is(open_elements->data[i], GUMBO_TAG_TEMPLATE)) {
      last_template_index = i;
    }
    if (node_html_tag_is(open_elements->data[i], GUMBO_TAG_TABLE)) {
      last_table_index = i;
    }
  }
  if (
    last_template_index != -1
    && (last_table_index == -1 || last_template_index > last_table_index)
  ) {
    retval.target = open_elements->data[last_template_index];
    return retval;
  }
  if (last_table_index == -1) {
    retval.target = open_elements->data[0];
    return retval;
  }
  const GumboNode* last_table = open_elements->data[last_table_index];
  if (last_table->parent != NULL) {
    retval.target = last_table->parent;
    retval.index = last_table->index_within_parent;
    return retval;
  }

  retval.target = open_elements->data[last_table_index - 1];
  return retval;
}

// Appends a node to the end of its parent, setting the "parent" and
// "index_within_parent" fields appropriately.
static void append_node(GumboNode* parent, GumboNode* node) {
  assert(node->parent == NULL);
  assert(node->index_within_parent == (unsigned int) -1);
  GumboVector* children;
  if (
    parent->type == GUMBO_NODE_ELEMENT
    || parent->type == GUMBO_NODE_TEMPLATE
  ) {
    children = &parent->v.element.children;
  } else {
    assert(parent->type == GUMBO_NODE_DOCUMENT);
    children = &parent->v.document.children;
  }
  node->parent = parent;
  node->index_within_parent = children->length;
  gumbo_vector_add((void*) node, children);
  assert(node->index_within_parent < children->length);
}

// Inserts a node at the specified InsertionLocation, updating the
// "parent" and "index_within_parent" fields of it and all its siblings.
// If the index of the location is -1, this calls append_node.
static void insert_node(GumboNode* node, InsertionLocation location) {
  assert(node->parent == NULL);
  assert(node->index_within_parent == (unsigned int) -1);
  GumboNode* parent = location.target;
  int index = location.index;
  if (index != -1) {
    GumboVector* children = NULL;
    if (
      parent->type == GUMBO_NODE_ELEMENT
      || parent->type == GUMBO_NODE_TEMPLATE
    ) {
      children = &parent->v.element.children;
    } else if (parent->type == GUMBO_NODE_DOCUMENT) {
      children = &parent->v.document.children;
      assert(children->length == 0);
    } else {
      assert(0);
    }

    assert(index >= 0);
    assert((unsigned int) index < children->length);
    node->parent = parent;
    node->index_within_parent = index;
    gumbo_vector_insert_at((void*) node, index, children);
    assert(node->index_within_parent < children->length);
    for (unsigned int i = index + 1; i < children->length; ++i) {
      GumboNode* sibling = children->data[i];
      sibling->index_within_parent = i;
      assert(sibling->index_within_parent < children->length);
    }
  } else {
    append_node(parent, node);
  }
}

static void maybe_flush_text_node_buffer(GumboParser* parser) {
  GumboParserState* state = parser->_parser_state;
  TextNodeBufferState* buffer_state = &state->_text_node;
  if (buffer_state->_buffer.length == 0) {
    return;
  }

  assert (
    buffer_state->_type == GUMBO_NODE_WHITESPACE
    || buffer_state->_type == GUMBO_NODE_TEXT
    || buffer_state->_type == GUMBO_NODE_CDATA
  );
  GumboNode* text_node = create_node(buffer_state->_type);
  GumboText* text_node_data = &text_node->v.text;
  text_node_data->text = gumbo_string_buffer_to_string(&buffer_state->_buffer);
  text_node_data->original_text.data = buffer_state->_start_original_text;
  text_node_data->original_text.length =
      state->_current_token->original_text.data -
      buffer_state->_start_original_text;
  text_node_data->start_pos = buffer_state->_start_position;

  gumbo_debug (
    "Flushing text node buffer of %.*s.\n",
    (int) buffer_state->_buffer.length,
    buffer_state->_buffer.data
  );

  InsertionLocation location = get_appropriate_insertion_location(parser, NULL);
  if (location.target->type == GUMBO_NODE_DOCUMENT) {
    // The DOM does not allow Document nodes to have Text children, so per the
    // spec, they are dropped on the floor.
    destroy_node(text_node);
  } else {
    insert_node(text_node, location);
  }

  gumbo_string_buffer_clear(&buffer_state->_buffer);
  buffer_state->_type = GUMBO_NODE_WHITESPACE;
  assert(buffer_state->_buffer.length == 0);
}

static void record_end_of_element (
  const GumboToken* current_token,
  GumboElement* element
) {
  element->end_pos = current_token->position;
  element->original_end_tag =
    (current_token->type == GUMBO_TOKEN_END_TAG)
      ? current_token->original_text
      : kGumboEmptyString;
}

static GumboNode* pop_current_node(GumboParser* parser) {
  GumboParserState* state = parser->_parser_state;
  maybe_flush_text_node_buffer(parser);
  if (state->_open_elements.length > 0) {
    assert(node_html_tag_is(state->_open_elements.data[0], GUMBO_TAG_HTML));
    gumbo_debug (
      "Popping %s node.\n",
      gumbo_normalized_tagname(get_current_node(parser)->v.element.tag)
    );
  }
  GumboNode* current_node = gumbo_vector_pop(&state->_open_elements);
  if (!current_node) {
    assert(state->_open_elements.length == 0);
    return NULL;
  }
  assert (
    current_node->type == GUMBO_NODE_ELEMENT
    || current_node->type == GUMBO_NODE_TEMPLATE
  );
  bool is_closed_body_or_html_tag =
    (
      node_html_tag_is(current_node, GUMBO_TAG_BODY)
      && state->_closed_body_tag
    ) || (
      node_html_tag_is(current_node, GUMBO_TAG_HTML)
      && state->_closed_html_tag
    )
  ;
  if (
    (
      state->_current_token->type != GUMBO_TOKEN_END_TAG
      || !node_qualified_tagname_is (
        current_node,
        GUMBO_NAMESPACE_HTML,
        state->_current_token->v.end_tag.tag,
        state->_current_token->v.end_tag.name
      )
    )
    && !is_closed_body_or_html_tag
  ) {
    current_node->parse_flags |= GUMBO_INSERTION_IMPLICIT_END_TAG;
  }
  if (!is_closed_body_or_html_tag) {
    record_end_of_element(state->_current_token, &current_node->v.element);
  }
  return current_node;
}

static void append_comment_node (
  GumboParser* parser,
  GumboNode* node,
  const GumboToken* token
) {
  maybe_flush_text_node_buffer(parser);
  GumboNode* comment = create_node(GUMBO_NODE_COMMENT);
  comment->type = GUMBO_NODE_COMMENT;
  comment->parse_flags = GUMBO_INSERTION_NORMAL;
  comment->v.text.text = token->v.text;
  comment->v.text.original_text = token->original_text;
  comment->v.text.start_pos = token->position;
  append_node(node, comment);
}

// https://html.spec.whatwg.org/multipage/parsing.html#clear-the-stack-back-to-a-table-row-context
static void clear_stack_to_table_row_context(GumboParser* parser) {
  static const TagSet tags = {TAG(HTML), TAG(TR), TAG(TEMPLATE)};
  while (!node_tag_in_set(get_current_node(parser), &tags)) {
    pop_current_node(parser);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#clear-the-stack-back-to-a-table-context
static void clear_stack_to_table_context(GumboParser* parser) {
  static const TagSet tags = {TAG(HTML), TAG(TABLE), TAG(TEMPLATE)};
  while (!node_tag_in_set(get_current_node(parser), &tags)) {
    pop_current_node(parser);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#clear-the-stack-back-to-a-table-body-context
static void clear_stack_to_table_body_context(GumboParser* parser) {
  static const TagSet tags = {
    TAG(HTML), TAG(TBODY), TAG(TFOOT), TAG(THEAD), TAG(TEMPLATE)
  };
  while (!node_tag_in_set(get_current_node(parser), &tags)) {
    pop_current_node(parser);
  }
}

// Creates a parser-inserted element in the HTML namespace and returns it.
static GumboNode* create_element(GumboParser* parser, GumboTag tag) {
  // XXX: This will fail for creating fragments with an element with tag
  // GUMBO_TAG_UNKNOWN
  assert(tag != GUMBO_TAG_UNKNOWN);
  GumboNode* node = create_node(GUMBO_NODE_ELEMENT);
  GumboElement* element = &node->v.element;
  gumbo_vector_init(1, &element->children);
  gumbo_vector_init(0, &element->attributes);
  element->tag = tag;
  element->name = gumbo_normalized_tagname(tag);
  element->tag_namespace = GUMBO_NAMESPACE_HTML;
  element->original_tag = kGumboEmptyString;
  element->original_end_tag = kGumboEmptyString;
  element->start_pos = (parser->_parser_state->_current_token)
    ? parser->_parser_state->_current_token->position
    : kGumboEmptySourcePosition
  ;
  element->end_pos = kGumboEmptySourcePosition;
  return node;
}

// Constructs an element from the given start tag token.
static GumboNode* create_element_from_token (
  GumboToken* token,
  GumboNamespaceEnum tag_namespace
) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  GumboTokenStartTag* start_tag = &token->v.start_tag;

  GumboNodeType type =
    (
      tag_namespace == GUMBO_NAMESPACE_HTML
      && start_tag->tag == GUMBO_TAG_TEMPLATE
    )
    ? GUMBO_NODE_TEMPLATE
    : GUMBO_NODE_ELEMENT
  ;

  GumboNode* node = create_node(type);
  GumboElement* element = &node->v.element;
  gumbo_vector_init(1, &element->children);
  element->attributes = start_tag->attributes;
  element->tag = start_tag->tag;
  element->name = start_tag->name ? start_tag->name : gumbo_normalized_tagname(start_tag->tag);
  element->tag_namespace = tag_namespace;

  assert(token->original_text.length >= 2);
  assert(token->original_text.data[0] == '<');
  assert(token->original_text.data[token->original_text.length - 1] == '>');
  element->original_tag = token->original_text;
  element->start_pos = token->position;
  element->original_end_tag = kGumboEmptyString;
  element->end_pos = kGumboEmptySourcePosition;

  // The element takes ownership of the attributes and name from the token, so
  // any allocated-memory fields should be nulled out.
  start_tag->attributes = kGumboEmptyVector;
  start_tag->name = NULL;
  return node;
}

// https://html.spec.whatwg.org/multipage/parsing.html#insert-an-html-element
static void insert_element (
  GumboParser* parser,
  GumboNode* node,
  bool is_reconstructing_formatting_elements
) {
  GumboParserState* state = parser->_parser_state;
  // NOTE(jdtang): The text node buffer must always be flushed before inserting
  // a node, otherwise we're handling nodes in a different order than the spec
  // mandated. However, one clause of the spec (character tokens in the body)
  // requires that we reconstruct the active formatting elements *before* adding
  // the character, and reconstructing the active formatting elements may itself
  // result in the insertion of new elements (which should be pushed onto the
  // stack of open elements before the buffer is flushed). We solve this (for
  // the time being, the spec has been rewritten for <template> and the new
  // version may be simpler here) with a boolean flag to this method.
  if (!is_reconstructing_formatting_elements) {
    maybe_flush_text_node_buffer(parser);
  }
  InsertionLocation location = get_appropriate_insertion_location(parser, NULL);
  insert_node(node, location);
  gumbo_vector_add((void*) node, &state->_open_elements);
}

// Convenience method that combines create_element_from_token and
// insert_element, inserting the generated element directly into the current
// node. Returns the node inserted.
static GumboNode* insert_element_from_token (
  GumboParser* parser,
  GumboToken* token
) {
  GumboNode* element = create_element_from_token(token, GUMBO_NAMESPACE_HTML);
  insert_element(parser, element, false);
  gumbo_debug (
    "Inserting <%s> element (@%p) from token.\n",
    gumbo_normalized_tagname(element->v.element.tag),
    (void*)element
  );
  return element;
}

// Convenience method that combines create_element and insert_element, inserting
// a parser-generated element of a specific tag type. Returns the node
// inserted.
static GumboNode* insert_element_of_tag_type (
  GumboParser* parser,
  GumboTag tag,
  GumboParseFlags reason
) {
  GumboNode* element = create_element(parser, tag);
  element->parse_flags |= GUMBO_INSERTION_BY_PARSER | reason;
  insert_element(parser, element, false);
  gumbo_debug (
    "Inserting %s element (@%p) from tag type.\n",
    gumbo_normalized_tagname(tag),
    (void*)element
  );
  return element;
}

// Convenience method for creating foreign namespaced element. Returns the node
// inserted.
static GumboNode* insert_foreign_element (
  GumboParser* parser,
  GumboToken* token,
  GumboNamespaceEnum tag_namespace
) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  GumboNode* element = create_element_from_token(token, tag_namespace);
  insert_element(parser, element, false);
  if (
    token_has_attribute(token, "xmlns")
    && !attribute_matches_case_sensitive (
      &token->v.start_tag.attributes,
      "xmlns",
      kLegalXmlns[tag_namespace]
    )
  ) {
    // TODO(jdtang): Since there're multiple possible error codes here, we
    // eventually need reason codes to differentiate them.
    parser_add_parse_error(parser, token);
  }
  if (
    token_has_attribute(token, "xmlns:xlink")
    && !attribute_matches_case_sensitive (
      &token->v.start_tag.attributes,
      "xmlns:xlink",
      "http://www.w3.org/1999/xlink"
    )
  ) {
    parser_add_parse_error(parser, token);
  }
  return element;
}

static void insert_text_token(GumboParser* parser, GumboToken* token) {
  assert (
    token->type == GUMBO_TOKEN_WHITESPACE
    || token->type == GUMBO_TOKEN_CHARACTER
    || token->type == GUMBO_TOKEN_NULL
    || token->type == GUMBO_TOKEN_CDATA
  );
  TextNodeBufferState* buffer_state = &parser->_parser_state->_text_node;
  if (buffer_state->_buffer.length == 0) {
    // Initialize position fields.
    buffer_state->_start_original_text = token->original_text.data;
    buffer_state->_start_position = token->position;
  }
  gumbo_string_buffer_append_codepoint (
    token->v.character,
    &buffer_state->_buffer
  );
  if (token->type == GUMBO_TOKEN_CHARACTER) {
    buffer_state->_type = GUMBO_NODE_TEXT;
  } else if (token->type == GUMBO_TOKEN_CDATA) {
    buffer_state->_type = GUMBO_NODE_CDATA;
  }
  gumbo_debug("Inserting text token '%c'.\n", token->v.character);
}

// https://html.spec.whatwg.org/multipage/parsing.html#generic-rcdata-element-parsing-algorithm
static void run_generic_parsing_algorithm (
  GumboParser* parser,
  GumboToken* token,
  GumboTokenizerEnum lexer_state
) {
  insert_element_from_token(parser, token);
  gumbo_tokenizer_set_state(parser, lexer_state);
  GumboParserState* parser_state = parser->_parser_state;
  parser_state->_original_insertion_mode = parser_state->_insertion_mode;
  parser_state->_insertion_mode = GUMBO_INSERTION_MODE_TEXT;
}

static void acknowledge_self_closing_tag(GumboParser* parser) {
  parser->_parser_state->_self_closing_flag_acknowledged = true;
}

// Returns true if there's an anchor tag in the list of active formatting
// elements, and fills in its index if so.
static bool find_last_anchor_index(GumboParser* parser, int* anchor_index) {
  GumboVector* elements = &parser->_parser_state->_active_formatting_elements;
  for (int i = elements->length; --i >= 0;) {
    GumboNode* node = elements->data[i];
    if (node == &kActiveFormattingScopeMarker) {
      return false;
    }
    if (node_html_tag_is(node, GUMBO_TAG_A)) {
      *anchor_index = i;
      return true;
    }
  }
  return false;
}

// Counts the number of open formatting elements in the list of active
// formatting elements (after the last active scope marker) that have a specific
// tag. If this is > 0, then earliest_matching_index will be filled in with the
// index of the first such element.
static int count_formatting_elements_of_tag (
  GumboParser* parser,
  const GumboNode* desired_node,
  int* earliest_matching_index
) {
  const GumboElement* desired_element = &desired_node->v.element;
  GumboVector* elements = &parser->_parser_state->_active_formatting_elements;
  int num_identical_elements = 0;
  for (int i = elements->length; --i >= 0;) {
    GumboNode* node = elements->data[i];
    if (node == &kActiveFormattingScopeMarker) {
      break;
    }
    assert(node->type == GUMBO_NODE_ELEMENT);
    if (
      node_qualified_tagname_is (
        node,
        desired_element->tag_namespace,
        desired_element->tag,
        desired_element->name
      )
      && all_attributes_match(&node->v.element.attributes, &desired_element->attributes)
    ) {
      num_identical_elements++;
      *earliest_matching_index = i;
    }
  }
  return num_identical_elements;
}

// https://html.spec.whatwg.org/multipage/parsing.html#reconstruct-the-active-formatting-elements
static void add_formatting_element(GumboParser* parser, const GumboNode* node) {
  assert (
    node == &kActiveFormattingScopeMarker
    || node->type == GUMBO_NODE_ELEMENT
  );
  GumboVector* elements = &parser->_parser_state->_active_formatting_elements;
  if (node == &kActiveFormattingScopeMarker) {
    gumbo_debug("Adding a scope marker.\n");
  } else {
    gumbo_debug("Adding a formatting element.\n");
  }

  // Hunt for identical elements.
  int earliest_identical_element = elements->length;
  int num_identical_elements = count_formatting_elements_of_tag (
    parser,
    node,
    &earliest_identical_element
  );

  // Noah's Ark clause: if there're at least 3, remove the earliest.
  if (num_identical_elements >= 3) {
    gumbo_debug (
      "Noah's ark clause: removing element at %d.\n",
      earliest_identical_element
    );
    gumbo_vector_remove_at(earliest_identical_element, elements);
  }

  gumbo_vector_add((void*) node, elements);
}

static bool is_open_element(const GumboParser* parser, const GumboNode* node) {
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (unsigned int i = 0; i < open_elements->length; ++i) {
    if (open_elements->data[i] == node) {
      return true;
    }
  }
  return false;
}

// Clones attributes, tags, etc. of a node, but does not copy the content. The
// clone shares no structure with the original node: all owned strings and
// values are fresh copies.
static GumboNode* clone_node (
  GumboNode* node,
  GumboParseFlags reason
) {
  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  GumboNode* new_node = gumbo_alloc(sizeof(GumboNode));
  *new_node = *node;
  new_node->parent = NULL;
  new_node->index_within_parent = -1;
  // Clear the GUMBO_INSERTION_IMPLICIT_END_TAG flag, as the cloned node may
  // have a separate end tag.
  new_node->parse_flags &= ~GUMBO_INSERTION_IMPLICIT_END_TAG;
  new_node->parse_flags |= reason | GUMBO_INSERTION_BY_PARSER;
  GumboElement* element = &new_node->v.element;
  gumbo_vector_init(1, &element->children);

  const GumboVector* old_attributes = &node->v.element.attributes;
  gumbo_vector_init(old_attributes->length, &element->attributes);
  for (unsigned int i = 0; i < old_attributes->length; ++i) {
    const GumboAttribute* old_attr = old_attributes->data[i];
    GumboAttribute* attr = gumbo_alloc(sizeof(GumboAttribute));
    *attr = *old_attr;
    attr->name = gumbo_strdup(old_attr->name);
    attr->value = gumbo_strdup(old_attr->value);
    gumbo_vector_add(attr, &element->attributes);
  }
  return new_node;
}

// "Reconstruct active formatting elements" part of the spec.
// This implementation is based on the html5lib translation from the
// mess of GOTOs in the spec to reasonably structured programming.
// https://github.com/html5lib/html5lib-python/blob/master/html5lib/treebuilders/base.py
static void reconstruct_active_formatting_elements(GumboParser* parser) {
  GumboVector* elements = &parser->_parser_state->_active_formatting_elements;
  // Step 1
  if (elements->length == 0) {
    return;
  }

  // Step 2 & 3
  unsigned int i = elements->length - 1;
  GumboNode* element = elements->data[i];
  if (
    element == &kActiveFormattingScopeMarker
    || is_open_element(parser, element)
  ) {
    return;
  }

  // Step 6
  do {
    if (i == 0) {
      // Step 4
      i = -1;  // Incremented to 0 below.
      break;
    }
    // Step 5
    element = elements->data[--i];
  } while (
    element != &kActiveFormattingScopeMarker
    && !is_open_element(parser, element)
  );

  ++i;
  gumbo_debug (
    "Reconstructing elements from %u on %s parent.\n",
    i,
    gumbo_normalized_tagname(get_current_node(parser)->v.element.tag)
  );
  for (; i < elements->length; ++i) {
    // Step 7 & 8.
    assert(elements->length > 0);
    assert(i < elements->length);
    element = elements->data[i];
    assert(element != &kActiveFormattingScopeMarker);
    GumboNode* clone = clone_node (
      element,
      GUMBO_INSERTION_RECONSTRUCTED_FORMATTING_ELEMENT
    );
    // Step 9.
    InsertionLocation location =
        get_appropriate_insertion_location(parser, NULL);
    insert_node(clone, location);
    gumbo_vector_add (
      (void*) clone,
      &parser->_parser_state->_open_elements
    );

    // Step 10.
    elements->data[i] = clone;
    gumbo_debug (
      "Reconstructed %s element at %u.\n",
      gumbo_normalized_tagname(clone->v.element.tag),
      i
    );
  }
}

static void clear_active_formatting_elements(GumboParser* parser) {
  GumboVector* elements = &parser->_parser_state->_active_formatting_elements;
  int num_elements_cleared = 0;
  const GumboNode* node;
  do {
    node = gumbo_vector_pop(elements);
    ++num_elements_cleared;
  } while (node && node != &kActiveFormattingScopeMarker);
  gumbo_debug (
    "Cleared %d elements from active formatting list.\n",
    num_elements_cleared
  );
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-initial-insertion-mode
GumboQuirksModeEnum gumbo_compute_quirks_mode (
  const char *name,
  const char *pubid_str,
  const char *sysid_str
) {

  GumboStringPiece pubid = {
    .data = pubid_str,
    .length = pubid_str? strlen(pubid_str) : 0,
  };
  GumboStringPiece sysid = {
    .data = sysid_str,
    .length = sysid_str? strlen(sysid_str) : 0,
  };
  bool has_system_identifier = !!sysid_str;
  if (
    name == NULL
    || strcmp(name, "html")
    || is_in_static_list(&pubid, kQuirksModePublicIdPrefixes, false)
    || is_in_static_list(&pubid, kQuirksModePublicIdExactMatches, true)
    || is_in_static_list(&sysid, kQuirksModeSystemIdExactMatches, true)
    || (
      !has_system_identifier
      && is_in_static_list(&pubid, kSystemIdDependentPublicIdPrefixes, false)
    )
  ) {
    return GUMBO_DOCTYPE_QUIRKS;
  }

  if (
    is_in_static_list(&pubid, kLimitedQuirksPublicIdPrefixes, false)
    || (
      has_system_identifier
      && is_in_static_list(&pubid, kSystemIdDependentPublicIdPrefixes, false)
    )
  ) {
    return GUMBO_DOCTYPE_LIMITED_QUIRKS;
  }

  return GUMBO_DOCTYPE_NO_QUIRKS;
}

static GumboQuirksModeEnum compute_quirks_mode(const GumboTokenDocType* doctype) {
  if (doctype->force_quirks)
    return GUMBO_DOCTYPE_QUIRKS;
  return gumbo_compute_quirks_mode (
    doctype->name,
    doctype->has_public_identifier? doctype->public_identifier : NULL,
    doctype->has_system_identifier? doctype->system_identifier : NULL
  );
}

// The following functions are all defined by the "has an element in __ scope"
// sections of the HTML5 spec:
// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-the-specific-scope
// The basic idea behind them is that they check for an element of the given
// qualified name, contained within a scope formed by a set of other qualified
// names. For example, "has an element in list scope" looks for an element of
// the given qualified name within the nearest enclosing <ol> or <ul>, along
// with a bunch of generic element types that serve to "firewall" their content
// from the rest of the document. Note that because of the way the spec is
// written,
// all elements are expected to be in the HTML namespace
static bool has_an_element_in_specific_scope (
  const GumboParser* parser,
  int expected_size,
  const GumboTag* expected,
  bool negate,
  const TagSet* tags
) {
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (int i = open_elements->length; --i >= 0;) {
    const GumboNode* node = open_elements->data[i];
    if (node->type != GUMBO_NODE_ELEMENT && node->type != GUMBO_NODE_TEMPLATE) {
      continue;
    }

    GumboTag node_tag = node->v.element.tag;
    GumboNamespaceEnum node_ns = node->v.element.tag_namespace;
    for (int j = 0; j < expected_size; ++j) {
      if (node_tag == expected[j] && node_ns == GUMBO_NAMESPACE_HTML) {
        return true;
      }
    }

    bool found = tagset_includes(tags, node_ns, node_tag);
    if (negate != found) {
      return false;
    }
  }
  return false;
}

// Checks for the presence of an open element of the specified tag type.
static bool has_open_element(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {TAG(HTML)};
  return has_an_element_in_specific_scope(parser, 1, &tag, false, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-scope
#define DEFAULT_SCOPE_TAGS \
  TAG(APPLET), \
  TAG(CAPTION), \
  TAG(HTML), \
  TAG(TABLE), \
  TAG(TD), \
  TAG(TH), \
  TAG(MARQUEE), \
  TAG(OBJECT), \
  TAG(TEMPLATE), \
  TAG_MATHML(MI), \
  TAG_MATHML(MO), \
  TAG_MATHML(MN), \
  TAG_MATHML(MS), \
  TAG_MATHML(MTEXT), \
  TAG_MATHML(ANNOTATION_XML), \
  TAG_SVG(FOREIGNOBJECT), \
  TAG_SVG(DESC), \
  TAG_SVG(TITLE)

static const TagSet heading_tags = {
  TAG(H1), TAG(H2), TAG(H3), TAG(H4), TAG(H5), TAG(H6)
};

static const TagSet td_th_tags = {
  TAG(TD), TAG(TH)
};

static const TagSet dd_dt_tags = {
  TAG(DD), TAG(DT)
};

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-scope
static bool has_an_element_in_scope(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {DEFAULT_SCOPE_TAGS};
  return has_an_element_in_specific_scope(parser, 1, &tag, false, &tags);
}

// Like "has an element in scope", but for the specific case of looking for a
// unique target node, not for any node with a given tag name. This duplicates
// much of the algorithm from has_an_element_in_specific_scope because the
// predicate is different when checking for an exact node, and it's easier &
// faster just to duplicate the code for this one case than to try and
// parameterize it.
static bool has_node_in_scope(const GumboParser* parser, const GumboNode* node) {
  static const TagSet tags = {DEFAULT_SCOPE_TAGS};
  const GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (int i = open_elements->length; --i >= 0;) {
    const GumboNode* current = open_elements->data[i];
    const GumboNodeType type = current->type;
    if (current == node) {
      return true;
    }
    if (type != GUMBO_NODE_ELEMENT && type != GUMBO_NODE_TEMPLATE) {
      continue;
    }
    if (node_tag_in_set(current, &tags)) {
      return false;
    }
  }
  assert(false);
  return false;
}

// Like has_an_element_in_scope, but restricts the expected qualified name to a
// range of possible qualified names instead of just a single one.
static bool has_an_element_in_scope_with_tagname (
  const GumboParser* parser,
  int len,
  const GumboTag expected[]
) {
  static const TagSet tags = {DEFAULT_SCOPE_TAGS};
  return has_an_element_in_specific_scope(parser, len, expected, false, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-list-item-scope
static bool has_an_element_in_list_scope(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {DEFAULT_SCOPE_TAGS, TAG(OL), TAG(UL)};
  return has_an_element_in_specific_scope(parser, 1, &tag, false, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-button-scope
static bool has_an_element_in_button_scope(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {DEFAULT_SCOPE_TAGS, TAG(BUTTON)};
  return has_an_element_in_specific_scope(parser, 1, &tag, false, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-table-scope
static bool has_an_element_in_table_scope(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {TAG(HTML), TAG(TABLE), TAG(TEMPLATE)};
  return has_an_element_in_specific_scope(parser, 1, &tag, false, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#has-an-element-in-select-scope
static bool has_an_element_in_select_scope(const GumboParser* parser, GumboTag tag) {
  static const TagSet tags = {TAG(OPTGROUP), TAG(OPTION)};
  return has_an_element_in_specific_scope(parser, 1, &tag, true, &tags);
}

// https://html.spec.whatwg.org/multipage/parsing.html#generate-implied-end-tags
// "exception" is the "element to exclude from the process" listed in the spec.
// Pass GUMBO_TAG_LAST to not exclude any of them.
static void generate_implied_end_tags (
  GumboParser* parser,
  GumboTag exception,
  const char* exception_name
) {
  static const TagSet tags = {
    TAG(DD), TAG(DT), TAG(LI), TAG(OPTGROUP), TAG(OPTION),
    TAG(P), TAG(RB), TAG(RP), TAG(RT), TAG(RTC)
  };
  while (
    node_tag_in_set(get_current_node(parser), &tags)
    && !node_html_tagname_is(get_current_node(parser), exception, exception_name)
  ) {
    pop_current_node(parser);
  }
}

// This is the "generate all implied end tags thoroughly" clause of the spec.
// https://html.spec.whatwg.org/multipage/parsing.html#closing-elements-that-have-implied-end-tags
static void generate_all_implied_end_tags_thoroughly(GumboParser* parser) {
  static const TagSet tags = {
    TAG(CAPTION), TAG(COLGROUP), TAG(DD), TAG(DT), TAG(LI), TAG(OPTGROUP),
    TAG(OPTION), TAG(P), TAG(RB), TAG(RP), TAG(RT), TAG(RTC), TAG(TBODY),
    TAG(TD), TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
  };
  while (node_tag_in_set(get_current_node(parser), &tags)) {
    pop_current_node(parser);
  }
}

// This factors out the clauses in the "in body" insertion mode checking "if
// there is a node in the stack of open elements that is not" one of a list of
// elements in which case it's a parse error.
// This is used in "an end-of-file token", "an end tag whose tag name is
// 'body'", and "an end tag whose tag name is 'html'".
static bool stack_contains_nonclosable_element (
  GumboParser* parser
) {
  static const TagSet tags = {
    TAG(DD), TAG(DT), TAG(LI), TAG(OPTGROUP), TAG(OPTION), TAG(P), TAG(RB),
    TAG(RP), TAG(RT), TAG(RTC), TAG(TBODY), TAG(TD), TAG(TFOOT), TAG(TH),
    TAG(THEAD), TAG(TR), TAG(BODY), TAG(HTML),
  };
  GumboVector* open_elements = &parser->_parser_state->_open_elements;
  for (size_t i = 0; i < open_elements->length; ++i) {
    if (!node_tag_in_set(open_elements->data[i], &tags))
      return true;
  }
  return false;
}

// This factors out the clauses relating to "act as if an end tag token with tag
// name "table" had been seen. Returns true if there's a table element in table
// scope which was successfully closed, false if not and the token should be
// ignored. Does not add parse errors; callers should handle that.
static bool close_table(GumboParser* parser) {
  if (!has_an_element_in_table_scope(parser, GUMBO_TAG_TABLE)) {
    return false;
  }

  GumboNode* node = pop_current_node(parser);
  while (!node_html_tag_is(node, GUMBO_TAG_TABLE)) {
    node = pop_current_node(parser);
  }
  reset_insertion_mode_appropriately(parser);
  return true;
}

// This factors out the clauses relating to "act as if an end tag token with tag
// name `cell_tag` had been seen".
static void close_table_cell (
  GumboParser* parser,
  const GumboToken* token,
  GumboTag cell_tag
) {
  generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
  const GumboNode* node = get_current_node(parser);
  if (!node_html_tag_is(node, cell_tag))
    parser_add_parse_error(parser, token);
  do {
    node = pop_current_node(parser);
  } while (!node_html_tag_is(node, cell_tag));

  clear_active_formatting_elements(parser);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_ROW);
}

// https://html.spec.whatwg.org/multipage/parsing.html#close-the-cell
// This holds the logic to determine whether we should close a <td> or a <th>.
static void close_current_cell(GumboParser* parser, const GumboToken* token) {
  GumboTag cell_tag;
  if (has_an_element_in_table_scope(parser, GUMBO_TAG_TD)) {
    assert(!has_an_element_in_table_scope(parser, GUMBO_TAG_TH));
    cell_tag = GUMBO_TAG_TD;
  } else {
    assert(has_an_element_in_table_scope(parser, GUMBO_TAG_TH));
    cell_tag = GUMBO_TAG_TH;
  }
  close_table_cell(parser, token, cell_tag);
}

// This factors out the "act as if an end tag of tag name 'select' had been
// seen" clause of the spec, since it's referenced in several places. It pops
// all nodes from the stack until the current <select> has been closed, then
// resets the insertion mode appropriately.
static void close_current_select(GumboParser* parser) {
  GumboNode* node = pop_current_node(parser);
  while (!node_html_tag_is(node, GUMBO_TAG_SELECT)) {
    node = pop_current_node(parser);
  }
  reset_insertion_mode_appropriately(parser);
}

// The list of nodes in the "special" category:
// https://html.spec.whatwg.org/multipage/parsing.html#special
static bool is_special_node(const GumboNode* node) {
  assert(node->type == GUMBO_NODE_ELEMENT || node->type == GUMBO_NODE_TEMPLATE);
  return node_tag_in_set(node, &(const TagSet) {
      TAG(ADDRESS), TAG(APPLET), TAG(AREA), TAG(ARTICLE),
      TAG(ASIDE), TAG(BASE), TAG(BASEFONT), TAG(BGSOUND), TAG(BLOCKQUOTE),
      TAG(BODY), TAG(BR), TAG(BUTTON), TAG(CAPTION), TAG(CENTER), TAG(COL),
      TAG(COLGROUP), TAG(DD), TAG(DETAILS), TAG(DIR),
      TAG(DIV), TAG(DL), TAG(DT), TAG(EMBED), TAG(FIELDSET),
      TAG(FIGCAPTION), TAG(FIGURE), TAG(FOOTER), TAG(FORM), TAG(FRAME),
      TAG(FRAMESET), TAG(H1), TAG(H2), TAG(H3), TAG(H4), TAG(H5), TAG(H6),
      TAG(HEAD), TAG(HEADER), TAG(HGROUP), TAG(HR), TAG(HTML), TAG(IFRAME),
      TAG(IMG), TAG(INPUT), TAG(LI), TAG(LINK), TAG(LISTING),
      TAG(MARQUEE), TAG(MENU), TAG(META), TAG(NAV), TAG(NOEMBED),
      TAG(NOFRAMES), TAG(NOSCRIPT), TAG(OBJECT), TAG(OL), TAG(P),
      TAG(PARAM), TAG(PLAINTEXT), TAG(PRE), TAG(SCRIPT), TAG(SECTION),
      TAG(SELECT), TAG(STYLE), TAG(SUMMARY), TAG(TABLE), TAG(TBODY),
      TAG(TD), TAG(TEMPLATE), TAG(TEXTAREA), TAG(TFOOT), TAG(TH),
      TAG(THEAD), TAG(TR), TAG(UL), TAG(WBR), TAG(XMP),

      TAG_MATHML(MI), TAG_MATHML(MO), TAG_MATHML(MN), TAG_MATHML(MS),
      TAG_MATHML(MTEXT), TAG_MATHML(ANNOTATION_XML),

      TAG_SVG(FOREIGNOBJECT), TAG_SVG(DESC),

      // This TagSet needs to include the "title" element in both the
      // HTML and SVG namespaces. Using both TAG(TITLE) and TAG_SVG(TITLE)
      // won't work, due to the simplistic way in which the TAG macros are
      // implemented, so we do it like this instead:
      [GUMBO_TAG_TITLE] =
          (1 << GUMBO_NAMESPACE_HTML) |
          (1 << GUMBO_NAMESPACE_SVG)
    }
  );
}

// Implicitly closes currently open elements until it reaches an element with
// the
// specified qualified name. If the elements closed are in the set handled by
// generate_implied_end_tags, this is normal operation and this function returns
// true. Otherwise, a parse error is recorded and this function returns false.
static void implicitly_close_tags (
  GumboParser* parser,
  GumboToken* token,
  GumboNamespaceEnum target_ns,
  GumboTag target
) {
  assert(target != GUMBO_TAG_UNKNOWN);
  generate_implied_end_tags(parser, target, NULL);
  if (!node_qualified_tag_is(get_current_node(parser), target_ns, target)) {
    parser_add_parse_error(parser, token);
    while (
      !node_qualified_tag_is(get_current_node(parser), target_ns, target)
    ) {
      pop_current_node(parser);
    }
  }
  assert(node_qualified_tag_is(get_current_node(parser), target_ns, target));
  pop_current_node(parser);
}

// If the stack of open elements has a <p> tag in button scope, this acts as if
// a </p> tag was encountered, implicitly closing tags. Returns false if a
// parse error occurs. This is a convenience function because this particular
// clause appears several times in the spec.
static void maybe_implicitly_close_p_tag (
  GumboParser* parser,
  GumboToken* token
) {
  if (has_an_element_in_button_scope(parser, GUMBO_TAG_P)) {
    implicitly_close_tags (
      parser,
      token,
      GUMBO_NAMESPACE_HTML,
      GUMBO_TAG_P
    );
  }
}

// Convenience function to encapsulate the logic for closing <li> or <dd>/<dt>
// tags. Pass true to is_li for handling <li> tags, false for <dd> and <dt>.
static void maybe_implicitly_close_list_tag (
  GumboParser* parser,
  GumboToken* token,
  bool is_li
) {
  GumboParserState* state = parser->_parser_state;
  set_frameset_not_ok(parser);
  for (int i = state->_open_elements.length; --i >= 0;) {
    const GumboNode* node = state->_open_elements.data[i];
    bool is_list_tag = is_li
      ? node_html_tag_is(node, GUMBO_TAG_LI)
      : node_tag_in_set(node, &dd_dt_tags)
    ;
    if (is_list_tag) {
      implicitly_close_tags (
        parser,
        token,
        node->v.element.tag_namespace,
        node->v.element.tag
      );
      return;
    }

    if (
      is_special_node(node)
      && !node_tag_in_set(node, &(const TagSet){TAG(ADDRESS), TAG(DIV), TAG(P)})
    ) {
      return;
    }
  }
}

static void merge_attributes (
  GumboToken* token,
  GumboNode* node
) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  assert(node->type == GUMBO_NODE_ELEMENT);
  const GumboVector* token_attr = &token->v.start_tag.attributes;
  GumboVector* node_attr = &node->v.element.attributes;

  for (unsigned int i = 0; i < token_attr->length; ++i) {
    GumboAttribute* attr = token_attr->data[i];
    if (!gumbo_get_attribute(node_attr, attr->name)) {
      // Ownership of the attribute is transferred by this gumbo_vector_add,
      // so it has to be nulled out of the original token so it doesn't get
      // double-deleted.
      gumbo_vector_add(attr, node_attr);
      token_attr->data[i] = NULL;
    }
  }
  // When attributes are merged, it means the token has been ignored and merged
  // with another token, so we need to free its memory. The attributes that are
  // transferred need to be nulled-out in the vector above so that they aren't
  // double-deleted.
  gumbo_token_destroy(token);

#ifndef NDEBUG
  // Mark this sentinel so the assertion in the main loop knows it's been
  // destroyed.
  token->v.start_tag.attributes = kGumboEmptyVector;
#endif
}

const char* gumbo_normalize_svg_tagname(const GumboStringPiece* tag) {
  const StringReplacement *replacement = gumbo_get_svg_tag_replacement (
    tag->data,
    tag->length
  );
  return replacement ? replacement->to : NULL;
}

// https://html.spec.whatwg.org/multipage/parsing.html#adjust-foreign-attributes
// This destructively modifies any matching attributes on the token and sets the
// namespace appropriately.
static void adjust_foreign_attributes(GumboToken* token) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  const GumboVector* attributes = &token->v.start_tag.attributes;
  for (unsigned int i = 0, n = attributes->length; i < n; ++i) {
    GumboAttribute* attr = attributes->data[i];
    const ForeignAttrReplacement* entry = gumbo_get_foreign_attr_replacement (
      attr->name,
      strlen(attr->name)
    );
    if (!entry) {
      continue;
    }
    gumbo_free((void*) attr->name);
    attr->attr_namespace = entry->attr_namespace;
    attr->name = gumbo_strdup(entry->local_name);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inforeign
// This adjusts svg tags.
static void adjust_svg_tag(GumboToken* token) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  if (token->v.start_tag.tag == GUMBO_TAG_FOREIGNOBJECT) {
    assert(token->v.start_tag.name == NULL);
    token->v.start_tag.name = "foreignObject";
  } else if (token->v.start_tag.tag == GUMBO_TAG_UNKNOWN) {
    assert(token->v.start_tag.name);
    const StringReplacement *replacement = gumbo_get_svg_tag_replacement(
      token->v.start_tag.name,
      strlen(token->v.start_tag.name)
    );
    if (replacement) {
      // This cast is safe because we allocated this memory and we'll free it.
      strcpy((char *)token->v.start_tag.name, replacement->to);
    }
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#adjust-svg-attributes
// This destructively modifies any matching attributes on the token.
static void adjust_svg_attributes(GumboToken* token) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  const GumboVector* attributes = &token->v.start_tag.attributes;
  for (unsigned int i = 0, n = attributes->length; i < n; i++) {
    GumboAttribute* attr = (GumboAttribute*) attributes->data[i];
    const StringReplacement* replacement = gumbo_get_svg_attr_replacement (
      attr->name,
      attr->original_name.length
    );
    if (!replacement) {
      continue;
    }
    gumbo_free((void*) attr->name);
    attr->name = gumbo_strdup(replacement->to);
  }
}

// https://html.spec.whatwg.org/multipage/parsing.html#adjust-mathml-attributes
// Note that this may destructively modify the token with the new attribute
// value.
static void adjust_mathml_attributes(GumboToken* token) {
  assert(token->type == GUMBO_TOKEN_START_TAG);
  GumboAttribute* attr = gumbo_get_attribute (
    &token->v.start_tag.attributes,
    "definitionurl"
  );
  if (!attr) {
    return;
  }
  gumbo_free((void*) attr->name);
  attr->name = gumbo_strdup("definitionURL");
}

static void maybe_add_doctype_error (
  GumboParser* parser,
  const GumboToken* token
) {
  const GumboTokenDocType* doctype = &token->v.doc_type;
  if (
    strcmp(doctype->name, "html")
    || doctype->has_public_identifier
    || (doctype->has_system_identifier
        && strcmp(doctype->system_identifier, "about:legacy-compat"))
  ) {
    parser_add_parse_error(parser, token);
  }
}

static void remove_from_parent(GumboNode* node) {
  if (!node->parent) {
    // The node may not have a parent if, for example, it is a newly-cloned copy
    // of an active formatting element. DOM manipulations continue with the
    // orphaned fragment of the DOM tree until it's appended/foster-parented to
    // the common ancestor at the end of the adoption agency algorithm.
    return;
  }
  assert(node->parent->type == GUMBO_NODE_ELEMENT);
  GumboVector* children = &node->parent->v.element.children;
  int index = gumbo_vector_index_of(children, node);
  assert(index != -1);

  gumbo_vector_remove_at(index, children);
  node->parent = NULL;
  node->index_within_parent = -1;
  for (unsigned int i = index; i < children->length; ++i) {
    GumboNode* child = children->data[i];
    child->index_within_parent = i;
  }
}

// This is here to clean up memory when the spec says "Ignore current token."
static void ignore_token(GumboParser* parser) {
  GumboToken* token = parser->_parser_state->_current_token;
  // Ownership of the token's internal buffers are normally transferred to the
  // element, but if no element is emitted (as happens in non-verbatim-mode
  // when a token is ignored), we need to free it here to prevent a memory
  // leak.
  gumbo_token_destroy(token);
#ifndef NDEBUG
  if (token->type == GUMBO_TOKEN_START_TAG) {
    // Mark this sentinel so the assertion in the main loop knows it's been
    // destroyed.
    token->v.start_tag.attributes = kGumboEmptyVector;
    token->v.start_tag.name = NULL;
  }
#endif
}

// The token is usually an end tag; however, the adoption agency algorithm may
// invoke this for an 'a' or 'nobr' start tag.
// Returns false if there was an error.
static void in_body_any_other_end_tag(GumboParser* parser, GumboToken* token)
{
  GumboParserState* state = parser->_parser_state;
  GumboTag tag;
  const char* tagname;

  if (token->type == GUMBO_TOKEN_END_TAG) {
    tag = token->v.end_tag.tag;
    tagname = token->v.end_tag.name;
  } else {
    assert(token->type == GUMBO_TOKEN_START_TAG);
    tag = token->v.start_tag.tag;
    tagname = token->v.start_tag.name;
  }

  assert(state->_open_elements.length > 0);
  assert(node_html_tag_is(state->_open_elements.data[0], GUMBO_TAG_HTML));
  // Walk up the stack of open elements until we find one that either:
  // a) Matches the tag name we saw
  // b) Is in the "special" category.
  // If we see a), implicitly close everything up to and including it. If we
  // see b), then record a parse error, don't close anything (except the
  // implied end tags) and ignore the end tag token.
  for (int i = state->_open_elements.length; --i >= 0;) {
    const GumboNode* node = state->_open_elements.data[i];
    if (node_qualified_tagname_is(node, GUMBO_NAMESPACE_HTML, tag, tagname)) {
      generate_implied_end_tags(parser, tag, tagname);
      // <!DOCTYPE><body><sarcasm><foo></sarcasm> is an example of an error.
      // foo is the "current node" but sarcasm is node.
      // XXX: Write a test for this.
      if (node != get_current_node(parser)) {
        parser_add_parse_error(parser, token);
      }
      while (node != pop_current_node(parser))
        ;  // Pop everything.
      return;
    } else if (is_special_node(node)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
  }
  // <html> is in the special category, so we should never get here.
  assert(0 && "unreachable");
}

// https://html.spec.whatwg.org/multipage/parsing.html#an-introduction-to-error-handling-and-strange-cases-in-the-parser
// Also described in the "in body" handling for end formatting tags.
// Returns false if there was an error.
static void adoption_agency_algorithm(GumboParser* parser, GumboToken* token)
{
  GumboParserState* state = parser->_parser_state;
  gumbo_debug("Entering adoption agency algorithm.\n");
  // Step 1.
  GumboTag subject;
  if (token->type == GUMBO_TOKEN_START_TAG) {
    subject = token->v.start_tag.tag;
  } else {
    assert(token->type == GUMBO_TOKEN_END_TAG);
    subject = token->v.end_tag.tag;
  }
  assert(subject != GUMBO_TAG_UNKNOWN);

  // Step 2.
  GumboNode* current_node = get_current_node(parser);
  if (
    node_html_tag_is(current_node, subject)
    && -1 == gumbo_vector_index_of (
      &state->_active_formatting_elements,
      current_node
    )
  ) {
    pop_current_node(parser);
    return;
  }

  // Steps 3-5 & 21:
  for (unsigned int i = 0; i < 8; ++i) {
    // Step 6.
    GumboNode* formatting_node = NULL;
    int formatting_node_in_open_elements = -1;
    for (int j = state->_active_formatting_elements.length; --j >= 0;) {
      GumboNode* current_node = state->_active_formatting_elements.data[j];
      if (current_node == &kActiveFormattingScopeMarker) {
        gumbo_debug("Broke on scope marker; aborting.\n");
        // Last scope marker; abort the algorithm and handle according to "any
        // other end tag" (below).
        break;
      }
      if (node_html_tag_is(current_node, subject)) {
        // Found it.
        formatting_node = current_node;
        formatting_node_in_open_elements = gumbo_vector_index_of (
          &state->_open_elements,
          formatting_node
        );
        gumbo_debug (
          "Formatting element of tag %s at %d.\n",
          gumbo_normalized_tagname(subject),
          formatting_node_in_open_elements
        );
        break;
      }
    }
    if (!formatting_node) {
      // No matching tag; not a parse error outright, but fall through to the
      // "any other end tag" clause (which may potentially add a parse error,
      // but not always).
      gumbo_debug("No active formatting elements; aborting.\n");
      in_body_any_other_end_tag(parser, token);
      return;
    }

    // Step 7
    if (formatting_node_in_open_elements == -1) {
      gumbo_debug("Formatting node not on stack of open elements.\n");
      parser_add_parse_error(parser, token);
      gumbo_vector_remove (
        formatting_node,
        &state->_active_formatting_elements
      );
      return;
    }

    // Step 8
    if (!has_an_element_in_scope(parser, formatting_node->v.element.tag)) {
      parser_add_parse_error(parser, token);
      gumbo_debug("Element not in scope.\n");
      return;
    }

    // Step 9
    if (formatting_node != get_current_node(parser))
      parser_add_parse_error(parser, token);  // But continue onwards.
    assert(formatting_node);
    assert(!node_html_tag_is(formatting_node, GUMBO_TAG_HTML));
    assert(!node_html_tag_is(formatting_node, GUMBO_TAG_BODY));

    // Step 10
    GumboNode* furthest_block = NULL;
    for (
      unsigned int j = formatting_node_in_open_elements;
      j < state->_open_elements.length;
      ++j
    ) {
      assert(j > 0);
      GumboNode* current = state->_open_elements.data[j];
      if (is_special_node(current)) {
        furthest_block = current;
        break;
      }
    }
    // Step 11.
    if (!furthest_block) {
      while (pop_current_node(parser) != formatting_node)
        ;
      gumbo_vector_remove (
        formatting_node,
        &state->_active_formatting_elements
      );
      return;
    }
    assert(!node_html_tag_is(furthest_block, GUMBO_TAG_HTML));

    // Step 12.
    // Elements may be moved and reparented by this algorithm, so
    // common_ancestor is not necessarily the same as formatting_node->parent.
    GumboNode* common_ancestor = state->_open_elements.data [
      formatting_node_in_open_elements - 1
    ];
    gumbo_debug (
      "Common ancestor tag = %s, furthest block tag = %s.\n",
      gumbo_normalized_tagname(common_ancestor->v.element.tag),
      gumbo_normalized_tagname(furthest_block->v.element.tag)
    );

    // Step 13.
    int bookmark = 1 + gumbo_vector_index_of (
      &state->_active_formatting_elements,
      formatting_node
    );
    gumbo_debug("Bookmark at %d.\n", bookmark);
    // Step 14.
    GumboNode* node = furthest_block;
    GumboNode* last_node = furthest_block;
    // Must be stored explicitly, in case node is removed from the stack of open
    // elements, to handle step 14.3.
    int saved_node_index = gumbo_vector_index_of(&state->_open_elements, node);
    assert(saved_node_index > 0);
    // Step 14.1.
    for (int j = 0;;) {
      // Step 14.2.
      ++j;
      // Step 14.3.
      int node_index = gumbo_vector_index_of(&state->_open_elements, node);
      gumbo_debug (
        "Current index: %d, last index: %d.\n",
        node_index,
        saved_node_index
      );
      if (node_index == -1) {
        node_index = saved_node_index;
      }
      saved_node_index = --node_index;
      assert(node_index > 0);
      assert((unsigned int) node_index < state->_open_elements.capacity);
      node = state->_open_elements.data[node_index];
      assert(node->parent);
      // Step 14.4.
      if (node == formatting_node) {
        break;
      }
      int formatting_index = gumbo_vector_index_of (
        &state->_active_formatting_elements,
        node
      );
      // Step 14.5.
      if (j > 3 && formatting_index != -1) {
        gumbo_debug("Removing formatting element at %d.\n", formatting_index);
        gumbo_vector_remove_at (
          formatting_index,
          &state->_active_formatting_elements
        );
        // Removing the element shifts all indices over by one, so we may need
        // to move the bookmark.
        if (formatting_index < bookmark) {
          --bookmark;
          gumbo_debug("Moving bookmark to %d.\n", bookmark);
        }
        continue;
      }
      if (formatting_index == -1) {
        // Step 14.6.
        gumbo_vector_remove_at(node_index, &state->_open_elements);
        continue;
      }
      // Step 14.7.
      // "common ancestor as the intended parent" doesn't actually mean insert
      // it into the common ancestor; that happens below.
      node = clone_node(node, GUMBO_INSERTION_ADOPTION_AGENCY_CLONED);
      assert(formatting_index >= 0);
      state->_active_formatting_elements.data[formatting_index] = node;
      assert(node_index >= 0);
      state->_open_elements.data[node_index] = node;
      // Step 14.8.
      if (last_node == furthest_block) {
        bookmark = formatting_index + 1;
        gumbo_debug("Bookmark moved to %d.\n", bookmark);
        assert((unsigned int) bookmark <= state->_active_formatting_elements.length);
      }
      // Step 14.9.
      last_node->parse_flags |= GUMBO_INSERTION_ADOPTION_AGENCY_MOVED;
      remove_from_parent(last_node);
      append_node(node, last_node);
      // Step 14.10.
      last_node = node;
    }  // Step 14.11.

    // Step 15.
    gumbo_debug (
      "Removing %s node from parent ",
      gumbo_normalized_tagname(last_node->v.element.tag)
    );
    remove_from_parent(last_node);
    last_node->parse_flags |= GUMBO_INSERTION_ADOPTION_AGENCY_MOVED;
    InsertionLocation location = get_appropriate_insertion_location (
      parser,
      common_ancestor
    );
    gumbo_debug (
      "and inserting it into %s.\n",
      gumbo_normalized_tagname(location.target->v.element.tag)
    );
    insert_node(last_node, location);

    // Step 16.
    GumboNode* new_formatting_node = clone_node (
      formatting_node,
      GUMBO_INSERTION_ADOPTION_AGENCY_CLONED
    );
    formatting_node->parse_flags |= GUMBO_INSERTION_IMPLICIT_END_TAG;

    // Step 17. Instead of appending nodes one-by-one, we swap the children
    // vector of furthest_block with the empty children of new_formatting_node,
    // reducing memory traffic and allocations. We still have to reset their
    // parent pointers, though.
    GumboVector temp = new_formatting_node->v.element.children;
    new_formatting_node->v.element.children = furthest_block->v.element.children;
    furthest_block->v.element.children = temp;

    temp = new_formatting_node->v.element.children;
    for (unsigned int i = 0; i < temp.length; ++i) {
      GumboNode* child = temp.data[i];
      child->parent = new_formatting_node;
    }

    // Step 18.
    append_node(furthest_block, new_formatting_node);

    // Step 19.
    // If the formatting node was before the bookmark, it may shift over all
    // indices after it, so we need to explicitly find the index and possibly
    // adjust the bookmark.
    int formatting_node_index = gumbo_vector_index_of (
      &state->_active_formatting_elements,
      formatting_node
    );
    assert(formatting_node_index != -1);
    if (formatting_node_index < bookmark) {
      gumbo_debug (
        "Formatting node at %d is before bookmark at %d; decrementing.\n",
        formatting_node_index, bookmark
      );
      --bookmark;
    }
    gumbo_vector_remove_at (
      formatting_node_index,
      &state->_active_formatting_elements
    );
    assert(bookmark >= 0);
    assert((unsigned int) bookmark <= state->_active_formatting_elements.length);
    gumbo_vector_insert_at (
      new_formatting_node,
      bookmark,
      &state->_active_formatting_elements
    );

    // Step 20.
    gumbo_vector_remove(formatting_node, &state->_open_elements);
    int insert_at = 1 + gumbo_vector_index_of (
      &state->_open_elements,
      furthest_block
    );
    assert(insert_at >= 0);
    assert((unsigned int) insert_at <= state->_open_elements.length);
    gumbo_vector_insert_at (
      new_formatting_node,
      insert_at,
      &state->_open_elements
    );
  }  // Step 21.
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-end
static void finish_parsing(GumboParser* parser) {
  gumbo_debug("Finishing parsing");
  maybe_flush_text_node_buffer(parser);
  GumboParserState* state = parser->_parser_state;
  for (
    GumboNode* node = pop_current_node(parser);
    node;
    node = pop_current_node(parser)
  ) {
    if (
      (node_html_tag_is(node, GUMBO_TAG_BODY) && state->_closed_body_tag)
      || (node_html_tag_is(node, GUMBO_TAG_HTML) && state->_closed_html_tag)
    ) {
      continue;
    }
    node->parse_flags |= GUMBO_INSERTION_IMPLICIT_END_TAG;
  }
  while (pop_current_node(parser))
    ;  // Pop them all.
}

static void handle_initial(GumboParser* parser, GumboToken* token) {
  GumboDocument* document = &get_document_node(parser)->v.document;
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_document_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    document->has_doctype = true;
    document->name = token->v.doc_type.name;
    document->public_identifier = token->v.doc_type.public_identifier;
    document->system_identifier = token->v.doc_type.system_identifier;
    document->doc_type_quirks_mode = compute_quirks_mode(&token->v.doc_type);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_BEFORE_HTML);
    maybe_add_doctype_error(parser, token);
    return;
  }
  parser_add_parse_error(parser, token);
  document->doc_type_quirks_mode = GUMBO_DOCTYPE_QUIRKS;
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_BEFORE_HTML);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-before-html-insertion-mode
static void handle_before_html(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_document_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    GumboNode* html_node = insert_element_from_token(parser, token);
    parser->_output->root = html_node;
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_BEFORE_HEAD);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_END_TAG
    && !tag_in(token, false, &(const TagSet){TAG(HEAD), TAG(BODY), TAG(HTML), TAG(BR)})
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  GumboNode* html_node = insert_element_of_tag_type (
    parser,
    GUMBO_TAG_HTML,
    GUMBO_INSERTION_IMPLIED
  );
  assert(html_node);
  parser->_output->root = html_node;
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_BEFORE_HEAD);
  parser->_parser_state->_reprocess_current_token = true;
}

// Forward declarations because of mutual dependencies.
static void handle_token(GumboParser* parser, GumboToken* token);
static void handle_in_body(GumboParser* parser, GumboToken* token);
static void handle_in_template(GumboParser* parser, GumboToken* token);

// https://html.spec.whatwg.org/multipage/parsing.html#the-before-head-insertion-mode
static void handle_before_head(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HEAD)) {
    GumboNode* node = insert_element_from_token(parser, token);
    parser->_parser_state->_head_element = node;
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_HEAD);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_END_TAG
    && !tag_in(token, kEndTag, &(const TagSet){TAG(HEAD), TAG(BODY), TAG(HTML), TAG(BR)})
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  GumboNode* node = insert_element_of_tag_type (
    parser,
    GUMBO_TAG_HEAD,
    GUMBO_INSERTION_IMPLIED
  );
  parser->_parser_state->_head_element = node;
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_HEAD);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inhead
static void handle_in_head(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    return handle_in_body(parser, token);
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(BASE), TAG(BASEFONT), TAG(BGSOUND), TAG(LINK)
    })
  ) {
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_META)) {
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    // NOTE(jdtang): Gumbo handles only UTF-8, so the encoding clause of the
    // spec doesn't apply. If clients want to handle meta-tag re-encoding, they
    // should specifically look for that string in the document and re-encode it
    // before passing to Gumbo.
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TITLE)) {
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RCDATA);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(NOFRAMES), TAG(STYLE)})
  ) {
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RAWTEXT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOSCRIPT)) {
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_HEAD_NOSCRIPT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_SCRIPT)) {
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_SCRIPT_DATA);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_HEAD)) {
    GumboNode* head = pop_current_node(parser);
    UNUSED_IF_NDEBUG(head);
    assert(node_html_tag_is(head, GUMBO_TAG_HEAD));
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_HEAD);
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet){TAG(BODY), TAG(HTML), TAG(BR)})
  ) {
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_HEAD);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TEMPLATE)) {
    insert_element_from_token(parser, token);
    add_formatting_element(parser, &kActiveFormattingScopeMarker);
    set_frameset_not_ok(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TEMPLATE);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TEMPLATE);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)) {
    if (!has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    generate_all_implied_end_tags_thoroughly(parser);
    if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_TEMPLATE))
      parser_add_parse_error(parser, token);
    while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_TEMPLATE))
      ;
    clear_active_formatting_elements(parser);
    pop_template_insertion_mode(parser);
    reset_insertion_mode_appropriately(parser);
    return;
  }
  if (
    tag_is(token, kStartTag, GUMBO_TAG_HEAD)
    || (token->type == GUMBO_TOKEN_END_TAG)
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  pop_current_node(parser);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_HEAD);
  parser->_parser_state->_reprocess_current_token = true;
  return;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inheadnoscript
static void handle_in_head_noscript(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_NOSCRIPT)) {
    const GumboNode* node = pop_current_node(parser);
    assert(node_html_tag_is(node, GUMBO_TAG_NOSCRIPT));
    UNUSED_IF_NDEBUG(node);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_HEAD);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_WHITESPACE
    || token->type == GUMBO_TOKEN_COMMENT
    || tag_in (token, kStartTag, &(const TagSet) {
      TAG(BASEFONT), TAG(BGSOUND), TAG(LINK),
      TAG(META), TAG(NOFRAMES), TAG(STYLE)
    })
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(HEAD), TAG(NOSCRIPT)})
    || (
      token->type == GUMBO_TOKEN_END_TAG
      && !tag_is(token, kEndTag, GUMBO_TAG_BR)
    )
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  parser_add_parse_error(parser, token);
  const GumboNode* node = pop_current_node(parser);
  assert(node_html_tag_is(node, GUMBO_TAG_NOSCRIPT));
  UNUSED_IF_NDEBUG(node);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_HEAD);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-after-head-insertion-mode
static void handle_after_head(GumboParser* parser, GumboToken* token) {
  GumboParserState* state = parser->_parser_state;
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_BODY)) {
    insert_element_from_token(parser, token);
    set_frameset_not_ok(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FRAMESET)) {
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_FRAMESET);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(BASE), TAG(BASEFONT), TAG(BGSOUND), TAG(LINK), TAG(META),
      TAG(NOFRAMES), TAG(SCRIPT), TAG(STYLE), TAG(TEMPLATE), TAG(TITLE)
    })
  ) {
    parser_add_parse_error(parser, token);
    assert(state->_head_element != NULL);
    // This must be flushed before we push the head element on, as there may be
    // pending character tokens that should be attached to the root.
    maybe_flush_text_node_buffer(parser);
    gumbo_vector_add(state->_head_element, &state->_open_elements);
    handle_in_head(parser, token);
    gumbo_vector_remove(state->_head_element, &state->_open_elements);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)) {
    handle_in_head(parser, token);
    return;
  }
  if (
    tag_is(token, kStartTag, GUMBO_TAG_HEAD)
    || (
      token->type == GUMBO_TOKEN_END_TAG
      && !tag_in(token, kEndTag, &(const TagSet){TAG(BODY), TAG(HTML), TAG(BR)})
    )
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  insert_element_of_tag_type(parser, GUMBO_TAG_BODY, GUMBO_INSERTION_IMPLIED);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
  state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inbody
static void handle_in_body(GumboParser* parser, GumboToken* token) {
  GumboParserState* state = parser->_parser_state;
  assert(state->_open_elements.length > 0);
  if (token->type == GUMBO_TOKEN_NULL) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    reconstruct_active_formatting_elements(parser);
    insert_text_token(parser, token);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_CHARACTER
    || token->type == GUMBO_TOKEN_CDATA
  ) {
    reconstruct_active_formatting_elements(parser);
    insert_text_token(parser, token);
    set_frameset_not_ok(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    parser_add_parse_error(parser, token);
    if (has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      ignore_token(parser);
      return;
    }
    assert(parser->_output->root != NULL);
    assert(parser->_output->root->type == GUMBO_NODE_ELEMENT);
    merge_attributes(token, parser->_output->root);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(BASE), TAG(BASEFONT), TAG(BGSOUND), TAG(LINK),
      TAG(META), TAG(NOFRAMES), TAG(SCRIPT), TAG(STYLE), TAG(TEMPLATE),
      TAG(TITLE)
    })
    || tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_BODY)) {
    parser_add_parse_error(parser, token);
    if (
      state->_open_elements.length < 2
      || !node_html_tag_is(state->_open_elements.data[1], GUMBO_TAG_BODY)
      || has_open_element(parser, GUMBO_TAG_TEMPLATE)
    ) {
      ignore_token(parser);
    } else {
      set_frameset_not_ok(parser);
      merge_attributes(token, state->_open_elements.data[1]);
    }
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FRAMESET)) {
    parser_add_parse_error(parser, token);
    if (
      state->_open_elements.length < 2
      || !node_html_tag_is(state->_open_elements.data[1], GUMBO_TAG_BODY)
      || !state->_frameset_ok
    ) {
      ignore_token(parser);
      return;
    }
    // Save the body node for later removal.
    GumboNode* body_node = state->_open_elements.data[1];

    // Pop all nodes except root HTML element.
    GumboNode* node;
    do {
      node = pop_current_node(parser);
    } while (node != state->_open_elements.data[1]);

    // Removing & destroying the body node is going to kill any nodes that have
    // been added to the list of active formatting elements, and so we should
    // clear it to prevent a use-after-free if the list of active formatting
    // elements is reconstructed afterwards. This may happen if whitespace
    // follows the </frameset>.
    clear_active_formatting_elements(parser);

    // Remove the body node. We may want to factor this out into a generic
    // helper, but right now this is the only code that needs to do this.
    GumboVector* children = &parser->_output->root->v.element.children;
    for (unsigned int i = 0; i < children->length; ++i) {
      if (children->data[i] == body_node) {
        gumbo_vector_remove_at(i, children);
        break;
      }
    }
    destroy_node(body_node);

    // Insert the <frameset>, and switch the insertion mode.
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_FRAMESET);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    if (get_current_template_insertion_mode(parser) !=
        GUMBO_INSERTION_MODE_INITIAL) {
      handle_in_template(parser, token);
      return;
    }
    if (stack_contains_nonclosable_element(parser))
      parser_add_parse_error(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_BODY)) {
    if (!has_an_element_in_scope(parser, GUMBO_TAG_BODY)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    if (stack_contains_nonclosable_element(parser))
      parser_add_parse_error(parser, token);
    GumboNode* body = state->_open_elements.data[1];
    assert(node_html_tag_is(body, GUMBO_TAG_BODY));
    record_end_of_element(state->_current_token, &body->v.element);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_BODY);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_HTML)) {
    if (!has_an_element_in_scope(parser, GUMBO_TAG_BODY)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    if (stack_contains_nonclosable_element(parser))
      parser_add_parse_error(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_BODY);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(ADDRESS), TAG(ARTICLE), TAG(ASIDE), TAG(BLOCKQUOTE), TAG(CENTER),
      TAG(DETAILS), TAG(DIALOG), TAG(DIR), TAG(DIV), TAG(DL), TAG(FIELDSET),
      TAG(FIGCAPTION), TAG(FIGURE), TAG(FOOTER), TAG(HEADER), TAG(HGROUP),
      TAG(MAIN), TAG(MENU), TAG(NAV), TAG(OL), TAG(P), TAG(SECTION),
      TAG(SUMMARY), TAG(UL)
    })
  ) {
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_in(token, kStartTag, &heading_tags)) {
    maybe_implicitly_close_p_tag(parser, token);
    if (node_tag_in_set(get_current_node(parser), &heading_tags)) {
      parser_add_parse_error(parser, token);
      pop_current_node(parser);
    }
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_in(token, kStartTag, &(const TagSet){TAG(PRE), TAG(LISTING)})) {
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    state->_ignore_next_linefeed = true;
    set_frameset_not_ok(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FORM)) {
    if (
      state->_form_element != NULL
      && !has_open_element(parser, GUMBO_TAG_TEMPLATE)
    ) {
      gumbo_debug("Ignoring nested form.\n");
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    maybe_implicitly_close_p_tag(parser, token);
    GumboNode* form_element = insert_element_from_token(parser, token);
    if (!has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      state->_form_element = form_element;
    }
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_LI)) {
    maybe_implicitly_close_list_tag(parser, token, true);
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_in(token, kStartTag, &dd_dt_tags)) {
    maybe_implicitly_close_list_tag(parser, token, false);
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_PLAINTEXT)) {
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    gumbo_tokenizer_set_state(parser, GUMBO_LEX_PLAINTEXT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_BUTTON)) {
    if (has_an_element_in_scope(parser, GUMBO_TAG_BUTTON)) {
      parser_add_parse_error(parser, token);
      // We don't want to use implicitly_close_tags here because it may add an
      // error and we've already added the only error the standard specifies.
      generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
      while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_BUTTON))
        ;
    }
    reconstruct_active_formatting_elements(parser);
    insert_element_from_token(parser, token);
    set_frameset_not_ok(parser);
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(ADDRESS), TAG(ARTICLE), TAG(ASIDE), TAG(BLOCKQUOTE), TAG(BUTTON),
      TAG(CENTER), TAG(DETAILS), TAG(DIALOG), TAG(DIR), TAG(DIV), TAG(DL),
      TAG(FIELDSET), TAG(FIGCAPTION), TAG(FIGURE), TAG(FOOTER), TAG(HEADER),
      TAG(HGROUP), TAG(LISTING), TAG(MAIN), TAG(MENU), TAG(NAV), TAG(OL),
      TAG(PRE), TAG(SECTION), TAG(SUMMARY), TAG(UL)
    })
  ) {
    GumboTag tag = token->v.end_tag.tag;
    if (!has_an_element_in_scope(parser, tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    return implicitly_close_tags (
      parser,
      token,
      GUMBO_NAMESPACE_HTML,
      token->v.end_tag.tag
    );
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_FORM)) {
    if (has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      if (!has_an_element_in_scope(parser, GUMBO_TAG_FORM)) {
        parser_add_parse_error(parser, token);
        ignore_token(parser);
        return;
      }
      generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
      if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_FORM))
        parser_add_parse_error(parser, token);
      while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_FORM))
        ;
      return;
    } else {
      GumboNode* node = state->_form_element;
      assert(!node || node->type == GUMBO_NODE_ELEMENT);
      state->_form_element = NULL;
      if (!node || !has_node_in_scope(parser, node)) {
        gumbo_debug("Closing an unopened form.\n");
        parser_add_parse_error(parser, token);
        ignore_token(parser);
        return;
      }
      // This differs from implicitly_close_tags because we remove *only* the
      // <form> element; other nodes are left in scope.
      generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
      if (get_current_node(parser) != node)
        parser_add_parse_error(parser, token);
      else
        record_end_of_element(token, &node->v.element);

      GumboVector* open_elements = &state->_open_elements;
      int index = gumbo_vector_index_of(open_elements, node);
      assert(index >= 0);
      gumbo_vector_remove_at(index, open_elements);
      return;
    }
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_P)) {
    if (!has_an_element_in_button_scope(parser, GUMBO_TAG_P)) {
      parser_add_parse_error(parser, token);
      // reconstruct_active_formatting_elements(parser);
      insert_element_of_tag_type (
        parser,
        GUMBO_TAG_P,
        GUMBO_INSERTION_CONVERTED_FROM_END_TAG
      );
    }
    implicitly_close_tags (
      parser,
      token,
      GUMBO_NAMESPACE_HTML,
      GUMBO_TAG_P
    );
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_LI)) {
    if (!has_an_element_in_list_scope(parser, GUMBO_TAG_LI)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    implicitly_close_tags (
      parser,
      token,
      GUMBO_NAMESPACE_HTML,
      GUMBO_TAG_LI
    );
    return;
  }
  if (tag_in(token, kEndTag, &dd_dt_tags)) {
    GumboTag token_tag = token->v.end_tag.tag;
    if (!has_an_element_in_scope(parser, token_tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    implicitly_close_tags (
      parser,
      token,
      GUMBO_NAMESPACE_HTML,
      token_tag
    );
    return;
  }
  if (tag_in(token, kEndTag, &heading_tags)) {
    if (
      !has_an_element_in_scope_with_tagname(parser, 6, (GumboTag[]) {
        GUMBO_TAG_H1, GUMBO_TAG_H2, GUMBO_TAG_H3, GUMBO_TAG_H4,
        GUMBO_TAG_H5, GUMBO_TAG_H6
      })
    ) {
      // No heading open; ignore the token entirely.
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
    const GumboNode* current_node = get_current_node(parser);
    if (!node_html_tag_is(current_node, token->v.end_tag.tag)) {
      // There're children of the heading currently open; close them below and
      // record a parse error.
      // TODO(jdtang): Add a way to distinguish this error case from the one
      // above.
      parser_add_parse_error(parser, token);
    }
    do {
      current_node = pop_current_node(parser);
    } while (!node_tag_in_set(current_node, &heading_tags));
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_A)) {
    int last_a;
    int has_matching_a = find_last_anchor_index(parser, &last_a);
    if (has_matching_a) {
      assert(has_matching_a == 1);
      parser_add_parse_error(parser, token);
      (void)adoption_agency_algorithm(parser, token);
      // The adoption agency algorithm usually removes all instances of <a>
      // from the list of active formatting elements, but in case it doesn't,
      // we're supposed to do this. (The conditions where it might not are
      // listed in the spec.)
      if (find_last_anchor_index(parser, &last_a)) {
        void* last_element = gumbo_vector_remove_at (
          last_a,
          &state->_active_formatting_elements
        );
        gumbo_vector_remove(last_element, &state->_open_elements);
      }
    }
    reconstruct_active_formatting_elements(parser);
    add_formatting_element(parser, insert_element_from_token(parser, token));
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(B), TAG(BIG), TAG(CODE), TAG(EM), TAG(FONT), TAG(I), TAG(S),
      TAG(SMALL), TAG(STRIKE), TAG(STRONG), TAG(TT), TAG(U)
    })
  ) {
    reconstruct_active_formatting_elements(parser);
    add_formatting_element(parser, insert_element_from_token(parser, token));
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOBR)) {
    reconstruct_active_formatting_elements(parser);
    if (has_an_element_in_scope(parser, GUMBO_TAG_NOBR)) {
      parser_add_parse_error(parser, token);
      adoption_agency_algorithm(parser, token);
      reconstruct_active_formatting_elements(parser);
    }
    insert_element_from_token(parser, token);
    add_formatting_element(parser, get_current_node(parser));
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(A), TAG(B), TAG(BIG), TAG(CODE), TAG(EM), TAG(FONT), TAG(I),
      TAG(NOBR), TAG(S), TAG(SMALL), TAG(STRIKE), TAG(STRONG), TAG(TT),
      TAG(U)
    })
  ) {
    adoption_agency_algorithm(parser, token);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(APPLET), TAG(MARQUEE), TAG(OBJECT)})
  ) {
    reconstruct_active_formatting_elements(parser);
    insert_element_from_token(parser, token);
    add_formatting_element(parser, &kActiveFormattingScopeMarker);
    set_frameset_not_ok(parser);
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet){TAG(APPLET), TAG(MARQUEE), TAG(OBJECT)})
  ) {
    GumboTag token_tag = token->v.end_tag.tag;
    if (!has_an_element_in_scope(parser, token_tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    implicitly_close_tags(parser, token, GUMBO_NAMESPACE_HTML, token_tag);
    clear_active_formatting_elements(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TABLE)) {
    if (
      get_document_node(parser)->v.document.doc_type_quirks_mode
        != GUMBO_DOCTYPE_QUIRKS
    ) {
      maybe_implicitly_close_p_tag(parser, token);
    }
    insert_element_from_token(parser, token);
    set_frameset_not_ok(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_BR)) {
    parser_add_parse_error(parser, token);
    reconstruct_active_formatting_elements(parser);
    insert_element_of_tag_type (
      parser,
      GUMBO_TAG_BR,
      GUMBO_INSERTION_CONVERTED_FROM_END_TAG
    );
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    set_frameset_not_ok(parser);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(AREA), TAG(BR), TAG(EMBED), TAG(IMG), TAG(IMAGE), TAG(KEYGEN),
      TAG(WBR)
    })
  ) {
    bool is_image = tag_is(token, kStartTag, GUMBO_TAG_IMAGE);
    if (is_image) {
      parser_add_parse_error(parser, token);
      token->v.start_tag.tag = GUMBO_TAG_IMG;
    }
    reconstruct_active_formatting_elements(parser);
    GumboNode* node = insert_element_from_token(parser, token);
    if (is_image)
      node->parse_flags |= GUMBO_INSERTION_FROM_IMAGE;
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    set_frameset_not_ok(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_INPUT)) {
    reconstruct_active_formatting_elements(parser);
    GumboNode *input = insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    if (!attribute_matches(&input->v.element.attributes, "type", "hidden"))
      set_frameset_not_ok(parser);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(PARAM), TAG(SOURCE), TAG(TRACK)})
  ) {
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HR)) {
    maybe_implicitly_close_p_tag(parser, token);
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    set_frameset_not_ok(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TEXTAREA)) {
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RCDATA);
    parser->_parser_state->_ignore_next_linefeed = true;
    set_frameset_not_ok(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_XMP)) {
    maybe_implicitly_close_p_tag(parser, token);
    reconstruct_active_formatting_elements(parser);
    set_frameset_not_ok(parser);
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RAWTEXT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_IFRAME)) {
    set_frameset_not_ok(parser);
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RAWTEXT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOEMBED)) {
    run_generic_parsing_algorithm(parser, token, GUMBO_LEX_RAWTEXT);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_SELECT)) {
    reconstruct_active_formatting_elements(parser);
    insert_element_from_token(parser, token);
    set_frameset_not_ok(parser);
    GumboInsertionMode state = parser->_parser_state->_insertion_mode;
    if (
      state == GUMBO_INSERTION_MODE_IN_TABLE
      || state == GUMBO_INSERTION_MODE_IN_CAPTION
      || state == GUMBO_INSERTION_MODE_IN_TABLE_BODY
      || state == GUMBO_INSERTION_MODE_IN_ROW
      || state == GUMBO_INSERTION_MODE_IN_CELL
    ) {
      set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_SELECT_IN_TABLE);
    } else {
      set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_SELECT);
    }
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(OPTGROUP), TAG(OPTION)})
  ) {
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTION)) {
      pop_current_node(parser);
    }
    reconstruct_active_formatting_elements(parser);
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_in(token, kStartTag, &(const TagSet){TAG(RB), TAG(RTC)})) {
    if (has_an_element_in_scope(parser, GUMBO_TAG_RUBY)) {
      generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
      if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_RUBY))
        parser_add_parse_error(parser, token);
    }
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_in(token, kStartTag, &(const TagSet){TAG(RP), TAG(RT)})) {
    if (has_an_element_in_scope(parser, GUMBO_TAG_RUBY)) {
      generate_implied_end_tags(parser, GUMBO_TAG_RTC, NULL);
      GumboNode* current = get_current_node(parser);
      if (!node_html_tag_is(current, GUMBO_TAG_RUBY) &&
          !node_html_tag_is(current, GUMBO_TAG_RTC)) {
        parser_add_parse_error(parser, token);
      }
    }
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_MATH)) {
    reconstruct_active_formatting_elements(parser);
    adjust_mathml_attributes(token);
    adjust_foreign_attributes(token);
    insert_foreign_element(parser, token, GUMBO_NAMESPACE_MATHML);
    if (token->v.start_tag.is_self_closing) {
      pop_current_node(parser);
      acknowledge_self_closing_tag(parser);
    }
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_SVG)) {
    reconstruct_active_formatting_elements(parser);
    adjust_svg_attributes(token);
    adjust_foreign_attributes(token);
    insert_foreign_element(parser, token, GUMBO_NAMESPACE_SVG);
    if (token->v.start_tag.is_self_closing) {
      pop_current_node(parser);
      acknowledge_self_closing_tag(parser);
    }
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(FRAME), TAG(HEAD),
      TAG(TBODY), TAG(TD), TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_START_TAG) {
    reconstruct_active_formatting_elements(parser);
    insert_element_from_token(parser, token);
    return;
  }
  in_body_any_other_end_tag(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incdata
static void handle_text(GumboParser* parser, GumboToken* token) {
  if (
    token->type == GUMBO_TOKEN_CHARACTER
    || token->type == GUMBO_TOKEN_WHITESPACE
  ) {
    insert_text_token(parser, token);
    return;
  }
  // We provide only bare-bones script handling that doesn't involve any of
  // the parser-pause/already-started/script-nesting flags or re-entrant
  // invocations of the tokenizer. Because the intended usage of this library
  // is mostly for templating, refactoring, and static-analysis libraries, we
  // provide the script body as a text-node child of the <script> element.
  // This behavior doesn't support document.write of partial HTML elements,
  // but should be adequate for almost all other scripting support.
  if (token->type == GUMBO_TOKEN_EOF) {
    parser_add_parse_error(parser, token);
    parser->_parser_state->_reprocess_current_token = true;
  }
  pop_current_node(parser);
  set_insertion_mode(parser, parser->_parser_state->_original_insertion_mode);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intable
static void handle_in_table(GumboParser* parser, GumboToken* token) {
  GumboParserState* state = parser->_parser_state;
  if (
    (token->type == GUMBO_TOKEN_CHARACTER
     || token->type == GUMBO_TOKEN_WHITESPACE
     || token->type == GUMBO_TOKEN_NULL)
    && node_tag_in_set(get_current_node(parser), &(const TagSet) {
      TAG(TABLE), TAG(TBODY), TAG(TFOOT), TAG(THEAD), TAG(TR)
    })
  ) {
    // The "pending table character tokens" list described in the spec is
    // nothing more than the TextNodeBufferState. We accumulate text tokens as
    // normal, except that when we go to flush them in the handle_in_table_text,
    // we set _foster_parent_insertions if there're non-whitespace characters in
    // the buffer.
    assert(state->_text_node._buffer.length == 0);
    assert(state->_table_character_tokens.length == 0);
    state->_original_insertion_mode = state->_insertion_mode;
    state->_reprocess_current_token = true;
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_TEXT);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_CAPTION)) {
    clear_stack_to_table_context(parser);
    add_formatting_element(parser, &kActiveFormattingScopeMarker);
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_CAPTION);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_COLGROUP)) {
    clear_stack_to_table_context(parser);
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_COLUMN_GROUP);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_COL)) {
    clear_stack_to_table_context(parser);
    insert_element_of_tag_type (
      parser,
      GUMBO_TAG_COLGROUP,
      GUMBO_INSERTION_IMPLIED
    );
    state->_reprocess_current_token = true;
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_COLUMN_GROUP);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(TBODY), TAG(TFOOT), TAG(THEAD)
    })
  ) {
    clear_stack_to_table_context(parser);
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(TD), TAG(TH), TAG(TR)
    })
  ) {
    clear_stack_to_table_context(parser);
    insert_element_of_tag_type (
      parser,
      GUMBO_TAG_TBODY,
      GUMBO_INSERTION_IMPLIED
    );
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    state->_reprocess_current_token = true;
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TABLE)) {
    parser_add_parse_error(parser, token);
    if (close_table(parser)) {
      state->_reprocess_current_token = true;
    } else {
      ignore_token(parser);
    }
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_TABLE)) {
    if (!close_table(parser)) {
      parser_add_parse_error(parser, token);
      return;
    }
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(BODY), TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(HTML),
      TAG(TBODY), TAG(TD), TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(STYLE), TAG(SCRIPT), TAG(TEMPLATE)})
    || (tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE))
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (
    tag_is(token, kStartTag, GUMBO_TAG_INPUT)
    && attribute_matches(&token->v.start_tag.attributes, "type", "hidden")
  ) {
    parser_add_parse_error(parser, token);
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FORM)) {
    parser_add_parse_error(parser, token);
    if (state->_form_element || has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      ignore_token(parser);
      return;
    }
    state->_form_element = insert_element_from_token(parser, token);
    pop_current_node(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    handle_in_body(parser, token);
    return;
  }
  // foster-parenting-start-tag or foster-parenting-end-tag error
  parser_add_parse_error(parser, token);
  state->_foster_parent_insertions = true;
  handle_in_body(parser, token);
  state->_foster_parent_insertions = false;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intabletext
static void handle_in_table_text(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_NULL) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  GumboParserState* state = parser->_parser_state;
  // Non-whitespace tokens will cause parse errors later.
  // It's not entirely clear from the spec how this is supposed to work.
  // https://github.com/whatwg/html/issues/4046
  if (token->type == GUMBO_TOKEN_WHITESPACE
      || token->type == GUMBO_TOKEN_CHARACTER) {
    insert_text_token(parser, token);
    gumbo_character_token_buffer_append(token, &state->_table_character_tokens);
    return;
  }

  GumboCharacterTokenBuffer* buffer = &state->_table_character_tokens;
  if (state->_text_node._type != GUMBO_NODE_WHITESPACE) {
    // Each character in buffer is an error. Unfortunately, that means we need
    // to emit a bunch of errors at the appropriate locations.
    for (size_t i = 0, n = buffer->length; i < n; ++i) {
      GumboToken tok;
      gumbo_character_token_buffer_get(buffer, i, &tok);
      // foster-parenting-character error
      parser_add_parse_error(parser, &tok);
    }
    state->_foster_parent_insertions = true;
    set_frameset_not_ok(parser);
    reconstruct_active_formatting_elements(parser);
  }
  maybe_flush_text_node_buffer(parser);
  gumbo_character_token_buffer_clear(buffer);
  state->_foster_parent_insertions = false;
  state->_reprocess_current_token = true;
  state->_insertion_mode = state->_original_insertion_mode;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incaption
static void handle_in_caption(GumboParser* parser, GumboToken* token) {
  if (tag_is(token, kEndTag, GUMBO_TAG_CAPTION)) {
    if (!has_an_element_in_table_scope(parser, GUMBO_TAG_CAPTION)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
    if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_CAPTION))
      parser_add_parse_error(parser, token);
    while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_CAPTION))
      ;
    clear_active_formatting_elements(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(TBODY), TAG(TD),
      TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
    })
    || (tag_is(token, kEndTag, GUMBO_TAG_TABLE))
  ) {
    if (!has_an_element_in_table_scope(parser, GUMBO_TAG_CAPTION)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    generate_implied_end_tags(parser, GUMBO_TAG_LAST, NULL);
    if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_CAPTION))
      parser_add_parse_error(parser, token);
    while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_CAPTION))
      ;
    clear_active_formatting_elements(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(BODY), TAG(COL), TAG(COLGROUP), TAG(HTML), TAG(TBODY), TAG(TD),
      TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  handle_in_body(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incolgroup
static void handle_in_column_group(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_COL)) {
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_COLGROUP)) {
    if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_COLGROUP)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_COL)) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (
    tag_is(token, kStartTag, GUMBO_TAG_TEMPLATE)
    || tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    handle_in_body(parser, token);
    return;
  }
  if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_COLGROUP)) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  pop_current_node(parser);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intbody
static void handle_in_table_body(GumboParser* parser, GumboToken* token) {
  if (tag_is(token, kStartTag, GUMBO_TAG_TR)) {
    clear_stack_to_table_body_context(parser);
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_ROW);
    return;
  }
  if (tag_in(token, kStartTag, &td_th_tags)) {
    parser_add_parse_error(parser, token);
    clear_stack_to_table_body_context(parser);
    insert_element_of_tag_type(parser, GUMBO_TAG_TR, GUMBO_INSERTION_IMPLIED);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_ROW);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet){TAG(TBODY), TAG(TFOOT), TAG(THEAD)})
  ) {
    if (!has_an_element_in_table_scope(parser, token->v.end_tag.tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    clear_stack_to_table_body_context(parser);
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(TBODY), TAG(TFOOT),
      TAG(THEAD)
    })
    || tag_is(token, kEndTag, GUMBO_TAG_TABLE)
  ) {
    if (
      !(
        has_an_element_in_table_scope(parser, GUMBO_TAG_TBODY)
        || has_an_element_in_table_scope(parser, GUMBO_TAG_THEAD)
        || has_an_element_in_table_scope(parser, GUMBO_TAG_TFOOT)
      )
    ) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    clear_stack_to_table_body_context(parser);
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(BODY), TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(HTML), TAG(TD),
      TAG(TH), TAG(TR)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  handle_in_table(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intr
static void handle_in_row(GumboParser* parser, GumboToken* token) {
  if (tag_in(token, kStartTag, &td_th_tags)) {
    clear_stack_to_table_row_context(parser);
    insert_element_from_token(parser, token);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_CELL);
    add_formatting_element(parser, &kActiveFormattingScopeMarker);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_TR)) {
    if (!has_an_element_in_table_scope(parser, GUMBO_TAG_TR)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    clear_stack_to_table_row_context(parser);
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(TBODY), TAG(TFOOT),
      TAG(THEAD), TAG(TR)
    })
    || tag_is(token, kEndTag, GUMBO_TAG_TABLE)
  ) {
    if (!has_an_element_in_table_scope(parser, GUMBO_TAG_TR)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    clear_stack_to_table_row_context(parser);
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {TAG(TBODY), TAG(TFOOT), TAG(THEAD)})
  ) {
    if (!has_an_element_in_table_scope(parser, token->v.end_tag.tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    if (!has_an_element_in_table_scope(parser, GUMBO_TAG_TR)) {
      ignore_token(parser);
      return;
    }
    clear_stack_to_table_row_context(parser);
    pop_current_node(parser);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(BODY), TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(HTML),
      TAG(TD), TAG(TH)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  handle_in_table(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intd
static void handle_in_cell(GumboParser* parser, GumboToken* token) {
  if (tag_in(token, kEndTag, &td_th_tags)) {
    GumboTag token_tag = token->v.end_tag.tag;
    if (!has_an_element_in_table_scope(parser, token_tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    close_table_cell(parser, token, token_tag);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(TBODY), TAG(TD),
      TAG(TFOOT), TAG(TH), TAG(THEAD), TAG(TR)
    })
  ) {
    gumbo_debug("Handling <td> in cell.\n");
    if (
      !has_an_element_in_table_scope(parser, GUMBO_TAG_TH)
      && !has_an_element_in_table_scope(parser, GUMBO_TAG_TD)
    ) {
      gumbo_debug("Bailing out because there's no <td> or <th> in scope.\n");
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    parser->_parser_state->_reprocess_current_token = true;
    close_current_cell(parser, token);
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(BODY), TAG(CAPTION), TAG(COL), TAG(COLGROUP), TAG(HTML)
    })
  ) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (
    tag_in(token, kEndTag, &(const TagSet) {
      TAG(TABLE), TAG(TBODY), TAG(TFOOT), TAG(THEAD), TAG(TR)
    })
  ) {
    if (!has_an_element_in_table_scope(parser, token->v.end_tag.tag)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    parser->_parser_state->_reprocess_current_token = true;
    close_current_cell(parser, token);
    return;
  }
  handle_in_body(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselect
static void handle_in_select(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_NULL) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_CHARACTER
    || token->type == GUMBO_TOKEN_WHITESPACE
  ) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_OPTION)) {
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTION)) {
      pop_current_node(parser);
    }
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_OPTGROUP)) {
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTION)) {
      pop_current_node(parser);
    }
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTGROUP)) {
      pop_current_node(parser);
    }
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_OPTGROUP)) {
    GumboVector* open_elements = &parser->_parser_state->_open_elements;
    if (
      node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTION)
      && node_html_tag_is (
        open_elements->data[open_elements->length - 2],
        GUMBO_TAG_OPTGROUP
      )
    ) {
      pop_current_node(parser);
    }
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTGROUP)) {
      pop_current_node(parser);
      return;
    }
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_OPTION)) {
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_OPTION)) {
      pop_current_node(parser);
      return;
    }
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_SELECT)) {
    if (!has_an_element_in_select_scope(parser, GUMBO_TAG_SELECT)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    close_current_select(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_SELECT)) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    if (has_an_element_in_select_scope(parser, GUMBO_TAG_SELECT)) {
      close_current_select(parser);
    }
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {TAG(INPUT), TAG(KEYGEN), TAG(TEXTAREA)})
  ) {
    parser_add_parse_error(parser, token);
    if (!has_an_element_in_select_scope(parser, GUMBO_TAG_SELECT)) {
      ignore_token(parser);
    } else {
      close_current_select(parser);
      parser->_parser_state->_reprocess_current_token = true;
    }
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet){TAG(SCRIPT), TAG(TEMPLATE)})
    || tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    handle_in_body(parser, token);
    return;
  }
  parser_add_parse_error(parser, token);
  ignore_token(parser);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselectintable
static void handle_in_select_in_table(GumboParser* parser, GumboToken* token) {
  static const TagSet tags = {
    TAG(CAPTION), TAG(TABLE), TAG(TBODY), TAG(TFOOT), TAG(THEAD),
    TAG(TR), TAG(TD), TAG(TH)
  };
  if (tag_in(token, kStartTag, &tags)) {
    parser_add_parse_error(parser, token);
    close_current_select(parser);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  if (tag_in(token, kEndTag, &tags)) {
    parser_add_parse_error(parser, token);
    if (!has_an_element_in_table_scope(parser, token->v.end_tag.tag)) {
      ignore_token(parser);
      return;
    }
    close_current_select(parser);
    parser->_parser_state->_reprocess_current_token = true;
    return;
  }
  handle_in_select(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intemplate
static void handle_in_template(GumboParser* parser, GumboToken* token) {
  GumboParserState* state = parser->_parser_state;
  switch (token->type) {
    case GUMBO_TOKEN_WHITESPACE:
    case GUMBO_TOKEN_CHARACTER:
    case GUMBO_TOKEN_COMMENT:
    case GUMBO_TOKEN_NULL:
    case GUMBO_TOKEN_DOCTYPE:
      handle_in_body(parser, token);
      return;
    default:
      break;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(BASE), TAG(BASEFONT), TAG(BGSOUND), TAG(LINK), TAG(META),
      TAG(NOFRAMES), TAG(SCRIPT), TAG(STYLE), TAG(TEMPLATE), TAG(TITLE)
    })
    || tag_is(token, kEndTag, GUMBO_TAG_TEMPLATE)
  ) {
    handle_in_head(parser, token);
    return;
  }
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(CAPTION), TAG(COLGROUP), TAG(TBODY), TAG(TFOOT), TAG(THEAD)
    })
  ) {
    pop_template_insertion_mode(parser);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE);
    state->_reprocess_current_token = true;
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_COL)) {
    pop_template_insertion_mode(parser);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_COLUMN_GROUP);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_COLUMN_GROUP);
    state->_reprocess_current_token = true;
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_TR)) {
    pop_template_insertion_mode(parser);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TABLE_BODY);
    state->_reprocess_current_token = true;
    return;
  }
  if (tag_in(token, kStartTag, &td_th_tags)) {
    pop_template_insertion_mode(parser);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_ROW);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_ROW);
    state->_reprocess_current_token = true;
    return;
  }
  if (token->type == GUMBO_TOKEN_START_TAG) {
    pop_template_insertion_mode(parser);
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
    state->_reprocess_current_token = true;
    return;
  }
  if (token->type == GUMBO_TOKEN_END_TAG) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    if (!has_open_element(parser, GUMBO_TAG_TEMPLATE)) {
      // Stop parsing.
      return;
    }
    parser_add_parse_error(parser, token);
    while (!node_html_tag_is(pop_current_node(parser), GUMBO_TAG_TEMPLATE))
      ;
    clear_active_formatting_elements(parser);
    pop_template_insertion_mode(parser);
    reset_insertion_mode_appropriately(parser);
    state->_reprocess_current_token = true;
    return;
  }
  assert(0 && "unreachable");
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterbody
static void handle_after_body(GumboParser* parser, GumboToken* token) {
  if (
    token->type == GUMBO_TOKEN_WHITESPACE
    || tag_is(token, kStartTag, GUMBO_TAG_HTML)
  ) {
    handle_in_body(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    GumboNode* html_node = parser->_output->root;
    assert(html_node != NULL);
    append_comment_node(parser, html_node, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_HTML)) {
    /* fragment case: ignore the closing HTML token */
    if (is_fragment_parser(parser)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_AFTER_BODY);
    GumboNode* html = parser->_parser_state->_open_elements.data[0];
    assert(node_html_tag_is(html, GUMBO_TAG_HTML));
    record_end_of_element (
      parser->_parser_state->_current_token,
      &html->v.element
    );
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    return;
  }
  parser_add_parse_error(parser, token);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inframeset
static void handle_in_frameset(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FRAMESET)) {
    insert_element_from_token(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_FRAMESET)) {
    if (node_html_tag_is(get_current_node(parser), GUMBO_TAG_HTML)) {
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    }
    pop_current_node(parser);
    if (
      !is_fragment_parser(parser)
      && !node_html_tag_is(get_current_node(parser), GUMBO_TAG_FRAMESET)
    ) {
      set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_FRAMESET);
    }
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_FRAME)) {
    insert_element_from_token(parser, token);
    pop_current_node(parser);
    acknowledge_self_closing_tag(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOFRAMES)) {
    handle_in_head(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    if (!node_html_tag_is(get_current_node(parser), GUMBO_TAG_HTML))
      parser_add_parse_error(parser, token);
    return;
  }
  parser_add_parse_error(parser, token);
  ignore_token(parser);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterframeset
static void handle_after_frameset(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_WHITESPACE) {
    insert_text_token(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_current_node(parser), token);
    return;
  }
  if (token->type == GUMBO_TOKEN_DOCTYPE) {
    parser_add_parse_error(parser, token);
    ignore_token(parser);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_HTML)) {
    handle_in_body(parser, token);
    return;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_HTML)) {
    GumboNode* html = parser->_parser_state->_open_elements.data[0];
    assert(node_html_tag_is(html, GUMBO_TAG_HTML));
    record_end_of_element (
      parser->_parser_state->_current_token,
      &html->v.element
    );
    set_insertion_mode(parser, GUMBO_INSERTION_MODE_AFTER_AFTER_FRAMESET);
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOFRAMES)) {
    return handle_in_head(parser, token);
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    return;
  }
  parser_add_parse_error(parser, token);
  ignore_token(parser);
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-body-insertion-mode
static void handle_after_after_body(GumboParser* parser, GumboToken* token) {
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_document_node(parser), token);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_DOCTYPE
    || token->type == GUMBO_TOKEN_WHITESPACE
    || tag_is(token, kStartTag, GUMBO_TAG_HTML)
  ) {
    handle_in_body(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    return;
  }
  parser_add_parse_error(parser, token);
  set_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_BODY);
  parser->_parser_state->_reprocess_current_token = true;
}

// https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-frameset-insertion-mode
static void handle_after_after_frameset (
  GumboParser* parser,
  GumboToken* token
) {
  if (token->type == GUMBO_TOKEN_COMMENT) {
    append_comment_node(parser, get_document_node(parser), token);
    return;
  }
  if (
    token->type == GUMBO_TOKEN_DOCTYPE
    || token->type == GUMBO_TOKEN_WHITESPACE
    || tag_is(token, kStartTag, GUMBO_TAG_HTML)
  ) {
    handle_in_body(parser, token);
    return;
  }
  if (token->type == GUMBO_TOKEN_EOF) {
    return;
  }
  if (tag_is(token, kStartTag, GUMBO_TAG_NOFRAMES)) {
    handle_in_head(parser, token);
    return;
  }
  parser_add_parse_error(parser, token);
  ignore_token(parser);
}

// Function pointers for each insertion mode.
// Keep in sync with insertion_mode.h.
typedef void (*TokenHandler)(GumboParser* parser, GumboToken* token);
static const TokenHandler kTokenHandlers[] = {
  handle_initial,
  handle_before_html,
  handle_before_head,
  handle_in_head,
  handle_in_head_noscript,
  handle_after_head,
  handle_in_body,
  handle_text,
  handle_in_table,
  handle_in_table_text,
  handle_in_caption,
  handle_in_column_group,
  handle_in_table_body,
  handle_in_row,
  handle_in_cell,
  handle_in_select,
  handle_in_select_in_table,
  handle_in_template,
  handle_after_body,
  handle_in_frameset,
  handle_after_frameset,
  handle_after_after_body,
  handle_after_after_frameset
};

static void handle_html_content(GumboParser* parser, GumboToken* token) {
  const GumboInsertionMode mode = parser->_parser_state->_insertion_mode;
  const TokenHandler handler = kTokenHandlers[mode];
  handler(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inforeign
static void handle_in_foreign_content(GumboParser* parser, GumboToken* token) {
  gumbo_debug("Handling foreign content");
  switch (token->type) {
    case GUMBO_TOKEN_NULL:
      parser_add_parse_error(parser, token);
      token->v.character = kUtf8ReplacementChar;
      insert_text_token(parser, token);
      return;
    case GUMBO_TOKEN_WHITESPACE:
      insert_text_token(parser, token);
      return;
    case GUMBO_TOKEN_CDATA:
    case GUMBO_TOKEN_CHARACTER:
      insert_text_token(parser, token);
      set_frameset_not_ok(parser);
      return;
    case GUMBO_TOKEN_COMMENT:
      append_comment_node(parser, get_current_node(parser), token);
      return;
    case GUMBO_TOKEN_DOCTYPE:
      parser_add_parse_error(parser, token);
      ignore_token(parser);
      return;
    default:
      // Fall through to the if-statements below.
      break;
  }
  // Order matters for these clauses.
  if (
    tag_in(token, kStartTag, &(const TagSet) {
      TAG(B), TAG(BIG), TAG(BLOCKQUOTE), TAG(BODY), TAG(BR), TAG(CENTER),
      TAG(CODE), TAG(DD), TAG(DIV), TAG(DL), TAG(DT), TAG(EM), TAG(EMBED),
      TAG(H1), TAG(H2), TAG(H3), TAG(H4), TAG(H5), TAG(H6), TAG(HEAD),
      TAG(HR), TAG(I), TAG(IMG), TAG(LI), TAG(LISTING), TAG(MENU), TAG(META),
      TAG(NOBR), TAG(OL), TAG(P), TAG(PRE), TAG(RUBY), TAG(S), TAG(SMALL),
      TAG(SPAN), TAG(STRONG), TAG(STRIKE), TAG(SUB), TAG(SUP), TAG(TABLE),
      TAG(TT), TAG(U), TAG(UL), TAG(VAR)
    })
    || (
      tag_is(token, kStartTag, GUMBO_TAG_FONT)
      && (
        token_has_attribute(token, "color")
        || token_has_attribute(token, "face")
        || token_has_attribute(token, "size")
      )
    )
  ) {
    /* Parse error */
    parser_add_parse_error(parser, token);

    /*
     * Fragment case: If the parser was originally created for the HTML
     * fragment parsing algorithm, then act as described in the "any other
     * start tag" entry below.
     */
    if (!is_fragment_parser(parser)) {
      do {
        pop_current_node(parser);
      } while (
        !(
          is_mathml_integration_point(get_current_node(parser))
          || is_html_integration_point(get_current_node(parser))
          || get_current_node(parser)->v.element.tag_namespace == GUMBO_NAMESPACE_HTML
        )
      );
      parser->_parser_state->_reprocess_current_token = true;
      return;
    }
    // This is a start tag so the next if's then branch will be taken.
  }

  if (token->type == GUMBO_TOKEN_START_TAG) {
    const GumboNamespaceEnum current_namespace =
        get_adjusted_current_node(parser)->v.element.tag_namespace;
    if (current_namespace == GUMBO_NAMESPACE_MATHML) {
      adjust_mathml_attributes(token);
    }
    if (current_namespace == GUMBO_NAMESPACE_SVG) {
      adjust_svg_tag(token);
      adjust_svg_attributes(token);
    }
    adjust_foreign_attributes(token);
    insert_foreign_element(parser, token, current_namespace);
    if (token->v.start_tag.is_self_closing) {
      pop_current_node(parser);
      acknowledge_self_closing_tag(parser);
    }
    return;
    // </script> tags are handled like any other end tag, putting the script's
    // text into a text node child and closing the current node.
  }
  assert(token->type == GUMBO_TOKEN_END_TAG);
  GumboNode* node = get_current_node(parser);
  GumboTag tag = token->v.end_tag.tag;
  const char* name = token->v.end_tag.name;
  assert(node != NULL);

  if (!node_tagname_is(node, tag, name))
    parser_add_parse_error(parser, token);
  int i = parser->_parser_state->_open_elements.length;
  for (--i; i > 0;) {
    // Here we move up the stack until we find an HTML element (in which
    // case we do nothing) or we find the element that we're about to
    // close (in which case we pop everything we've seen until that
    // point.)
    gumbo_debug("Foreign %s node at %d.\n", node->v.element.name, i);
    if (node_tagname_is(node, tag, name)) {
      gumbo_debug("Matches.\n");
      while (node != pop_current_node(parser)) {
        // Pop all the nodes below the current one. Node is guaranteed to
        // be an element on the stack of open elements (set below), so
        // this loop is guaranteed to terminate.
      }
      return;
    }
    --i;
    node = parser->_parser_state->_open_elements.data[i];
    if (node->v.element.tag_namespace == GUMBO_NAMESPACE_HTML) {
      // The loop continues only in foreign namespaces.
      break;
    }
  }
  assert(node->v.element.tag_namespace == GUMBO_NAMESPACE_HTML);
  if (i == 0)
    return;
  // We can't call handle_token directly because the current node is still in
  // a foriegn namespace, so it would re-enter this and result in infinite
  // recursion.
  handle_html_content(parser, token);
}

// https://html.spec.whatwg.org/multipage/parsing.html#tree-construction
static void handle_token(GumboParser* parser, GumboToken* token) {
  if (
    parser->_parser_state->_ignore_next_linefeed
    && token->type == GUMBO_TOKEN_WHITESPACE && token->v.character == '\n'
  ) {
    parser->_parser_state->_ignore_next_linefeed = false;
    ignore_token(parser);
    return;
  }
  // This needs to be reset both here and in the conditional above to catch both
  // the case where the next token is not whitespace (so we don't ignore
  // whitespace in the middle of <pre> tags) and where there are multiple
  // whitespace tokens (so we don't ignore the second one).
  parser->_parser_state->_ignore_next_linefeed = false;

  if (tag_is(token, kEndTag, GUMBO_TAG_BODY)) {
    parser->_parser_state->_closed_body_tag = true;
  }
  if (tag_is(token, kEndTag, GUMBO_TAG_HTML)) {
    parser->_parser_state->_closed_html_tag = true;
  }

  const GumboNode* current_node = get_adjusted_current_node(parser);
  assert (
    !current_node
    || current_node->type == GUMBO_NODE_ELEMENT
    || current_node->type == GUMBO_NODE_TEMPLATE
  );
  if (current_node)
    gumbo_debug("Current node: <%s>.\n", current_node->v.element.name);
  if (!current_node ||
      current_node->v.element.tag_namespace == GUMBO_NAMESPACE_HTML ||
      (is_mathml_integration_point(current_node) &&
          (token->type == GUMBO_TOKEN_CHARACTER ||
              token->type == GUMBO_TOKEN_WHITESPACE ||
              token->type == GUMBO_TOKEN_NULL ||
              (token->type == GUMBO_TOKEN_START_TAG &&
                  !tag_in(token, kStartTag,
                      &(const TagSet){TAG(MGLYPH), TAG(MALIGNMARK)})))) ||
      (current_node->v.element.tag_namespace == GUMBO_NAMESPACE_MATHML &&
          node_qualified_tag_is(
              current_node, GUMBO_NAMESPACE_MATHML, GUMBO_TAG_ANNOTATION_XML) &&
          tag_is(token, kStartTag, GUMBO_TAG_SVG)) ||
      (is_html_integration_point(current_node) &&
          (token->type == GUMBO_TOKEN_START_TAG ||
              token->type == GUMBO_TOKEN_CHARACTER ||
              token->type == GUMBO_TOKEN_NULL ||
              token->type == GUMBO_TOKEN_WHITESPACE)) ||
      token->type == GUMBO_TOKEN_EOF) {
    handle_html_content(parser, token);
  } else {
    handle_in_foreign_content(parser, token);
  }
}

static GumboNode* create_fragment_ctx_element (
  const char* tag_name,
  GumboNamespaceEnum ns,
  const char* encoding
) {
  assert(tag_name);
  GumboTag tag = gumbo_tagn_enum(tag_name, strlen(tag_name));
  GumboNodeType type =
    ns == GUMBO_NAMESPACE_HTML && tag == GUMBO_TAG_TEMPLATE
    ? GUMBO_NODE_TEMPLATE : GUMBO_NODE_ELEMENT;
  GumboNode* node = create_node(type);
  GumboElement* element = &node->v.element;
  element->children = kGumboEmptyVector;
  if (encoding) {
    gumbo_vector_init(1, &element->attributes);
    GumboAttribute* attr = gumbo_alloc(sizeof(GumboAttribute));
    attr->attr_namespace = GUMBO_ATTR_NAMESPACE_NONE;
    attr->name = "encoding"; // Do not free this!
    attr->original_name = kGumboEmptyString;
    attr->value = encoding; // Do not free this!
    attr->original_value = kGumboEmptyString;
    attr->name_start = kGumboEmptySourcePosition;
    gumbo_vector_add(attr, &element->attributes);
  } else {
    element->attributes = kGumboEmptyVector;
  }
  element->tag = tag;
  element->tag_namespace = ns;
  element->name = tag_name; // Do not free this!
  element->original_tag = kGumboEmptyString;
  element->original_end_tag = kGumboEmptyString;
  element->start_pos = kGumboEmptySourcePosition;
  element->end_pos = kGumboEmptySourcePosition;
  return node;
}

static void destroy_fragment_ctx_element(GumboNode* ctx) {
  assert(ctx->type == GUMBO_NODE_ELEMENT || ctx->type == GUMBO_NODE_TEMPLATE);
  GumboElement* element = &ctx->v.element;
  element->name = NULL; // Do not free.
  if (element->attributes.length > 0) {
    assert(element->attributes.length == 1);
    GumboAttribute* attr = gumbo_vector_pop(&element->attributes);
    // Do not free attr->name or attr->value, just free the attr.
    gumbo_free(attr);
  }
  destroy_node(ctx);
}

static void fragment_parser_init (
  GumboParser* parser,
  const GumboOptions* options
) {
  assert(options->fragment_context != NULL);
  const char* fragment_ctx = options->fragment_context;
  GumboNamespaceEnum fragment_namespace = options->fragment_namespace;
  const char* fragment_encoding = options->fragment_encoding;
  GumboQuirksModeEnum quirks = options->quirks_mode;
  bool ctx_has_form_ancestor = options->fragment_context_has_form_ancestor;

  GumboNode* root;
  // 2.
  get_document_node(parser)->v.document.doc_type_quirks_mode = quirks;

  // 3.
  parser->_parser_state->_fragment_ctx =
    create_fragment_ctx_element(fragment_ctx, fragment_namespace, fragment_encoding);
  GumboTag ctx_tag = parser->_parser_state->_fragment_ctx->v.element.tag;

  // 4.
  if (fragment_namespace == GUMBO_NAMESPACE_HTML) {
    // Non-HTML namespaces always start in the DATA state.
    switch (ctx_tag) {
      case GUMBO_TAG_TITLE:
      case GUMBO_TAG_TEXTAREA:
        gumbo_tokenizer_set_state(parser, GUMBO_LEX_RCDATA);
        break;

      case GUMBO_TAG_STYLE:
      case GUMBO_TAG_XMP:
      case GUMBO_TAG_IFRAME:
      case GUMBO_TAG_NOEMBED:
      case GUMBO_TAG_NOFRAMES:
        gumbo_tokenizer_set_state(parser, GUMBO_LEX_RAWTEXT);
        break;

      case GUMBO_TAG_SCRIPT:
        gumbo_tokenizer_set_state(parser, GUMBO_LEX_SCRIPT_DATA);
        break;

      case GUMBO_TAG_NOSCRIPT:
        /* scripting is disabled in Gumbo, so leave the tokenizer
         * in the default data state */
        break;

      case GUMBO_TAG_PLAINTEXT:
        gumbo_tokenizer_set_state(parser, GUMBO_LEX_PLAINTEXT);
        break;

      default:
        /* default data state */
        break;
    }
  }

  // 5. 6. 7.
  root = insert_element_of_tag_type (
    parser,
    GUMBO_TAG_HTML,
    GUMBO_INSERTION_IMPLIED
  );
  parser->_output->root = root;

  // 8.
  if (ctx_tag == GUMBO_TAG_TEMPLATE) {
    push_template_insertion_mode(parser, GUMBO_INSERTION_MODE_IN_TEMPLATE);
  }

  // 10.
  reset_insertion_mode_appropriately(parser);

  // 11.
  if (ctx_has_form_ancestor
      || (ctx_tag == GUMBO_TAG_FORM
          && fragment_namespace == GUMBO_NAMESPACE_HTML)) {
    static const GumboNode form_ancestor = {
      .type = GUMBO_NODE_ELEMENT,
      .parent = NULL,
      .index_within_parent = -1,
      .parse_flags = GUMBO_INSERTION_BY_PARSER,
      .v.element = {
        .children = GUMBO_EMPTY_VECTOR_INIT,
        .tag = GUMBO_TAG_FORM,
        .name = NULL,
        .tag_namespace = GUMBO_NAMESPACE_HTML,
        .original_tag = GUMBO_EMPTY_STRING_INIT,
        .original_end_tag = GUMBO_EMPTY_STRING_INIT,
        .start_pos = GUMBO_EMPTY_SOURCE_POSITION_INIT,
        .end_pos = GUMBO_EMPTY_SOURCE_POSITION_INIT,
        .attributes = GUMBO_EMPTY_VECTOR_INIT,
      },
    };
    // This cast is okay because _form_element is only modified if it is
    // in in the list of open elements. This will never be.
    parser->_parser_state->_form_element = (GumboNode *)&form_ancestor;
  }
}

GumboOutput* gumbo_parse(const char* buffer) {
  return gumbo_parse_with_options (
    &kGumboDefaultOptions,
    buffer,
    strlen(buffer)
  );
}

GumboOutput* gumbo_parse_with_options (
  const GumboOptions* options,
  const char* buffer,
  size_t length
) {
  GumboParser parser;
  parser._options = options;
  output_init(&parser);
  gumbo_tokenizer_state_init(&parser, buffer, length);
  parser_state_init(&parser);

  if (options->fragment_context != NULL)
    fragment_parser_init(&parser, options);

  GumboParserState* state = parser._parser_state;
  gumbo_debug (
    "Parsing %.*s.\n",
    (int) length,
    buffer
  );

  // Sanity check so that infinite loops die with an assertion failure instead
  // of hanging the process before we ever get an error.
  uint_fast32_t loop_count = 0;

  const unsigned int max_tree_depth = options->max_tree_depth;
  GumboToken token;

  do {
    if (state->_reprocess_current_token) {
      state->_reprocess_current_token = false;
    } else {
      GumboNode* adjusted_current_node = get_adjusted_current_node(&parser);
      gumbo_tokenizer_set_is_adjusted_current_node_foreign (
        &parser,
        adjusted_current_node &&
          adjusted_current_node->v.element.tag_namespace != GUMBO_NAMESPACE_HTML
      );
      gumbo_lex(&parser, &token);
    }

    const char* token_type = "text";
    switch (token.type) {
      case GUMBO_TOKEN_DOCTYPE:
        token_type = "doctype";
        break;
      case GUMBO_TOKEN_START_TAG:
        if (token.v.start_tag.tag == GUMBO_TAG_UNKNOWN)
          token_type = token.v.start_tag.name;
        else
          token_type = gumbo_normalized_tagname(token.v.start_tag.tag);
        break;
      case GUMBO_TOKEN_END_TAG:
        token_type = gumbo_normalized_tagname(token.v.end_tag.tag);
        break;
      case GUMBO_TOKEN_COMMENT:
        token_type = "comment";
        break;
      default:
        break;
    }
    gumbo_debug (
      "Handling %s token @%lu:%lu in state %u.\n",
      (char*) token_type,
      (unsigned long)token.position.line,
      (unsigned long)token.position.column,
      state->_insertion_mode
    );

    state->_current_token = &token;
    state->_self_closing_flag_acknowledged = false;

    handle_token(&parser, &token);

    // Check for memory leaks when ownership is transferred from start tag
    // tokens to nodes.
    assert (
      state->_reprocess_current_token
      || token.type != GUMBO_TOKEN_START_TAG
      || (token.v.start_tag.attributes.data == NULL
          && token.v.start_tag.name == NULL)
    );

    if (!state->_reprocess_current_token) {
      // If we're done with the token, check for unacknowledged self-closing
      // flags on start tags.
      if (token.type == GUMBO_TOKEN_START_TAG &&
          token.v.start_tag.is_self_closing &&
          !state->_self_closing_flag_acknowledged) {
        GumboError* error = gumbo_add_error(&parser);
        if (error) {
          // This is essentially a tokenizer error that's only caught during
          // tree construction.
          error->type = GUMBO_ERR_NON_VOID_HTML_ELEMENT_START_TAG_WITH_TRAILING_SOLIDUS;
          error->original_text = token.original_text;
          error->position = token.position;
        }
      }
      // Make sure we free the end tag's name since it doesn't get transferred
      // to a token.
      if (token.type == GUMBO_TOKEN_END_TAG &&
          token.v.end_tag.tag == GUMBO_TAG_UNKNOWN)
        gumbo_free(token.v.end_tag.name);
    }

    if (unlikely(state->_open_elements.length > max_tree_depth)) {
      parser._output->status = GUMBO_STATUS_TREE_TOO_DEEP;
      gumbo_debug("Tree depth limit exceeded.\n");
      break;
    }

    ++loop_count;
    assert(loop_count < 1000000000UL);

  } while (
    (token.type != GUMBO_TOKEN_EOF || state->_reprocess_current_token)
    && !(options->stop_on_first_error && parser._output->document_error)
  );

  finish_parsing(&parser);
  // For API uniformity reasons, if the doctype still has nulls, convert them to
  // empty strings.
  GumboDocument* doc_type = &parser._output->document->v.document;
  if (doc_type->name == NULL) {
    doc_type->name = gumbo_strdup("");
  }
  if (doc_type->public_identifier == NULL) {
    doc_type->public_identifier = gumbo_strdup("");
  }
  if (doc_type->system_identifier == NULL) {
    doc_type->system_identifier = gumbo_strdup("");
  }

  parser_state_destroy(&parser);
  gumbo_tokenizer_state_destroy(&parser);
  return parser._output;
}

const char* gumbo_status_to_string(GumboOutputStatus status) {
  switch (status) {
    case GUMBO_STATUS_OK:
      return "OK";
    case GUMBO_STATUS_OUT_OF_MEMORY:
      return "System allocator returned NULL during parsing";
    case GUMBO_STATUS_TREE_TOO_DEEP:
      return "Document tree depth limit exceeded";
    default:
      return "Unknown GumboOutputStatus value";
  }
}

void gumbo_destroy_node(GumboNode* node) {
  destroy_node(node);
}

void gumbo_destroy_output(GumboOutput* output) {
  destroy_node(output->document);
  for (unsigned int i = 0; i < output->errors.length; ++i) {
    gumbo_error_destroy(output->errors.data[i]);
  }
  gumbo_vector_destroy(&output->errors);
  gumbo_free(output);
}
