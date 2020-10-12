#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting
  module Filters
    class TableOfContentsFilter < HTML::Pipeline::TableOfContentsFilter
      include ActionView::Context
      include ActionView::Helpers::TagHelper

      attr_reader :headings, :ids

      def initialize(doc, context = nil, result = nil)
        super(doc, context, result)
        @headings ||= doc.css('h1, h2, h3, h4, h5, h6')
        @ids = Set.new
      end

      def add_header_link(node, id)
        link = content_tag(:a,
                           '',
                           class: 'wiki-anchor icon-paragraph',
                           'aria-hidden': true,
                           href: "##{id}")
        node['id'] = id
        node.prepend_child(link)
      end

      ##
      # Build a unique id used for anchoring
      def get_unique_id(text)
        # Build id from text
        id = ascii_downcase(text)
        id.gsub!(PUNCTUATION_REGEXP, '') # remove punctuation
        id.tr!(' ', '-') # replace spaces with dash

        while ids.add?(id).nil?
          id += SecureRandom.hex(4)
        end

        id
      end

      ##
      # Appends the header link and returns
      # a toc item.
      def process_item(node)
        text = node.text
        return ''.html_safe unless text.present?

        id = get_unique_id(node.text)
        add_header_link(node, id)

        content_tag(:li) do
          content_tag(:a, node.text, href: "##{id}")
        end
      end

      def render_nested(current_level)
        result = ''.html_safe

        while headings.length > 0
          node = headings.first
          level = node.name[1,].to_i

          # Initialize first level
          current_level = level if current_level.nil?

          # Cancel our loop and let parent render this one
          break if level < current_level

          # We will render this node
          node = headings.shift

          if level == current_level
            result << process_item(node)
            result << render_nested(current_level)
          elsif level > current_level
            result << (content_tag(:ul, class: 'section-nav') do
              process_item(node) + render_nested(level)
            end)
          end
        end

        result
      end

      def call
        process!
        doc
      end

      def process!
        result[:toc] =
          if headings.empty?
            I18n.t(:label_wiki_toc_empty)
          else
            content_tag(:ul, render_nested(nil), class: 'toc')
          end

      rescue StandardError => e
        Rails.logger.error { "Failed to render table of contents: #{e} #{e.message}" }
      end
    end
  end
end
