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
require "nokogiri"

module OpenProject
  module Common
    class AttributeComponent < Primer::Component
      attr_reader :id,
                  :name,
                  :description,
                  :lines,
                  :format

      PARAGRAPH_CSS_CLASS = "op-uc-p"

      def initialize(id, name, description, lines: 1, format: true, **args)
        super()
        @id = id
        @name = name
        @description = description
        @system_arguments = args
        @lines = lines
        @format = format
      end

      # `lines` only constrains height in multi-line mode; a single line is best
      # served by single-line ellipsis truncation.
      def truncation_style
        lines > 1 ? :multi_line : :single_line
      end

      def short_text
        if multi_type?
          I18n.t(:label_preview_not_available)
        else
          first_paragraph
        end
      end

      def full_text
        @full_text ||= format ? helpers.format_text(description) : description
      end

      def show_expander?
        multi_type? || body_children.length > 1
      end

      def text_color
        :muted if multi_type?
      end

      private

      # rubocop:disable Rails/OutputSafety
      # OG: html_safe double-checked and expected here,
      # output is coming from format_text which we output elsewhere, too.
      def first_paragraph
        @first_paragraph ||= if body_children.any?
                               body_children
                                 .first
                                 .inner_html
                                 .html_safe
                             else
                               ""
                             end
      end
      # rubocop:enable Rails/OutputSafety

      def first_paragraph_ast
        @first_paragraph_ast ||= text_ast
                                 .xpath("html/body")
                                 .children
                                 .first
      end

      def text_ast
        @text_ast ||= Nokogiri::HTML(full_text)
      end

      def body_children
        text_ast
          .xpath("html/body")
          .children
      end

      def multi_type?
        @multi_type ||= (description.present? && first_paragraph_ast.nil?) ||
          %w[opce-macro-embedded-table figure macro].include?(first_paragraph_ast.name) ||
          first_paragraph_ast.css("figure, macro, .op-uc-toc--list, .opce-macro-embedded-table")&.any? ||
          (body_children.any? && first_paragraph.blank?)
      end
    end
  end
end
