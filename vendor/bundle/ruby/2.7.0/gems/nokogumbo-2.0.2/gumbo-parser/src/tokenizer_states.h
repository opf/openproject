#ifndef GUMBO_TOKENIZER_STATES_H_
#define GUMBO_TOKENIZER_STATES_H_

// This contains the list of states used in the tokenizer. Although at first
// glance it seems like these could be kept internal to the tokenizer, several
// of the actions in the parser require that it reach into the tokenizer and
// reset the tokenizer state. For that to work, it needs to have the
// definitions of individual states available.
//
// This may also be useful for providing more detailed error messages for parse
// errors, as we can match up states and inputs in a table without having to
// clutter the tokenizer code with lots of precise error messages.

// The ordering of this enum is also used to build the dispatch table for the
// tokenizer state machine, so if it is changed, be sure to update that too.
typedef enum {
  // 12.2.5.1 Data state
  // https://html.spec.whatwg.org/multipage/parsing.html#data-state
  GUMBO_LEX_DATA,

  // 12.2.5.2 RCDATA state
  // https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
  GUMBO_LEX_RCDATA,

  // 12.2.5.3 RAWTEXT state
  // https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state<Paste>
  GUMBO_LEX_RAWTEXT,

  // 12.2.5.4 Script data state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
  GUMBO_LEX_SCRIPT_DATA,

  // 12.2.5.5 PLAINTEXT state
  // https://html.spec.whatwg.org/multipage/parsing.html#plaintext-state
  GUMBO_LEX_PLAINTEXT,

  // 12.2.5.6 Tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#tag-open-state
  GUMBO_LEX_TAG_OPEN,

  // 12.2.5.7 End tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#end-tag-open-state
  GUMBO_LEX_END_TAG_OPEN,

  // 12.2.5.8 Tag name state
  // https://html.spec.whatwg.org/multipage/parsing.html#tag-name-state
  GUMBO_LEX_TAG_NAME,

  // 12.2.5.9 RCDATA less-than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
  GUMBO_LEX_RCDATA_LT,

  // 12.2.5.10 RCDATA end tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
  GUMBO_LEX_RCDATA_END_TAG_OPEN,

  // 12.2.5.11 RCDATA end tag name state
  // https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
  GUMBO_LEX_RCDATA_END_TAG_NAME,

  // 12.2.5.12 RAWTEXT less-than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
  GUMBO_LEX_RAWTEXT_LT,

  // 12.2.5.13 RAWTEXT end tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
  GUMBO_LEX_RAWTEXT_END_TAG_OPEN,

  // 12.2.5.14 RAWTEXT end tag name state
  // https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
  GUMBO_LEX_RAWTEXT_END_TAG_NAME,

  // 12.2.5.15 Script data less-than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
  GUMBO_LEX_SCRIPT_DATA_LT,

  // 12.2.5.16 Script data end tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
  GUMBO_LEX_SCRIPT_DATA_END_TAG_OPEN,

  // 12.2.5.17 Script data end tag name state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
  GUMBO_LEX_SCRIPT_DATA_END_TAG_NAME,

  // 12.2.5.18 Script data escape start state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_START,

  // 12.2.5.19 Script data escape start dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_START_DASH,

  // 12.2.5.20 Script data escaped state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED,

  // 12.2.5.21 Script data escaped dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH,

  // 12.2.5.22 Script data escaped dash dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_DASH_DASH,

  // 12.2.5.23 Script data escaped less than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_LT,

  // 12.2.5.24 Script data escaped end tag open state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_OPEN,

  // 12.2.5.25 Script data escaped end tag name state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
  GUMBO_LEX_SCRIPT_DATA_ESCAPED_END_TAG_NAME,

  // 12.2.5.26 Script data double escape start state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_START,

  // 12.2.5.27 Script data double escaped state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED,

  // 12.2.5.28 Script data double escaped dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH,

  // 12.2.5.29 Script data double escaped dash dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH,

  // 12.2.5.30 Script data double escaped less-than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_LT,

  // 12.2.5.31 Script data double escape end state (XXX: spec bug with the
  // name?)
  // https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-state
  GUMBO_LEX_SCRIPT_DATA_DOUBLE_ESCAPED_END,

  // 12.2.5.32 Before attribute name state
  // https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-name-state
  GUMBO_LEX_BEFORE_ATTR_NAME,

  // 12.2.5.33 Attributet name state
  // https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
  GUMBO_LEX_ATTR_NAME,

  // 12.2.5.34 After attribute name state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-name-state
  GUMBO_LEX_AFTER_ATTR_NAME,

  // 12.2.5.35 Before attribute value state
  // https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-value-state
  GUMBO_LEX_BEFORE_ATTR_VALUE,

  // 12.2.5.36 Attribute value (double-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
  GUMBO_LEX_ATTR_VALUE_DOUBLE_QUOTED,

  // 12.2.5.37 Attribute value (single-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(single-quoted)-state
  GUMBO_LEX_ATTR_VALUE_SINGLE_QUOTED,

  // 12.2.5.38 Attribute value (unquoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(unquoted)-state
  GUMBO_LEX_ATTR_VALUE_UNQUOTED,

  // 12.2.5.39 After attribute value (quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-value-(quoted)-state
  GUMBO_LEX_AFTER_ATTR_VALUE_QUOTED,

  // 12.2.5.40 Self-closing start tag state
  // https://html.spec.whatwg.org/multipage/parsing.html#self-closing-start-tag-state
  GUMBO_LEX_SELF_CLOSING_START_TAG,

  // 12.2.5.41 Bogus comment state
  // https://html.spec.whatwg.org/multipage/parsing.html#bogus-comment-state
  GUMBO_LEX_BOGUS_COMMENT,

  // 12.2.5.42 Markup declaration open state
  // https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
  GUMBO_LEX_MARKUP_DECLARATION_OPEN,

  // 12.2.5.43 Comment start state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
  GUMBO_LEX_COMMENT_START,

  // 12.2.5.44 Comment start dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
  GUMBO_LEX_COMMENT_START_DASH,

  // 12.2.5.45 Comment state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-state
  GUMBO_LEX_COMMENT,

  // 12.2.5.46 Comment less-than sign state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-state
  GUMBO_LEX_COMMENT_LT,

  // 12.2.5.47 Comment less-than sign bang state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
  GUMBO_LEX_COMMENT_LT_BANG,

  // 12.2.5.48 Comment less-than sign bang dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
  GUMBO_LEX_COMMENT_LT_BANG_DASH,

  // 12.2.5.49 Comment less-than sign bang dash dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
  GUMBO_LEX_COMMENT_LT_BANG_DASH_DASH,

  // 12.2.5.50 Comment end dash state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
  GUMBO_LEX_COMMENT_END_DASH,

  // 12.2.5.51 Comment end state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-end-state
  GUMBO_LEX_COMMENT_END,

  // 12.2.5.52 Comment end bang state
  // https://html.spec.whatwg.org/multipage/parsing.html#comment-end-bang-state
  GUMBO_LEX_COMMENT_END_BANG,

  // 12.2.5.53 DOCTYPE state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
  GUMBO_LEX_DOCTYPE,

  // 12.2.5.54 Before DOCTYPE name state
  // https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-name-state
  GUMBO_LEX_BEFORE_DOCTYPE_NAME,

  // 12.2.5.55 DOCTYPE name state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
  GUMBO_LEX_DOCTYPE_NAME,

  // 12.2.5.56 After DOCTYPE name state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
  GUMBO_LEX_AFTER_DOCTYPE_NAME,

  // 12.2.5.57 After DOCTYPE public keyword state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-keyword-state
  GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_KEYWORD,

  // 12.2.5.58 Before DOCTYPE public identifier state
  // https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-public-identifier-state
  GUMBO_LEX_BEFORE_DOCTYPE_PUBLIC_ID,

  // 12.2.5.59 DOCTYPE public identifier (double-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
  GUMBO_LEX_DOCTYPE_PUBLIC_ID_DOUBLE_QUOTED,

  // 12.2.5.60 DOCTYPE public identifier (single-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(single-quoted)-state
  GUMBO_LEX_DOCTYPE_PUBLIC_ID_SINGLE_QUOTED,

  // 12.2.5.61 After DOCTYPE public identifier state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
  GUMBO_LEX_AFTER_DOCTYPE_PUBLIC_ID,

  // 12.2.5.62 Between DOCTYPE public and system identifiers state
  // https://html.spec.whatwg.org/multipage/parsing.html#between-doctype-public-and-system-identifiers-state
  GUMBO_LEX_BETWEEN_DOCTYPE_PUBLIC_SYSTEM_ID,

  // 12.2.5.63 After DOCTYPE system keyword state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-keyword-state
  GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_KEYWORD,

  // 12.2.5.64 Before DOCTYPE system identifier state
  // https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-system-identifier-state
  GUMBO_LEX_BEFORE_DOCTYPE_SYSTEM_ID,

  // 12.2.5.65 DOCTYPE system identifier (double-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
  GUMBO_LEX_DOCTYPE_SYSTEM_ID_DOUBLE_QUOTED,

  // 12.2.5.66 DOCTYPE system identifier (single-quoted) state
  // https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(single-quoted)-state
  GUMBO_LEX_DOCTYPE_SYSTEM_ID_SINGLE_QUOTED,

  // 12.2.5.67 After DOCTYPE system identifier state
  // https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
  GUMBO_LEX_AFTER_DOCTYPE_SYSTEM_ID,

  // 12.2.5.68 Bogus DOCTYPE state
  // https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
  GUMBO_LEX_BOGUS_DOCTYPE,

  // 12.2.5.69 CDATA section state
  // https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
  GUMBO_LEX_CDATA_SECTION,

  // 12.2.5.70 CDATA section bracket state
  // https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
  GUMBO_LEX_CDATA_SECTION_BRACKET,

  // 12.2.5.71 CDATA section end state
  // https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
  GUMBO_LEX_CDATA_SECTION_END,

  // 12.2.5.72 Character reference state
  // https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
  GUMBO_LEX_CHARACTER_REFERENCE,

  // 12.2.5.73 Named character reference state
  // https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state
  GUMBO_LEX_NAMED_CHARACTER_REFERENCE,

  // 12.2.5.74 Ambiguous ampersand state
  // https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
  GUMBO_LEX_AMBIGUOUS_AMPERSAND,

  // 12.2.5.75 Numeric character reference state
  // https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
  GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE,

  // 12.2.5.76 Hexadecimal character reference start state
  // https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
  GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE_START,

  // 12.2.5.77 Decimal character reference start state
  // https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
  GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE_START,
  
  // 12.2.5.78 Hexadecimal character reference state
  // https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
  GUMBO_LEX_HEXADECIMAL_CHARACTER_REFERENCE,
  
  // 12.2.5.79 Decimal character reference state
  // https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
  GUMBO_LEX_DECIMAL_CHARACTER_REFERENCE,

  // 12.2.5.80 Numeric character reference end state
  // https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
  GUMBO_LEX_NUMERIC_CHARACTER_REFERENCE_END
} GumboTokenizerEnum;

#endif // GUMBO_TOKENIZER_STATES_H_
