#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require 'nokogiri'

module OpenProject
  module Common
    class AttributeComponent < Primer::Component
      attr_reader :id,
                  :name,
                  :description

      PARAGRAPH_CSS_CLASS = 'op-uc-p'.freeze

      def initialize(id, name, description, **args)
        super
        @id = id
        @name = name
        @description = description
        @system_arguments = args
      end

      def short_text
        if multi_type?
          I18n.t(:label_preview_not_available)
        else
          first_paragraph
        end
      end

      def full_text
        @full_text ||= helpers.format_text(description)
      end

      def display_expand_button_value
        multi_type? || body_children.length > 1 ? :block : :none
      end

      def text_color
        :muted if multi_type?
      end

      private

      def first_paragraph
        @first_paragraph ||= if body_children.any?
                               body_children
                                 .first
                                 .inner_html
                                 .html_safe # rubocop:disable Rails/OutputSafety
                             else
                               ''
                             end
      end

      def text_ast
        @text_ast ||= Nokogiri::HTML(full_text)
      end

      def body_children
        text_ast
          .xpath('html/body')
          .children
      end

      def multi_type?
        first_paragraph.include?('figure') || first_paragraph.include?('macro')
      end
    end
  end
end
