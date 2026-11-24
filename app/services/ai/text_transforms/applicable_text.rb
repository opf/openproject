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

module AI
  module TextTransforms
    # The model output as the pane shows, copies and inserts it: without macros, images and new mentions.
    class ApplicableText
      PARSE_OPTIONS = {
        parse: { smart: false },
        extension: { table: true, strikethrough: true, tagfilter: false, autolink: false, tasklist: false, shortcodes: false }
      }.freeze
      RENDER_OPTIONS = PARSE_OPTIONS.merge(render: { unsafe: true }).freeze
      # Comments (ended as HTML5 ends them) and declarations hide the tags in them, and attribute values belong to
      # their tag. As in HTML5, only a value after "=" can be quoted, other quotes belong to the attribute name.
      HTML_TOKEN = %r{
        <!--(?:-?>|.*?--!?>|(?<unclosed>.*))
        |<[!?][^>]*(?:>|(?<unclosed>\z))
        |<(?<closing>/?)(?<name>[a-z][^\s/>]*)
          (?>[\s/]+|[^\s/>][^\s/>=]*(?:\s*=\s*(?:"[^"]*(?:"|\z)|'[^']*(?:'|\z)|[^\s>]*))?)*>?
      }imx
      REWRITTEN_TAGS = %w[macro img mention].freeze
      MARKDOWN_SPECIAL = /[\\`*_{}\[\]<>()#+!|~&]/
      DESTINATION_SPECIAL = /[\s()<>]/
      LINE_BREAK = /\r\n?|\n/
      TEXT = %i[text escaped].freeze
      HTML = %i[html_inline html_block].freeze
      CODE = %i[code code_block].freeze
      CODE_ELEMENTS = OpenProject::TextFormatting::PreformattedBlocks::BLOCKS
      OPENER = /<[!?]/
      MAX_PASSES = 3

      class TooDeep < StandardError; end

      def self.call(text, input: "") = new(text, input:).call

      def initialize(text, input: "")
        @text = text.encode(Encoding::UTF_8)
        @mentions = NewMentions.new(input)
      end

      def call
        @call ||= begin
          result = rewritten_until_stable
          rendered = render(result)
          active_markup_in?(rendered) ? plain_text(rendered) : result
        rescue TooDeep
          escape(@mentions.convert(@text))
        end
      end

      def mentions_converted?
        call
        @mentions.found?
      end

      private

      # The tag scan cannot follow every HTML5 parsing rule, such as raw text elements, so the rendered result is
      # checked as well.
      def active_markup_in?(rendered)
        rendered.css("macro, img").any? || @mentions.hidden_in?(rendered)
      end

      # Removing a tag can join the text around it into new markup, such as an image, so the result is rewritten
      # again until it no longer changes.
      def rewritten_until_stable
        text = @text
        MAX_PASSES.times do
          rewritten = rewrite_pass(text)
          return text if rewritten == text

          text = rewritten
        end
        plain_text(render(text))
      end

      def rewrite_pass(text)
        @text = text
        @document = @line_offsets = nil
        escape_unclosed_openers
        walk_document
        close_macro(@macro[:closes_at]) if @macro
        @mentions.convert(splice(@edits))
      end

      # An unclosed comment or declaration hides the text and tags after it, so its opener is escaped and the text
      # parsed again. Further openers it hid may be unclosed as well, so from the second round on all are escaped.
      # Those that the second round turns out to have escaped in code are restored once.
      def escape_unclosed_openers
        rounds = 0
        loop do
          unclosed = scan_html_tokens
          next if rounds == 2 && restore_openers_in_code
          break if unclosed.empty?

          rounds += 1
          @escaped = escape_openers(rounds == 1 ? unclosed.map(&:begin) : unclosed.flat_map { openers_in(it) })
        end
      end

      def restore_openers_in_code
        in_code = @escaped.select { |offset| @code_ranges.bsearch { it.end > offset }&.cover?(offset) }
        @escaped = []
        return false if in_code.empty?

        @text = splice(in_code.map { [it...(it + 4), "<"] })
        @document = @line_offsets = nil
        true
      end

      def scan_html_tokens
        unclosed = []
        macro_tokens = []
        @code_ranges = []
        document.walk do |node|
          @code_ranges << byte_range(node) if CODE.include?(node.type)
          scan_html_node(node, unclosed, macro_tokens) if HTML.include?(node.type)
        end
        @macros_ending_with_block = macros_never_closed(macro_tokens)
        unclosed
      end

      def scan_html_node(node, unclosed, macro_tokens)
        each_html_token(byte_range(node)) do |match, range|
          if match[:unclosed]
            unclosed << range
          elsif match[:name]&.casecmp?("macro")
            macro_tokens << [range.begin, macro_depth_change(match), node.type == :html_block]
          end
        end
      end

      def macro_depth_change(match)
        return -1 if match[:closing].present?

        match[0].end_with?("/>") ? 0 : 1
      end

      # A macro in an HTML block that no later tag closes ends with its block. A later closing tag closes it
      # where the nesting depth first drops below the depth after its opening tag.
      def macros_never_closed(tokens)
        depth = 0
        depths = tokens.map { |_, change, _| depth += change }
        lowest_later = Float::INFINITY
        never_closed = Set.new
        tokens.each_with_index.reverse_each do |(first, change, block), index|
          never_closed << first if block && change == 1 && lowest_later >= depths[index]
          lowest_later = [lowest_later, depths[index]].min
        end
        never_closed
      end

      def walk_document
        @edits = []
        @mention_tags = []
        @macro = nil
        document.walk do |node|
          range = byte_range(node)
          close_macro(@macro[:closes_at]) if @macro && range.begin >= @macro[:closes_at]
          rewrite(node, range) unless range.begin < covered_until
        end
      end

      def document
        @document ||= Commonmarker.parse(@text, options: PARSE_OPTIONS)
      end

      def escape_openers(offsets)
        @text = splice(offsets.map { [it...(it + 1), "&lt;"] })
        @document = @line_offsets = nil
        offsets.each_with_index.map { |offset, index| offset + (index * 3) }
      end

      def splice(replacements)
        text = @text.b
        last = 0
        result = replacements.each_with_object(+"".b) do |(range, replacement), spliced|
          spliced << text.byteslice(last...range.begin) << replacement.b
          last = range.end
        end
        (result << text.byteslice(last..)).force_encoding(Encoding::UTF_8)
      end

      def openers_in(range)
        @text.byteslice(range).b.to_enum(:scan, OPENER).map { range.begin + Regexp.last_match.begin(0) }
      end

      def rewrite(node, range)
        return rewrite_tags(node, range) if HTML.include?(node.type)
        return if @macro

        case node.type
        when :image then edit_image(node, range)
        when :link then rewrite_link(node, range)
        when *TEXT then rewrite_text(node, range) unless TEXT.include?(node.previous_sibling&.type)
        end
      end

      # The link that replaces an image would be an image again after a "!" that is not escaped.
      def edit_image(node, range)
        link = markdown_image_link(node)
        return edit(range, link) unless link.start_with?("[") && unescaped_bang_before?(range.begin)

        edit((range.begin - 1)...range.end, "\\!#{link}")
      end

      def unescaped_bang_before?(offset)
        return false unless offset > covered_until && @text.getbyte(offset - 1) == 0x21

        backslashes = @text.b[0...(offset - 1)][/\\*\z/].size
        backslashes.even?
      end

      # Escaped characters split a text into several nodes, so they are read as one.
      def rewrite_text(node, range)
        nodes = text_run(node)
        text = nodes.map { it.type == :escaped ? it.first_child.string_content : it.string_content }.join
        converted = @mentions.convert(text)
        edit(range.begin...byte_range(nodes.last).end, escape(converted)) unless converted == text
      end

      def rewrite_link(node, range)
        edit(range, escape(@mentions.convert(plain_content(node)))) if @mentions.new_in?(node.url)
      end

      def text_run(node)
        nodes = [node]
        nodes << nodes.last.next_sibling while TEXT.include?(nodes.last.next_sibling&.type)
        nodes
      end

      def render(markdown)
        Nokogiri::HTML5.fragment(Commonmarker.to_html(markdown, options: RENDER_OPTIONS))
      rescue ArgumentError => e
        raise unless e.message.include?("depth limit")

        raise TooDeep
      end

      # Code stays code, since its text would otherwise turn into links and macros, such as wiki page links.
      # Escaping hides mentions that the editor unescapes again, so text is converted before it is escaped.
      def plain_text(rendered)
        runs = plain_parts(rendered).slice_when { |node, following| node.name == "pre" || run_kind(node) != run_kind(following) }
        @mentions.convert(runs.map { plain_markdown(it) }.join).strip
      end

      def run_kind(node) = node.element? ? node.name : "text"

      def plain_markdown(nodes)
        code = nodes.first
        text = nodes.map(&:text).join
        return escape(@mentions.convert(text)) unless code.element?

        code.name == "pre" ? code_block(text) : code_span(text)
      end

      def plain_parts(node)
        return [node] if node.text? || node.cdata? || CODE_ELEMENTS.include?(node.name)

        node.children.flat_map { plain_parts(it) }
      end

      def code_span(code)
        code = code.gsub(LINE_BREAK, " ")
        return code if code.blank?

        fence = "`" * (longest_backtick_run(code) + 1)
        padding = code.match?(/\A[` ]|[` ]\z/) ? " " : ""
        "#{fence}#{padding}#{code}#{padding}#{fence}"
      end

      def code_block(code)
        fence = "`" * [3, longest_backtick_run(code) + 1].max
        "\n#{fence}\n#{code.chomp}\n#{fence}\n"
      end

      def longest_backtick_run(code)
        code.scan(/`+/).map(&:size).max.to_i
      end

      def plain_content(node)
        node.to_enum(:walk).select { %i[text code].include?(it.type) }.map(&:string_content).join
      end

      def escape(text)
        text.gsub(MARKDOWN_SPECIAL) { "\\#{it}" }
      end

      def rewrite_tags(node, range)
        each_html_token(range) do |match, token_range|
          rewrite_tag(match, token_range, node) if REWRITTEN_TAGS.include?(match[:name]&.downcase)
        end
      end

      def each_html_token(range)
        @text.byteslice(range).scan(HTML_TOKEN) do
          match = Regexp.last_match
          first, last = match.byteoffset(0)
          yield match, (range.begin + first)...(range.begin + last)
        end
      end

      def rewrite_tag(match, range, node)
        closing = match[:closing].present?
        name = match[:name].downcase
        return rewrite_macro(match[0], range, node, closing) if name == "macro"
        return if @macro

        case name
        when "img" then edit(range, closing ? "" : html_image_link(match[0]))
        when "mention" then edit(range, "") if new_mention?(match[0], closing)
        end
      end

      # Like the preview, a macro disappears with everything inside it. An unclosed one ends with its paragraph
      # or HTML block, so that it does not hide the rest of the answer.
      def rewrite_macro(tag, range, node, closing)
        if closing
          @macro ? close_nested_macro(range) : edit(range, "")
        elsif tag.end_with?("/>")
          edit(range, "") unless @macro
        elsif @macro
          @macro[:depth] += 1
        else
          open_macro(range, node)
        end
      end

      def open_macro(range, node)
        @macro = { first: range.begin, depth: 1, closes_at: @text.bytesize }
        if node.type == :html_inline
          @macro[:closes_at] = byte_range(node.parent).end
        elsif @macros_ending_with_block.include?(range.begin)
          @macro[:closes_at] = byte_range(node).end
        end
      end

      def close_nested_macro(range)
        @macro[:depth] -= 1
        close_macro(range.end) if @macro[:depth].zero?
      end

      def close_macro(last)
        edit(@macro[:first]...last, "")
        @macro = nil
      end

      def new_mention?(tag, closing)
        closing ? @mention_tags.pop : @mention_tags.push(@mentions.new_tag?(attributes(tag))).last
      end

      def edit(range, replacement)
        @edits << [range, replacement]
      end

      def covered_until
        @edits.last&.first&.end || 0
      end

      def markdown_image_link(node)
        alt = @mentions.convert(plain_content(node))
        source = node.url.presence unless @mentions.new_in?(node.url)
        text = escape(image_link_text(alt, source))
        return text unless source

        "[#{text}](#{link_destination(source)})"
      end

      def link_destination(source)
        return source unless source.match?(DESTINATION_SPECIAL)

        "<#{source.gsub(/[<>\\]/) { "\\#{it}" }}>"
      end

      def html_image_link(tag)
        image = attributes(tag)
        source = image["src"].presence unless @mentions.new_in?(image["src"])
        text = ERB::Util.html_escape(image_link_text(@mentions.convert(image["alt"].to_s), source))
        source ? %(<a href="#{ERB::Util.html_escape(source)}">#{text}</a>) : text
      end

      def image_link_text(alt, source)
        OpenProject::TextFormatting::Filters::UntrustedSourceFilter.image_link_text(alt, source)
      end

      def attributes(tag)
        Nokogiri::HTML5.fragment(tag).element_children.first || {}
      end

      def byte_range(node)
        position = node.source_position
        first = line_offsets[position[:start_line] - 1] + position[:start_column] - 1
        last = line_offsets[position[:end_line] - 1] + position[:end_column]
        first...last
      end

      # Commonmarker counts a bare CR as a line break as well.
      def line_offsets
        @line_offsets ||= [0] + @text.b.to_enum(:scan, LINE_BREAK).map { Regexp.last_match.end(0) }
      end
    end
  end
end
