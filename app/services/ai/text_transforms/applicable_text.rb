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
      # Comments and declarations hide the tags in them, and attribute values belong to their tag.
      HTML_TOKEN = %r{<!--.*?(?:-->|\z)|<[!?][^>]*>?|<(/?)([a-z][^\s/>]*)(?:[^>"']|"[^"]*(?:"|\z)|'[^']*(?:'|\z))*>?}im
      REWRITTEN_TAGS = %w[macro img mention].freeze
      MARKDOWN_SPECIAL = /[\\`*_{}\[\]<>()#+!|~&]/
      DESTINATION_SPECIAL = /[\s()<>]/
      LINE_BREAK = /\r\n?|\n/
      TEXT = %i[text escaped].freeze
      DECODED = /[&\\]/

      def self.call(text, input: "") = new(text, input:).call

      def initialize(text, input: "")
        @text = text.encode(Encoding::UTF_8)
        @mentions = NewMentions.new(input)
        @edits = []
        @mention_tags = []
        @macro = nil
      end

      def call
        @call ||= begin
          collect_edits
          result = @mentions.convert(
            @edits.reverse.reduce(@text.b) { |text, (range, replacement)| text.bytesplice(range, replacement.b) }
                  .force_encoding(@text.encoding)
          )
          rendered = render(result) if result.match?(DECODED)
          rendered && @mentions.hidden_in?(rendered) ? plain_text(rendered) : result
        end
      end

      def mentions_converted?
        call
        @mentions.found?
      end

      private

      def collect_edits
        Commonmarker.parse(@text, options: PARSE_OPTIONS).walk do |node|
          range = byte_range(node)
          close_macro(@macro[:closes_at]) if @macro && range.begin >= @macro[:closes_at]
          rewrite(node, range) unless range.begin < covered_until
        end
        close_macro(@macro[:closes_at]) if @macro
      end

      def rewrite(node, range)
        return rewrite_tags(node, range) if %i[html_inline html_block].include?(node.type)
        return if @macro

        case node.type
        when :image then edit(range, markdown_image_link(node))
        when :link then rewrite_link(node, range)
        when *TEXT then rewrite_text(node, range) unless TEXT.include?(node.previous_sibling&.type)
        end
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
      end

      def plain_text(rendered)
        escape(@mentions.convert(rendered.text.strip))
      end

      def plain_content(node)
        node.to_enum(:walk).select { %i[text code].include?(it.type) }.map(&:string_content).join
      end

      def escape(text)
        text.gsub(MARKDOWN_SPECIAL) { "\\#{it}" }
      end

      def rewrite_tags(node, range)
        @text.byteslice(range).scan(HTML_TOKEN) do
          match = Regexp.last_match
          next unless REWRITTEN_TAGS.include?(match[2]&.downcase)

          first, last = match.byteoffset(0)
          rewrite_tag(match, (range.begin + first)...(range.begin + last), node)
        end
      end

      def rewrite_tag(match, range, node)
        closing = match[1].present?
        name = match[2].downcase
        return rewrite_macro(match[0], range, node, closing) if name == "macro"
        return if @macro

        case name
        when "img" then edit(range, closing ? "" : html_image_link(match[0]))
        when "mention" then edit(range, "") if new_mention?(match[0], closing)
        end
      end

      # Like the preview, a macro disappears with everything inside it. An unclosed one ends where the HTML
      # parser would close it: with its paragraph, or with the document for a macro in an HTML block.
      def rewrite_macro(tag, range, node, closing)
        if closing
          @macro ? close_nested_macro(range) : edit(range, "")
        elsif tag.end_with?("/>")
          edit(range, "") unless @macro
        elsif @macro
          @macro[:depth] += 1
        else
          closes_at = node.type == :html_inline ? byte_range(node.parent).end : @text.bytesize
          @macro = { first: range.begin, depth: 1, closes_at: }
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
