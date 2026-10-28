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
    class InputField < FormField
      delegate :fill_in, to: :input_element

      # Capybara's native .click on a checkbox can update the DOM property directly
      # without dispatching a browser click event, so Stimulus event handlers won't fire.
      # Using execute_script with element.click() fires a real browser event.
      # We first wait for the element via Capybara's find (which retries until it appears)
      # to avoid null reference errors when the DOM is still being updated by Turbo.
      def check
        page.find(selector)
        page.execute_script("document.querySelector(\"#{selector}\").click()")
      end

      def uncheck
        page.find(selector)
        page.execute_script("document.querySelector(\"#{selector}\").click()")
      end

      def field_container
        page.find(selector).first(:xpath, ".//..").first(:xpath, ".//..")
      end

      def input_element
        field_container
      end

      def send_keys(*)
        input_element.send_keys(*)
      end

      def clear
        fill_in(with: "")
      end

      # expectations

      def expect_error(string = nil)
        expect(page).to have_css("#{selector}[invalid='true']")
        expect(field_container).to have_content(string) if string
      end

      def expect_value(value)
        scroll_to_element(field_container)
        expect(field_container).to have_css("input") { |el| el.value == value }
      end

      def expect_blank
        expect_value("")
      end
    end
  end
end
