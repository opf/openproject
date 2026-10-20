# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports::PDF::Common::Macro
  PREFORMATTED_BLOCKS = %w(pre code).freeze
  # tables & images & markdown code blocks are not supported in nested rich text
  UNSUPPORTED_NESTED = %w[<table <img ```].freeze
  # markdown quotes are not supported in nested rich text
  UNSUPPORTED_NESTED_REGEX = [/^\s>/].freeze

  def apply_markdown_field_macros(markdown, context)
    return markdown if markdown.blank?

    apply_macros(markdown, context)
  end

  def macros
    [
      WorkPackage::Exports::Macros::Links,
      WorkPackage::Exports::Macros::Attributes
    ]
  end

  private

  def apply_macros(markdown, context)
    return markdown unless macros.any? { |macro| macro.applicable?(markdown) }

    document = Markly.parse(markdown)
    document.walk { |node| apply_macros_node(node, context) }
    document.to_markdown
            .gsub("\\~", "~") # fix a bug in Markly that escapes tildes
  end

  def apply_macros_node(node, context)
    if node.type == :html
      apply_macros_node_html(node, context)
    elsif node.type == :text && not_in_mention?(node)
      apply_macros_node_text(node, context)
    end
  end

  def not_in_mention?(node)
    # Check if the text node is not inside a mention tag
    # e.g. <mention ...>#1234</mention>
    # We don't want to end up with
    # <mention ...><mention ...>#1234</mention></mention>
    node.previous.nil? || node.previous.type != :inline_html || node.previous.string_content.exclude?("<mention")
  end

  def apply_macros_node_text(node, context)
    formatted = apply_macro_text(node.string_content, false, context)
    return if formatted == node.string_content

    fragment = Markly::Node.new(:inline_html)
    fragment.string_content = formatted
    node.insert_before(fragment)
    node.delete
  end

  def apply_macros_node_html(node, context)
    node.string_content = apply_macro_html(node.string_content, context)
  end

  def applicable?(content)
    macros.any? { |macro| macro.applicable?(content) }
  end

  def apply_macro_text(text, in_html, context)
    applicable_macros = macros.select { |macro| macro.applicable?(text) }
    return text if applicable_macros.empty?

    applicable_macros.each { |macro| text = replace_macro(text, macro, in_html, context) }
    text
  end

  def replace_macro(text, macro, in_html, context)
    text.gsub(macro.regexp) do |matched_string|
      match = Regexp.last_match
      replace_macro_match(match, matched_string, macro, in_html, context)
    end
  end

  def replace_macro_match(match, matched_string, macro, in_html, context)
    replacement, is_rich_text = macro.process_match(match, matched_string, context)
    if !is_rich_text
      build_plain_replacement(replacement)
    elsif in_html
      build_html_replacement(replacement)
    else
      build_markdown_replacement(replacement, match.begin(0))
    end
  end

  def build_markdown_replacement(markdown, position)
    # if there is a list or other markdown structure in the markdown and the macro is placed somewhere in the line
    # we need to add a line break before the markdown to not break the structure
    # example: a markdown list with asterisk is only valid if the asterisk is at the beginning of the line
    if position > 0 && has_markdown_structure_formatting?(markdown)
      "\n#{markdown}"
    else
      markdown
    end
  end

  def has_markdown_structure_formatting?(text)
    return false if text.nil? || text.strip.empty?

    # Check for headers (ATX style: # Heading or Setext style: Heading\n===)
    return true if text.start_with?("#") ||
                   text.match?(/\A[^\n]+\n[=-]{2,}\s*(?:\n|$)/)

    # Check for blockquotes
    return true if text.start_with?(">")

    # Check for lists (unordered: *, +, - and ordered: 1., 1), a., A., etc)
    return true if text.match?(/\A(?:[*+-]|\d+[.)]|[a-zA-Z][.)])\s+/)

    # Check for code blocks (indented with 4 spaces or fenced with ``` or ~~~)
    return true if text.match?(/\A(?:(?:.{4}|\t).*(?:\n|$)|\s*(?:```|~~~).*(?:\n|$))/)

    false
  end

  def build_plain_replacement(text)
    if text.strip.empty?
      " " # empty replacements may break markdown formatting
    else
      text
    end
  end

  def build_html_replacement(markdown)
    if contains_nested_richtext?(markdown)
      "[#{I18n.t('export.macro.nested_rich_text_unsupported')}] "
    elsif markdown.strip.empty?
      " " # empty replacements may break markdown formatting
    else
      markdown_to_html(markdown)
    end
  end

  def markdown_to_html(markdown)
    document = Markly.parse(
      markdown,
      flags: Markly::SMART | Markly::STRIKETHROUGH_DOUBLE_TILDE | Markly::UNSAFE | Markly::VALIDATE_UTF8,
      extensions: %i[autolink strikethrough table tagfilter tasklist]
    )
    document.to_html
  end

  def contains_nested_richtext?(markdown)
    UNSUPPORTED_NESTED.any? { |entry| markdown.include?(entry) } ||
      UNSUPPORTED_NESTED_REGEX.any? { |regex| markdown.match?(regex) }
  end

  def apply_macro_html(html, context)
    return html unless applicable?(html)

    doc = Nokogiri::HTML.fragment(html)
    apply_macro_html_node(doc, context)
    doc.to_html
  end

  def apply_macro_html_node(node, context)
    if node.text?
      formatted = apply_macro_text(node.content, true, context)
      node.replace(formatted) if formatted != node.content
    elsif PREFORMATTED_BLOCKS.exclude?(node.name)
      node.children.each { |child| apply_macro_html_node(child, context) }
    end
  end
end
