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

module OpenProject::TextFormatting
  module Filters
    class TableOfContentsFilter < HTML::Pipeline::TableOfContentsFilter
      include ActionView::Context
      include ActionView::Helpers::TagHelper

      attr_reader :headings, :ids

      def initialize(doc, context = nil, result = nil)
        super
        @headings ||= doc.css("h1, h2, h3, h4, h5, h6")
        @ids = Set.new
      end

      def add_header_link(node, id)
        link = content_tag(:a,
                           "",
                           class: "op-uc-link_permalink icon-link",
                           "aria-hidden": true,
                           href: "##{id}")
        node["id"] = id
        node.add_child(link)
      end

      ##
      # Build a unique id used for anchoring
      def get_unique_id(text)
        # Build id from text
        id = ascii_downcase(text)
        id.gsub!(PUNCTUATION_REGEXP, "") # remove punctuation
        id.tr!(" ", "-") # replace spaces with dash

        while ids.add?(id).nil?
          id += SecureRandom.hex(4)
        end

        id
      end

      ##
      # Appends the header link and returns
      # a toc item.
      # The item is prefixed by a number. If there is already a number prefix provided in the text,
      # that prefix is used if it matches the calculated number.
      def process_item(node, number)
        text = node.text
        return "".html_safe unless text.present?

        id = get_unique_id(text)
        add_header_link(node, id)

        content_tag(:li, class: "op-uc-toc--list-item") do
          anchor_tag(text, number, id)
        end
      end

      def get_heading_number(parent_number, num_in_level)
        parent_number == "" ? num_in_level.to_s : "#{parent_number}.#{num_in_level}"
      end

      def render_nested(level = 0, parent_number = "")
        result = "".html_safe
        num_in_level = 0

        while headings.length > 0
          node = headings.first
          node_level = node.name[1,].to_i

          if level == node_level
            # We will render this node
            node = headings.shift
            num_in_level = num_in_level + 1
            current_number = get_heading_number(parent_number, num_in_level)
            result << process_item(node, current_number)
          elsif level < node_level
            # Render a child list
            result << (content_tag(:ul, class: "op-uc-toc--list") do
              render_nested(node_level, num_in_level > 0 ? get_heading_number(parent_number, num_in_level) : "")
            end)
          elsif level > node_level
            # Break and return to the parent loop
            break
          end
        end

        result
      end

      def call
        process!
        doc
      end

      def process!
        result[:toc] = content_tag(:nav, class: "op-uc-toc") do
          if headings.empty?
            I18n.t(:label_wiki_toc_empty)
          else
            render_nested
          end
        end
      rescue StandardError => e
        Rails.logger.error { "Failed to render table of contents: #{e} #{e.message}" }
      end

      private

      def anchor_tag(text, number, id)
        parsed_text = text.match(Regexp.new("^(#{number}[.)]*)?(.+)$"))
        number = parsed_text[1] || number
        number_span = content_tag(:span, number, class: "op-uc-toc--list-item-number")
        content_span = content_tag(:span, parsed_text[2].strip, class: "op-uc-toc--list-item-title")
        content_tag(:a, number_span + content_span, href: "##{id}", class: "op-uc-toc--item-link")
      end
    end
  end
end
