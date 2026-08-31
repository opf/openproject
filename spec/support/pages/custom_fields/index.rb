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

require "support/pages/page"

module Pages
  module CustomFields
    class Index < Page
      def path
        "/custom_fields"
      end

      def visit_page(customizable_name)
        visit!
        within_test_selector("custom-fields--tab-nav") do
          click_on customizable_name.to_s
        end
      end

      def set_name(name)
        find_by_id("custom_field_name").set name
      end

      def set_default_value(value)
        fill_in "custom_field[default_value]", with: value
      end

      def set_all_projects(value)
        find_by_id("is_for_all").set value
      end

      def has_form_element?(name)
        page.has_css? "label.form--label", text: name
      end

      def click_to_create_new_custom_field(type)
        wait_for_network_idle

        click_button "New custom field"

        click_on type
      end

      def expect_having_create_item(type)
        wait_for_network_idle

        click_button "New custom field"

        expect(page).to have_link(type)
      end

      def expect_not_having_create_item(type)
        wait_for_network_idle

        click_button "New custom field"

        expect(page).to have_no_link(type)
      end

      def expect_none_listed
        expect(page).to have_text("There are currently no custom fields.")
      end
    end
  end
end
