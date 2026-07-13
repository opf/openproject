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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "strscan"

module Import
  module JiraWikiMarkup
    class Parser
      N = Nodes

      EMOTICON_KEYS = %w[
        (flagoff) (flag) (*r) (*g) (*b) (*y) (*) (on) (off)
        (y) (n) (i) (/) (x) (!) (+) (-) (?)
        :) :( :P :D ;)
      ].freeze

      EMOTICON_REGEX = Regexp.new(
        EMOTICON_KEYS.sort_by { |k| -k.length }.map { |k| Regexp.escape(k) }.join("|")
      )

      def initialize(text)
        # Normalize any input into a safe, mutable UTF-8 string: nil becomes "",
        # and invalid byte sequences are dropped so downstream regex/StringScanner
        # operations cannot raise ArgumentError on malformed input.
        @text = text.to_s.dup
        @text.scrub!("?") unless @text.valid_encoding?
      end

      def parse
        return N::Document.new(children: []) if @text.blank?

        preprocess
        blocks = parse_blocks
        N::Document.new(children: blocks)
      end

      private

      def preprocess
        @text.gsub!("\r\n", "\n")
      end

      def parse_blocks
        lines = @text.split("\n", -1)
        blocks = []
        index = 0

        while index < lines.length
          line = lines[index]
          node, index = parse_block_line(line, lines, index)

          blocks << node if node
        end

        blocks
      end

      def parse_block_line(line, lines, index)
        block_patterns.each do |pattern, handler|
          match = line.match(pattern)
          return send(handler, lines, index, match) if match
        end

        [N::Paragraph.new(children: parse_inline(line)), index + 1]
      end

      def block_patterns
        @block_patterns ||= [
          [/\A\{code(?::([^}]*))?\}(.+)\z/, :handle_inline_code_block],
          [/\A\{code(?::([^}]*))?\}\s*\z/, :handle_code_block],
          [/\A\{noformat(?::([^}]*))?\}(.+)\z/, :handle_inline_noformat_block],
          [/\A\{noformat(?::([^}]*))?\}\s*\z/, :handle_noformat_block],
          [/\A\{quote\}(.+)\z/, :handle_inline_quote_start],
          [/\A\{quote\}\s*\z/, :handle_quote_block],
          [/\A\{panel(?::([^}]*))?\}(.+)\z/, :handle_inline_panel_block],
          [/\A\{panel(?::([^}]*))?\}\s*\z/, :handle_panel_block],
          [/\Ah([1-6])\.\s+(.*)\z/, :handle_heading],
          [/\A----\s*\z/, :handle_horizontal_rule],
          [/\A\s*([*#]+)\s/, :handle_list],
          [/\A\s*-\s/, :handle_dash_list],
          [/\Abq\.\s+(.*)\z/, :handle_block_quote],
          [/\A\|\|.+\|\|\s*\z/, :handle_table_header],
          [/\A\|.+\|\s*\z/, :handle_table_data_row],
          [/\A\s*\z/, :handle_blank_line]
        ]
      end

      def handle_inline_code_block(lines, index, match)
        line = lines[index]
        # Check if this line has a closing {code} tag after the opening tag
        # The regex captured everything after the opening tag in match[2]
        remaining = match[2]
        if remaining.include?("{code}")
          # Has closing tag on same line - treat as inline code block in paragraph
          [N::Paragraph.new(children: parse_inline(line)), index + 1]
        else
          # No closing tag - treat as multi-line block start with first line content
          language, params = parse_code_block_header(match[1])
          consume_code_block_with_first_line(lines, index, language, params, remaining)
        end
      end

      def handle_code_block(lines, index, match)
        language, params = parse_code_block_header(match[1])
        consume_code_block(lines, index, language, params)
      end

      def handle_inline_noformat_block(lines, index, match)
        line = lines[index]
        # Check if this line has a closing {noformat} tag after the opening tag
        remaining = match[2]
        if remaining.include?("{noformat}")
          # Has closing tag on same line - treat as inline noformat block in paragraph
          [N::Paragraph.new(children: parse_inline(line)), index + 1]
        else
          # No closing tag - treat as multi-line block start with first line content
          params = parse_macro_params(match[1])
          consume_noformat_block_with_first_line(lines, index, params, remaining)
        end
      end

      def handle_noformat_block(lines, index, match)
        params = parse_macro_params(match[1])
        consume_noformat_block(lines, index, params)
      end

      def handle_inline_quote_start(lines, index, match)
        content = match[1]
        # Check if this is an inline quote (content on same line) that spans to next line
        if index + 1 < lines.length && lines[index + 1].match?(/\A\{quote\}\s*\z/)
          # Single line inline quote: {quote}content\n{quote}
          [N::BlockQuote.new(children: parse_inline(content)), index + 2]
        else
          # Not a recognized pattern, treat as paragraph
          [N::Paragraph.new(children: parse_inline(lines[index])), index + 1]
        end
      end

      def handle_quote_block(lines, index, _match)
        node, new_index = consume_quote_block(lines, index)
        [node, new_index]
      end

      def handle_inline_panel_block(lines, index, match)
        # Check if this line has a closing {panel} tag after the opening tag
        remaining = match[2]
        params = parse_macro_params(match[1])
        if remaining.include?("{panel}")
          # Has closing tag on same line - treat as inline panel block
          # Extract content between opening and closing tags
          content = remaining.sub(/\{panel\}.*\z/, "").strip
          render_panel_content(content, params, index)
        else
          # No closing tag - treat as multi-line block start with first line content
          consume_panel_block_with_first_line(lines, index, params, remaining)
        end
      end

      def handle_panel_block(lines, index, match)
        params = parse_macro_params(match[1])
        consume_panel_block(lines, index, params)
      end

      def render_panel_content(content, params, index)
        title = params["title"]
        output = if title
                   "**#{title}**\n#{content}"
                 else
                   content
                 end
        [N::Paragraph.new(children: parse_inline(output)), index + 1]
      end

      def handle_heading(_lines, index, match)
        level = match[1].to_i
        content = match[2]
        [N::Heading.new(level:, children: parse_inline(content)), index + 1]
      end

      def handle_horizontal_rule(_lines, index, _match)
        [N::HorizontalRule.new, index + 1]
      end

      def handle_list(lines, index, _match)
        consume_list(lines, index)
      end

      def handle_dash_list(lines, index, _match)
        consume_list(lines, index)
      end

      def handle_block_quote(_lines, index, match)
        content = match[1]
        [N::BlockQuote.new(children: parse_inline(content)), index + 1]
      end

      def handle_table_header(lines, index, _match)
        line = lines[index]
        inner = line.delete_prefix("||").sub(/\|\|\s*\z/, "")
        cells = inner.split("||").map(&:strip)
        [N::TableHeaderRow.new(cells:), index + 1]
      end

      def handle_table_data_row(lines, index, _match)
        [N::TableDataRow.new(raw: lines[index]), index + 1]
      end

      def handle_blank_line(_lines, index, _match)
        [N::BlankLine.new, index + 1]
      end

      # Generic block consumer for code, noformat, and panel blocks
      def consume_delimited_block(lines, start, closing_tag, first_line_content: nil)
        i = start + 1
        content_lines = first_line_content ? [first_line_content] : []
        closing_pattern = /\{#{Regexp.escape(closing_tag)}\}\s*\z/

        while i < lines.length
          if lines[i].match?(closing_pattern)
            before_tag = lines[i].sub(/\s*\{#{Regexp.escape(closing_tag)}\}\s*\z/, "")
            content_lines << before_tag unless before_tag.empty?
            break
          else
            content_lines << lines[i]
          end
          i += 1
        end

        [content_lines.join("\n"), i + 1]
      end

      def consume_code_block(lines, start, language, params)
        content, new_index = consume_delimited_block(lines, start, "code")
        [N::CodeBlock.new(language:, params:, content:), new_index]
      end

      def consume_code_block_with_first_line(lines, start, language, params, first_line_content)
        content, new_index = consume_delimited_block(lines, start, "code", first_line_content:)
        [N::CodeBlock.new(language:, params:, content:), new_index]
      end

      def consume_noformat_block(lines, start, params)
        content, new_index = consume_delimited_block(lines, start, "noformat")
        [N::NoformatBlock.new(params:, content:), new_index]
      end

      def consume_noformat_block_with_first_line(lines, start, params, first_line_content)
        content, new_index = consume_delimited_block(lines, start, "noformat", first_line_content:)
        [N::NoformatBlock.new(params:, content:), new_index]
      end

      def consume_quote_block(lines, start)
        i = start + 1
        inner_lines = []

        while i < lines.length
          break if lines[i].match?(/\A\{quote\}\s*\z/)

          inner_lines << lines[i]
          i += 1
        end

        parsed_lines = inner_lines.map { |l| parse_inline(l) }
        [N::MultiLineBlockQuote.new(lines: parsed_lines), i + 1]
      end

      def consume_panel_block(lines, start, params)
        content, new_index = consume_delimited_block(lines, start, "panel")
        [N::Panel.new(params:, content: content.strip), new_index]
      end

      def consume_panel_block_with_first_line(lines, start, params, first_line_content)
        content, new_index = consume_delimited_block(lines, start, "panel", first_line_content:)
        [N::Panel.new(params:, content: content.strip), new_index]
      end

      def consume_list(lines, start)
        flat_items = []
        i = start

        while i < lines.length
          item = parse_list_line(lines[i])
          break unless item

          flat_items << item
          i += 1
        end

        [build_list_tree(flat_items, 0, 0, flat_items.length), i]
      end

      def parse_list_line(line)
        if line =~ /\A\s*([*#]+)\s+(.*)\z/
          marker = Regexp.last_match(1)
          { marker_type: marker[-1] == "#" ? :ordered : :unordered,
            depth: marker.length - 1,
            children: parse_inline(Regexp.last_match(2)) }
        elsif line =~ /\A\s*-\s+(.*)\z/
          { marker_type: :unordered, depth: 0, children: parse_inline(Regexp.last_match(1)) }
        end
      end

      def build_list_tree(flat_items, target_depth, start, finish)
        list_type = flat_items[start][:marker_type]
        items = []
        i = start

        while i < finish
          item = flat_items[i]
          if item[:depth] == target_depth
            sub_end = find_sublist_end(flat_items, i, finish, target_depth)
            sublist = sub_end > i + 1 ? build_list_tree(flat_items, target_depth + 1, i + 1, sub_end) : nil
            items << N::ListItem.new(children: item[:children], sublist:)
            i = sub_end
          else
            i += 1
          end
        end

        N::List.new(list_type:, items:)
      end

      def find_sublist_end(flat_items, start, finish, target_depth)
        j = start + 1
        j += 1 while j < finish && flat_items[j][:depth] > target_depth
        j
      end

      def parse_inline(text)
        nodes = []
        buffer = +""
        scanner = StringScanner.new(text)

        until scanner.eos?
          next if scan_macro(scanner, buffer, nodes)
          next if scan_reference(scanner, buffer, nodes)
          next if scan_image(scanner, buffer, nodes)
          next if scan_escape(scanner, buffer, nodes)
          next if scan_emoticon_or_dash(scanner, buffer, nodes)
          next if scan_text_style(scanner, buffer, nodes)

          buffer << scanner.getch
        end

        flush_text(buffer, nodes)
        nodes
      end

      def scan_macro(scanner, buffer, nodes)
        scan_inline_code_block(scanner, buffer, nodes) ||
          scan_inline_noformat_block(scanner, buffer, nodes) ||
          scan_inline_quote(scanner, buffer, nodes) ||
          scan_color_macro(scanner, buffer, nodes) ||
          scan_inline_code_macro(scanner, buffer, nodes) ||
          scan_citation_macro(scanner, buffer, nodes)
      end

      def scan_inline_code_block(scanner, buffer, nodes)
        # Match {code:lang}content{code} or {code}content{code}
        return unless scanner.scan(/\{code(?::([^}]*))?\}(.*?)\{code\}/)

        header = scanner[1]
        content = scanner[2]

        language, _params = parse_code_block_header(header)

        # Render inline code blocks as raw markdown text
        lang_marker = language || ""
        code_text = "```#{lang_marker}\n#{content}\n```"

        flush_and_add(buffer, nodes, N::Text.new(content: code_text))
      end

      def scan_inline_noformat_block(scanner, buffer, nodes)
        # Match {noformat}content{noformat}
        return unless scanner.scan(/\{noformat(?::([^}]*))?\}(.*?)\{noformat\}/)

        content = scanner[2]

        # Render inline noformat blocks as raw markdown text
        code_text = "```\n#{content}\n```"

        flush_and_add(buffer, nodes, N::Text.new(content: code_text))
      end

      def scan_inline_quote(scanner, buffer, nodes)
        return unless scanner.scan(/\{quote\}(.*?)\{quote\}/)

        flush_and_add(buffer, nodes, N::BlockQuote.new(children: parse_inline(scanner[1])))
      end

      def scan_color_macro(scanner, buffer, nodes)
        return unless scanner.scan(/\{color:[^}]*\}(.*?)\{color\}/)

        flush_and_add(buffer, nodes, N::ColorMacro.new(children: parse_inline(scanner[1])))
      end

      def scan_inline_code_macro(scanner, buffer, nodes)
        return unless scanner.scan(/\{\{([^}]+)\}\}/)

        flush_and_add(buffer, nodes, N::InlineCode.new(content: scanner[1]))
      end

      def scan_citation_macro(scanner, buffer, nodes)
        return unless scanner.scan(/\?\?(.+?)\?\?/)

        flush_and_add(buffer, nodes, N::Citation.new(children: parse_inline(scanner[1])))
      end

      def scan_reference(scanner, buffer, nodes)
        if scanner.scan(/\[~([^\]]+)\]/)
          flush_and_add(buffer, nodes, N::Mention.new(username: scanner[1]))
        elsif scanner.scan(/\[([^|~\]]+)\|([^\]]+)\]/)
          flush_and_add(buffer, nodes, N::Link.new(text: scanner[1], url: scanner[2]))
        elsif scanner.scan(/\[([^\]|~]+)\]/)
          scan_bare_link(scanner, buffer, nodes)
        end
      end

      def scan_bare_link(scanner, buffer, nodes)
        url = scanner[1]
        if url.match?(%r{\A(https?://|www\.)})
          flush_and_add(buffer, nodes, N::Link.new(text: nil, url:))
        else
          buffer << scanner.matched
        end
      end

      def scan_image(scanner, buffer, nodes)
        if scanner.scan(/!([^!\s|]+)\|([^!]+)!/)
          flush_and_add(buffer, nodes, N::Image.new(url: scanner[1], params: parse_image_params(scanner[2])))
        elsif scanner.scan(/!([^!\s|]+)!/)
          flush_and_add(buffer, nodes, N::Image.new(url: scanner[1], params: {}))
        end
      end

      def scan_escape(scanner, buffer, nodes)
        if scanner.scan("\\\\")
          flush_and_add(buffer, nodes, N::LineBreak.new)
        elsif scanner.scan(/\\([{}\[\]!*_\-+^~#|\\])/)
          buffer << scanner[1]
        end
      end

      def scan_emoticon_or_dash(scanner, buffer, nodes)
        if scanner.scan(EMOTICON_REGEX)
          flush_and_add(buffer, nodes, N::Emoticon.new(key: scanner.matched))
        elsif scanner.scan("---")
          flush_and_add(buffer, nodes, N::EmDash.new)
        elsif scanner.scan("--")
          flush_and_add(buffer, nodes, N::EnDash.new)
        end
      end

      def scan_text_style(scanner, buffer, nodes)
        scan_formatting(scanner, buffer, nodes, "*", N::Bold) ||
          scan_formatting(scanner, buffer, nodes, "_", N::Italic) ||
          scan_formatting(scanner, buffer, nodes, "-", N::Strikethrough) ||
          scan_formatting(scanner, buffer, nodes, "+", N::Underline) ||
          scan_superscript(scanner, buffer, nodes) ||
          scan_subscript(scanner, buffer, nodes)
      end

      def scan_superscript(scanner, buffer, nodes)
        return unless scanner.scan(/\^([^^]+)\^/)

        flush_and_add(buffer, nodes, N::Superscript.new(children: parse_inline(scanner[1])))
      end

      def scan_formatting(scanner, buffer, nodes, delimiter, node_class)
        return if preceded_by_word?(buffer)

        inner = extract_delimited(scanner, delimiter)
        return unless inner

        flush_and_add(buffer, nodes, node_class.new(children: parse_inline(inner)))
      end

      def preceded_by_word?(buffer)
        !buffer.empty? && buffer[-1].match?(/\w/)
      end

      def extract_delimited(scanner, delimiter)
        rest_all = scanner.rest
        return unless rest_all.start_with?(delimiter)

        rest = rest_all[1..]
        return if rest.blank? || rest[0] == " "

        close_idx = rest.index(delimiter)
        return unless close_idx&.positive?

        inner = rest[0...close_idx]
        return if inner[-1] == " "
        return if followed_by_word?(rest, close_idx)

        # StringScanner#pos is byte-based; advance by byte length, not char count,
        # so multi-byte UTF-8 content inside the delimiters does not land pos mid-character.
        scanner.pos += inner.bytesize + 2
        inner
      end

      def followed_by_word?(text, close_idx)
        after = text[(close_idx + 1)..]
        after.present? && after[0].match?(/\w/)
      end

      def scan_subscript(scanner, buffer, nodes)
        return unless scanner.rest[0] == "~"

        scanned = scanner.string.byteslice(0, scanner.pos)
        return if (scanned + buffer).end_with?("~")

        inner = extract_subscript_content(scanner)
        return unless inner

        flush_and_add(buffer, nodes, N::Subscript.new(children: parse_inline(inner)))
      end

      def extract_subscript_content(scanner)
        rest = scanner.rest[1..]
        return if rest.blank?

        close_idx = rest.index("~")
        return unless close_idx&.positive?

        inner = rest[0...close_idx]
        return if inner.include?("~")

        after = rest[(close_idx + 1)..]
        return if after.present? && after[0] == "~"

        # StringScanner#pos is byte-based; advance by byte length to stay on a char boundary.
        scanner.pos += inner.bytesize + 2
        inner
      end

      def parse_code_block_header(raw)
        return [nil, {}] if raw.nil?

        parts = raw.split("|")
        first = parts.shift.strip

        if first.include?("=")
          params = parse_macro_params(raw)
          [nil, params]
        else
          params = parse_macro_params(parts.join("|"))
          language = first.empty? ? nil : first
          [language, params]
        end
      end

      def parse_macro_params(raw)
        return {} if raw.nil?

        params = {}
        raw.split("|").each do |segment|
          key, value = segment.strip.split("=", 2)
          params[key.strip] = value&.strip
        end
        params
      end

      def parse_image_params(raw)
        params = {}
        raw.split(",").each do |segment|
          part = segment.strip
          if part.include?("=")
            key, value = part.split("=", 2)
            params[key.strip] = value.strip
          elsif part == "thumbnail"
            params["thumbnail"] = true
          else
            params["alt"] = part
          end
        end
        params
      end

      def flush_text(buffer, nodes)
        return if buffer.empty?

        nodes << N::Text.new(content: buffer.dup)
        buffer.clear
      end

      def flush_and_add(buffer, nodes, node)
        flush_text(buffer, nodes)
        nodes << node
      end
    end
  end
end
