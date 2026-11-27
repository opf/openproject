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

module OpenProject::TextFormatting
  module Filters
    # Base for formatter stages that need the whole document as a Nokogiri
    # tree, as opposed to the final Selma pass over the generated HTML.
    #
    # Selma streams HTML once and only lets a handler change the current
    # element. That cannot express stages which:
    #
    # - change an ancestor after seeing its descendants (task lists classify
    #   the parent list, figure wrapping reuses the image's container),
    # - depend on later content (a TOC placeholder precedes its headings;
    #   mentions and pattern matchers preload records for the whole document),
    # - read an element's full contents (syntax highlighting), or
    # - sanitize with OpenProject's custom transformers.
    #
    # Each stage receives the previous stage's output, either a String or a
    # Nokogiri node, and parses Strings as an HTML4 fragment as html-pipeline
    # 2 did.
    class DomFilter
      attr_reader :context, :result

      def self.call(input, context = nil, result = nil)
        new(input, context, result).call
      end

      def self.parse(input)
        return input if input.is_a?(Nokogiri::XML::Node)

        Nokogiri::HTML4::DocumentFragment.parse(input.to_s)
      end

      def initialize(input, context = nil, result = nil)
        @input = input
        @context = context || {}
        @result = result || {}
      end

      def doc
        @doc ||= DomFilter.parse(@input)
      end

      def html
        @input.is_a?(String) ? @input : doc.to_html
      end

      def has_ancestor?(node, tags)
        while (node = node.parent)
          return true if tags.include?(node.name.downcase)
        end

        false
      end
    end
  end
end
