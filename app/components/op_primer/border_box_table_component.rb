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

module OpPrimer
  class BorderBoxTableComponent < TableComponent
    include ComponentHelpers

    class << self
      # Declares columns to be shown in the mobile table
      #
      # Use it in subclasses like so:
      #
      #     columns :name, :description
      #
      #     mobile_columns :name
      #
      # This results in the description columns to be hidden on mobile
      def mobile_columns(*names)
        return Array(@mobile_columns || columns) if names.empty?

        @mobile_columns = names.map(&:to_sym)
      end

      # Declares which columns to be rendered with a label
      #
      #     mobile_labels :name
      #
      # This results in the description columns to be hidden on mobile
      def mobile_labels(*names)
        return Array(@mobile_labels) if names.empty?

        @mobile_labels = names.map(&:to_sym)
      end

      # Declare main columns, that will result in a grid column span of 2 and not truncate text
      #
      #     column_grid_span :title
      #
      def main_column(*names)
        return Array(@main_columns) if names.empty?

        @main_columns = names.map(&:to_sym)
      end
    end

    delegate :mobile_columns, :mobile_labels,
             to: :class

    def main_column?(column)
      self.class.main_column.include?(column)
    end

    def pagination_params = {}

    def column_title(name)
      _, header_options = headers.assoc(name)
      header_options&.dig(:caption)
    end

    def header_classes(column)
      class_names(
        header_class,
        "op-border-box-grid__header--main-column": main_column?(column)
      )
    end

    def header_action_class
      "op-border-box-grid__header-action"
    end

    def header_class
      "op-border-box-grid__header"
    end

    # Default grid class with equal weights
    def grid_class
      "op-border-box-grid"
    end

    def has_actions?
      false
    end

    def has_header?
      true
    end

    def has_footer?
      false
    end

    def sortable?
      false
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false)) do |component|
        component.with_visual_icon(icon: blank_icon, size: :medium) if blank_icon
        component.with_heading(tag: :h2) { blank_title }
        component.with_description { blank_description }
      end
    end

    def mobile_title
      raise ArgumentError, "Need to provide a mobile table title"
    end

    def blank_title
      I18n.t(:label_nothing_display)
    end

    def blank_description
      I18n.t(:no_results_title_text)
    end

    def blank_icon
      nil
    end

    def action_row_header_content
      nil
    end

    def footer
      raise ArgumentError, "Need to provide footer content"
    end

    private

    def column_count
      @column_count ||= columns.size + (has_actions? ? 1 : 0)
    end
  end
end
