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
  class InputFormField < FormField
    def expect_value(value)
      scroll_to_element(field_container)
      expect(field_container).to have_css("input") { |el| el.value == value }
    end

    def expect_visible
      expect(field_container).to have_css("input")
    end

    ##
    # Set or select the given value.
    # For fields of type select, will check for an option with that value.
    def set_value(content)
      scroll_to_and_click(input_element)

      # A normal fill_in would cause the focus loss on the input for empty strings.
      # Thus the form would be submitted.
      # https://github.com/erikras/redux-form/issues/686
      if using_cuprite?
        clear_input_field_contents(input_element)
        input_element.fill_in with: content
      else
        input_element.fill_in with: content, fill_options: { clear: :backspace }
      end
    end

    def send_keys(*)
      input_element.send_keys(*)
    end

    def input_element
      field_container.find "input"
    end
  end
end
