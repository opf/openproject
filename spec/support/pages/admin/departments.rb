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
require "support/components/autocompleter/ng_select_autocomplete_helpers"

module Pages
  module Admin
    class Departments < ::Pages::Page
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def path
        "/admin/departments"
      end

      def visit_department(department)
        visit "/admin/departments/#{department.id}"
      end

      # --- Assertions ---

      def expect_department_listed(name)
        within_detail_component do
          expect(page).to have_link(name)
        end
      end

      def expect_no_department_listed(name)
        within_detail_component do
          expect(page).to have_no_link(name)
        end
      end

      def expect_user_listed(user_name)
        within_detail_component do
          expect(page).to have_text(user_name)
        end
      end

      def expect_no_user_listed(user_name)
        within_detail_component do
          expect(page).to have_no_text(user_name)
        end
      end

      def expect_empty_state
        within_detail_component do
          expect(page).to have_text(I18n.t("departments.blankslate.heading"))
        end
      end

      def expect_department_empty_state
        within_detail_component do
          expect(page).to have_text(I18n.t("departments.detail_blankslate.heading"))
        end
      end

      def expect_breadcrumbs(*names)
        within_detail_component do
          expect(page).to have_css("li.breadcrumb-item", text: names.last)
          actual = page.all("li.breadcrumb-item").map(&:text)
          expect(actual).to eq(names)
        end
      end

      def expect_organization_name(name)
        within(organization_name_selector) do
          expect(page).to have_text(name)
        end
      end

      def expect_organization_name_form
        within(organization_name_selector) do
          expect(page).to have_field(I18n.t("setting_organization_name"), type: "text")
        end
      end

      def expect_no_organization_name_form
        within(organization_name_selector) do
          expect(page).to have_no_field(I18n.t("setting_organization_name"), type: "text")
        end
      end

      # --- Actions ---

      def click_add_button
        within("sub-header") do
          click_on I18n.t(:button_add)
        end
      end

      def click_add_user
        click_add_button
        click_on I18n.t("departments.add_user")
      end

      def click_add_department
        click_add_button
        click_on I18n.t("departments.add_department")
      end

      def add_user(user_name)
        wait_for_turbo_frame { click_add_user }

        autocompleter = page.find("opce-user-autocompleter")
        select_autocomplete autocompleter,
                            query: user_name,
                            select_text: user_name,
                            results_selector: "body"

        within_detail_component do
          wait_for_turbo { click_button(I18n.t(:button_add)) }
        end
      end

      def add_department(name)
        wait_for_turbo_frame { click_add_department }

        fill_in I18n.t("departments.add_department_form.name_placeholder"), with: name

        within_detail_component do
          wait_for_turbo { click_button(I18n.t(:button_add)) }
        end
      end

      def remove_user(user_name)
        row = find_user_row(user_name)
        menu = row.find("action-menu")
        menu.click_link_or_button

        accept_confirm do
          menu.click_on I18n.t(:button_remove)
        end
      end

      def select_user_in_autocompleter(user_name)
        autocompleter = page.find("opce-user-autocompleter")
        select_autocomplete autocompleter,
                            query: user_name,
                            select_text: user_name,
                            results_selector: "body"
      end

      def submit_add_form
        within_detail_component do
          click_button(I18n.t(:button_add))
        end
      end

      def cancel_add_user
        within_detail_component do
          wait_for_turbo { click_on I18n.t(:button_cancel) }
        end
      end

      def cancel_add_department
        within_detail_component do
          wait_for_turbo { click_on I18n.t(:button_cancel) }
        end
      end

      def click_edit_organization_name
        wait_for_turbo_stream do
          find_test_selector("edit-organization-name-button").click
        end
      end

      def edit_organization_name(new_name)
        click_edit_organization_name

        within(organization_name_selector) do
          fill_in I18n.t("setting_organization_name"), with: new_name
          wait_for_turbo_stream { click_button(I18n.t(:button_save)) }
        end
      end

      def cancel_edit_organization_name
        within(organization_name_selector) do
          wait_for_turbo_stream { click_on I18n.t(:button_cancel) }
        end
      end

      def tree_view
        @tree_view ||= ::Components::TreeView.new
      end

      private

      def organization_name_selector
        "##{::Admin::Departments::OrganizationNameComponent.wrapper_key}"
      end

      def detail_component_selector
        "##{::Admin::Departments::DetailComponent.wrapper_key}"
      end

      def within_detail_component(&)
        within(detail_component_selector, &)
      end

      def find_user_row(user_name)
        within_detail_component do
          page.find(".Box-row", text: user_name)
        end
      end
    end
  end
end
