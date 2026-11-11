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

      INLINE_QUOTE_PATTERN = /\{quote\}(.*?)\{quote\}/
      TABLE_ROW_PATTERN = /\A\|.+\z/
      # Macros whose body may span lines, so a table row stays open until they close.
      MULTILINE_MACRO_PATTERN = /\{(code|noformat|panel|quote)(:[^}]*)?\}/
      # Jira bounds an attachment name only by the delimiters: spaces are allowed
      # anywhere but the first character, and no file extension is required. That
      # leading character is the whole guard against an exclamation mark in prose,
      # which is why "Stop! Now!" is text while "!no extension!" is an embed.
      IMAGE_NAME = /[^!|\s][^!|\n]*/
      IMAGE_WITH_PARAMS_PATTERN = /!(#{IMAGE_NAME})\|([^!\n]+)!/
      IMAGE_PATTERN = /!(#{IMAGE_NAME})!/
      # Regions of a row whose separators belong to the content: a macro body, a
      # [text|url] link, or the !image|params! form that scan_image accepts.
      PROTECTED_CELL_REGION = /
        \{(code|noformat|panel|quote|color)(?::[^}]*)?\}.*?\{\1\}
        | \[[^\]]*\]
        | #{IMAGE_WITH_PARAMS_PATTERN}
      /mx
      CELL_SEPARATOR_PLACEHOLDER = "\u0000"

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

          blocks.concat(Array.wrap(node)) if node
        end

        blocks
      end

      def parse_block_line(line, lines, index)
        block_patterns.each do |pattern, handler|
          match = line.match(pattern)
          return send(handler, lines, index, match) if match
        end

        split_quote_line(line, index) || [N::Paragraph.new(children: parse_inline(line)), index + 1]
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
          [TABLE_ROW_PATTERN, :handle_table],
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
        remaining = match[1]
        if remaining.include?("{quote}")
          split_quote_line(lines[index], index)
        else
          consume_quote_block(lines, index, first_line_content: remaining)
        end
      end

      def handle_quote_block(lines, index, _match)
        consume_quote_block(lines, index)
      end

      def handle_inline_panel_block(lines, index, match)
        # Check if this line has a closing {panel} tag after the opening tag
        remaining = match[2]
        params = parse_macro_params(match[1])
        if remaining.include?("{panel}")
          # Has closing tag on same line - treat as inline panel block
          # Extract content between opening and closing tags
          content = remaining.sub(/\{panel\}.*\z/, "").strip
          [N::Panel.new(params:, children: parse_inline(content)), index + 1]
        else
          # No closing tag - treat as multi-line block start with first line content
          consume_panel_block_with_first_line(lines, index, params, remaining)
        end
      end

      def handle_panel_block(lines, index, match)
        params = parse_macro_params(match[1])
        consume_panel_block(lines, index, params)
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

      def handle_table(lines, index, _match)
        consume_table(lines, index)
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

      def consume_quote_block(lines, start, first_line_content: nil)
        content, new_index = consume_delimited_block(lines, start, "quote", first_line_content:)
        parsed_lines = content.empty? ? [] : content.split("\n", -1).map { |quote_line| parse_inline(quote_line) }
        [N::MultiLineBlockQuote.new(lines: parsed_lines), new_index]
      end

      # Jira treats {quote} as a block macro even mid-line: it ends the current
      # paragraph, quotes its content, and resumes a new paragraph afterwards.
      def split_quote_line(line, index)
        return unless line.match?(INLINE_QUOTE_PATTERN)

        nodes = []
        rest = line

        while (match = rest.match(INLINE_QUOTE_PATTERN))
          append_paragraph(nodes, match.pre_match)
          nodes << N::MultiLineBlockQuote.new(lines: [parse_inline(match[1])])
          rest = match.post_match
        end
        append_paragraph(nodes, rest)

        [nodes, index + 1]
      end

      def append_paragraph(nodes, text)
        stripped = text.strip
        nodes << N::Paragraph.new(children: parse_inline(stripped)) if stripped.present?
      end

      # Every row is consumed the same way; a leading row made entirely of header
      # cells becomes the head. Jira writes a key/value table as a run of header
      # rows, so breaking the run at each one would split it into many tables.
      def consume_table(lines, start)
        rows, i = consume_table_rows(lines, start)

        return [N::Paragraph.new(children: parse_inline(lines[start])), start + 1] if rows.empty?

        header = rows.shift if header_row?(rows.first)

        [N::Table.new(header:, rows:), i]
      end

      def header_row?(cells)
        cells.any? && cells.all?(&:header)
      end

      def consume_table_rows(lines, start)
        rows = []
        i = start

        while i < lines.length && lines[i].start_with?("|")
          cells, row_end = consume_table_row(lines, i)
          break unless cells

          rows << cells
          i = row_end
        end

        [rows, i]
      end

      # A cell may hold a multi-line macro, so the row runs on until that macro
      # closes. A row that never closes is not a row at all: nothing is consumed, so
      # the line falls back to normal block parsing instead of swallowing the rest
      # of the document.
      def consume_table_row(lines, start)
        i = start
        row = +""
        open_macro = false

        while i < lines.length
          row << "\n" unless row.empty?
          row << lines[i]
          i += 1
          open_macro = unclosed_macro?(row)
          break unless open_macro
        end

        return if open_macro
        # A row only runs past its own line to let a macro close, and that form is
        # always written with its closing separator. Without requiring it, a macro
        # left open in one cell would pull in everything up to some later bare tag
        # that happens to close it.
        return if i > start + 1 && !row.rstrip.end_with?("|")

        cells = parse_cells(row)
        [cells, i] if cells
      end

      # Only a bare tag closes a macro, so counting tags would read two openers such
      # as {code:java} as a balanced pair. The tags are walked in order instead, and
      # tags of another name are passed over while one is open.
      def unclosed_macro?(text)
        open = nil
        text.scan(MULTILINE_MACRO_PATTERN) do |name, params|
          if open.nil?
            open = name
          elsif open == name && params.nil?
            open = nil
          end
        end
        !open.nil?
      end

      # A run of two or more separators introduces a header cell and a single one a
      # data cell, which is how Jira writes both header rows and header columns. The
      # leading run opens the row and the closing run is optional, since Jira lets it
      # be left off; neither yields a cell. A line holding only the opening run is
      # not a row. Separators belonging to a macro body, a link, an image or an
      # escaped \| are masked first and so never split anything.
      def parse_cells(row)
        segments = mask_protected_separators(row.strip).split(/(\|+)/, -1)
        segments.shift
        parts = segments.each_slice(2).to_a
        return if parts.size < 2

        parts.pop if parts.last.last.empty?
        parts.map { |separator, content| build_cell(separator, content) }
      end

      def build_cell(separator, content)
        children = parse_inline(content.tr(CELL_SEPARATOR_PLACEHOLDER, "|").strip)
        N::TableCell.new(children:, header: separator.length > 1)
      end

      # Jira's escape token swallows a separator that immediately follows it, so
      # "\||" yields one literal separator rather than a literal plus a live one.
      def mask_protected_separators(inner)
        inner
          .gsub(/\\\|\|?/, CELL_SEPARATOR_PLACEHOLDER)
          .gsub(PROTECTED_CELL_REGION) { |region| region.tr("|", CELL_SEPARATOR_PLACEHOLDER) }
      end

      def consume_panel_block(lines, start, params)
        content, new_index = consume_delimited_block(lines, start, "panel")
        [N::Panel.new(params:, children: parse_inline(content.strip)), new_index]
      end

      def consume_panel_block_with_first_line(lines, start, params, first_line_content)
        content, new_index = consume_delimited_block(lines, start, "panel", first_line_content:)
        [N::Panel.new(params:, children: parse_inline(content.strip)), new_index]
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

        return [N::Paragraph.new(children: parse_inline(lines[start])), start + 1] if flat_items.empty?

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
        depth = list_depth(flat_items, target_depth, start, finish)
        items = []
        i = start

        while i < finish
          sub_end = find_sublist_end(flat_items, i, finish, depth)
          items << build_list_item(flat_items, depth, i, sub_end)
          i = sub_end
        end

        N::List.new(list_type: flat_items[start][:marker_type], items:)
      end

      def list_depth(flat_items, target_depth, start, finish)
        [target_depth, (start...finish).map { |j| flat_items[j][:depth] }.min].max
      end

      def build_list_item(flat_items, depth, start, finish)
        sublist = build_list_tree(flat_items, depth + 1, start + 1, finish) if finish > start + 1
        N::ListItem.new(children: flat_items[start][:children], sublist:)
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
          scan_inline_panel(scanner, buffer, nodes) ||
          scan_color_macro(scanner, buffer, nodes) ||
          scan_inline_code_macro(scanner, buffer, nodes) ||
          scan_citation_macro(scanner, buffer, nodes)
      end

      def scan_inline_code_block(scanner, buffer, nodes)
        # Match {code:lang}content{code} or {code}content{code}
        return unless scanner.scan(/\{code(?::([^}]*))?\}(.*?)\{code\}/m)

        language, params = parse_code_block_header(scanner[1])

        flush_and_add(buffer, nodes, N::CodeBlock.new(language:, params:, content: trim_macro_body(scanner[2])))
      end

      def scan_inline_noformat_block(scanner, buffer, nodes)
        # Match {noformat}content{noformat}
        return unless scanner.scan(/\{noformat(?::([^}]*))?\}(.*?)\{noformat\}/m)

        flush_and_add(buffer, nodes,
                      N::NoformatBlock.new(params: parse_macro_params(scanner[1]), content: trim_macro_body(scanner[2])))
      end

      def scan_inline_quote(scanner, buffer, nodes)
        return unless scanner.scan(/\{quote\}(.*?)\{quote\}/)

        flush_and_add(buffer, nodes, N::BlockQuote.new(children: parse_inline(scanner[1])))
      end

      def scan_inline_panel(scanner, buffer, nodes)
        return unless scanner.scan(/\{panel(?::([^}]*))?\}(.*?)\{panel\}/m)

        params = parse_macro_params(scanner[1])
        flush_and_add(buffer, nodes,
                      N::Panel.new(params:, children: parse_inline(trim_macro_body(scanner[2]))))
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
        if scanner.scan(IMAGE_WITH_PARAMS_PATTERN)
          flush_and_add(buffer, nodes, N::Image.new(url: scanner[1], params: parse_image_params(scanner[2])))
        elsif scanner.scan(IMAGE_PATTERN)
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

      # A macro opened on its own line contributes newlines that are delimiters,
      # not content.
      def trim_macro_body(content)
        content.delete_prefix("\n").delete_suffix("\n")
      end

      def parse_code_block_header(raw)
        return [nil, {}] if raw.nil?

        parts = raw.split("|")
        first = parts.shift.to_s.strip

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
          part = segment.strip
          next if part.empty?
          next unless part.include?("=")

          key, value = part.split("=", 2)
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
