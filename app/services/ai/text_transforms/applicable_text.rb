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
    # Brings the model output that Replace inserts in line with the pane's untrusted preview, so the
    # editor never receives macros, images or group mentions (which notify every member on save).
    # Code spans and blocks stay untouched because only image and raw HTML nodes are rewritten.
    class ApplicableText
      PARSE_OPTIONS = {
        parse: { smart: false },
        extension: { table: true, strikethrough: true, tagfilter: false, autolink: false, tasklist: false, shortcodes: false }
      }.freeze
      TAG = %r{<(/?)(macro|img|mention)\b(?:[^>"']|"[^"]*"|'[^']*')*>}i

      def self.call(text) = new(text).call

      def initialize(text)
        @text = text
        @group_mentions = []
      end

      def call
        edits.reverse.reduce(@text.b) { |result, (range, replacement)| result.bytesplice(range, replacement.b) }
             .force_encoding(@text.encoding)
      end

      private

      def edits
        covered_until = 0
        Commonmarker.parse(@text, options: PARSE_OPTIONS).to_enum(:walk).filter_map do |node|
          range = byte_range(node)
          next if range.begin < covered_until

          edit = edit_for(node, range)
          covered_until = range.end if edit
          edit
        end
      end

      def edit_for(node, range)
        case node.type
        when :image
          [range, markdown_image_link(node)]
        when :html_inline, :html_block
          source = @text.byteslice(range)
          rewritten = source.gsub(TAG) { rewrite_tag(Regexp.last_match) }
          [range, rewritten] if rewritten != source
        end
      end

      def rewrite_tag(match)
        closing = match[1].present?
        case match[2].downcase
        when "macro" then ""
        when "img" then closing ? "" : html_image_link(match[0])
        when "mention" then rewrite_mention(match[0], closing)
        end
      end

      def rewrite_mention(tag, closing)
        group = closing ? @group_mentions.pop : @group_mentions.push(attributes(tag)["data-type"] == "group").last
        group ? "" : tag
      end

      def markdown_image_link(node)
        alt = node.to_enum(:walk).select { %i[text code].include?(it.type) }.map(&:string_content).join
        source = node.url.presence
        text = image_link_text(alt, source).delete("[]")
        return text unless source

        "[#{text}](#{source.match?(/[\s()<>]/) ? "<#{source}>" : source})"
      end

      def html_image_link(tag)
        image = attributes(tag)
        source = image["src"].presence
        text = ERB::Util.html_escape(image_link_text(image["alt"], source))
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

      def line_offsets
        @line_offsets ||= @text.each_line.reduce([0]) { |offsets, line| offsets << (offsets.last + line.bytesize) }
      end
    end
  end
end
