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
    class BemCssFilter < ElementFilter
      BEM_CLASSES = {
        h1: "op-uc-h1",
        h2: "op-uc-h2",
        h3: "op-uc-h3",
        h4: "op-uc-h4",
        h5: "op-uc-h5",
        h6: "op-uc-h6",
        p: "op-uc-p",
        blockquote: "op-uc-blockquote",
        code: "op-uc-code",
        pre: "op-uc-code-block",
        li: "op-uc-list--item",
        ul: "op-uc-list",
        ol: "op-uc-list",
        a: "op-uc-link",
        figure: "op-uc-figure",
        img: "op-uc-image",
        figcaption: "op-uc-figure--description",
        table: "op-uc-table",
        thead: "op-uc-table--head",
        tr: "op-uc-table--row",
        td: "op-uc-table--cell",
        th: "op-uc-table--cell op-uc-table--cell_head"
      }.with_indifferent_access.freeze

      # Contains all elements with their classes which should not be modified
      # as they already have the correct BEM class.
      UNMODIFIED = {
        h1: "op-uc-toc--title",
        li: "op-uc-toc--list-item",
        ul: "op-uc-toc--list"
      }.with_indifferent_access.freeze

      match_elements BEM_CLASSES.keys.join(", ")

      private

      def process(element, tag_name)
        add_css_class(element, BEM_CLASSES.fetch(tag_name)) unless not_to_be_modified?(element, tag_name)
      end

      def not_to_be_modified?(element, tag_name)
        element["class"].present? &&
          UNMODIFIED[tag_name] &&
          element["class"].include?(UNMODIFIED[tag_name])
      end

      def add_css_class(element, css_class)
        if element["class"].present?
          # Avoid using element['class'].include?(css_class) as css_class can be a substring
          # of an existing class
          element["class"] += " #{css_class}" unless element["class"].split.any?(css_class)
        else
          element["class"] = css_class
        end
      end
    end
  end
end
