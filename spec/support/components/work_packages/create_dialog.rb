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

require "support/components/autocompleter/ng_select_autocomplete_helpers"

module Components
  module WorkPackages
    class CreateDialog
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include RSpec::Wait
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def initialize
        @description = ::Components::WysiwygEditor.new("#create-work-package-dialog")
      end

      def select_type(value)
        in_dialog do
          select_combo_box_option value, from: "Type"
        end

        wait_for_network_idle # form is updated
      end

      def set_subject(value)
        in_dialog do
          fill_in "Subject", with: value
        end
      end

      def expect_subject(value)
        in_dialog do
          expect(page).to have_field "Subject", with: value
        end
      end

      def expect_subject_field_focused
        in_dialog do
          subject_field = page.find_field("Subject")
          subject_field_id_selector = "##{subject_field[:id]}"
          expect(page).to have_focus_on(subject_field_id_selector)
        end
      end

      def set_description(value)
        @description.set_markdown(value)
      end

      def expect_description(value)
        @description.expect_value(value)
      end

      def expect_custom_field(custom_field, **args)
        expect(page).to have_field "work_package_custom_field_values_#{custom_field.id}", **args
      end

      def expect_no_custom_field(custom_field)
        expect(page).to have_no_field "work_package_custom_field_values_#{custom_field.id}"
      end

      def set_custom_field(custom_field, value)
        fill_in "work_package_custom_field_values_#{custom_field.id}", with: value
      end

      def in_dialog(&)
        page.within("#create-work-package-dialog", &)
      end

      def submit
        page.within("#create-work-package-dialog") do
          click_on "Create"
        end
      end
    end
  end
end
