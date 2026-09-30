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

require_relative "form_field"

module FormFields
  module Primerized
    class EditorFormField < FormField
      attr_reader :editor

      delegate :expect_value, to: :editor

      def initialize(property, selector: nil)
        super

        @editor = ::Components::WysiwygEditor.new(selector)
      end

      def field_container
        augmented_textarea = page.find(selector || "[data-text-area-id='\"project_custom_field_values_#{property.id}\"']")
        augmented_textarea.first(:xpath, ".//..")
      end

      ##
      # Set or select the given value.
      # For fields of type select, will check for an option with that value.
      def set_value(content)
        editor.set_markdown(content)
      end

      def input_element
        editor.editor_element
      end

      # expectations

      def expect_visible
        !!editor.container
      end

      def expect_error(string = nil)
        sleep 2 # quick fix for stale element error
        expect(field_container).to have_css(".FormControl-inlineValidation")
        expect(field_container).to have_content(string) if string
      end
    end
  end
end
