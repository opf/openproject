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
    class ElementFilter < HTMLPipeline::NodeFilter
      # Selma exposes attribute values as raw source text and escapes only `"`
      # on write. Decode and re-escape so filters see the same values as on
      # a Nokogiri node.
      class DecodedElement
        ESCAPES = { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;" }.freeze

        delegate :tag_name, to: :@element

        def initialize(element)
          @element = element
        end

        def [](name)
          value = @element[name]
          value && CGI.unescapeHTML(value)
        end

        def []=(name, value)
          @element[name] = value.to_s.gsub(/[&<>"]/, ESCAPES)
        end
      end

      class << self
        attr_reader :element_selector

        def match_elements(css)
          @element_selector = Selma::Selector.new(match_element: css)
        end
      end

      def selector
        self.class.element_selector
      end

      def handle_element(element)
        process(DecodedElement.new(element)) if applicable?
      end

      def applicable?
        true
      end
    end
  end
end
