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
  module Notifications
    class Settings < ::Pages::Page
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_reader :user

      def initialize(user)
        @user = user
        super()
      end

      def path
        edit_user_path(user, tab: :notifications)
      end

      def expect_represented
        user.notification_settings.each do |setting|
          expect_global_represented(setting)
          # expect_project_represented(setting)
        end
      end

      def expect_global_represented(setting)
        %i[
          assignee
          responsible
          work_package_commented
          work_package_created
          work_package_processed
          work_package_prioritized
          work_package_scheduled
        ].each do |type|
          expect(page).to have_css("input[type='checkbox'][data-test-selector='global-notification-type-#{type}']") { |checkbox|
            checkbox.checked? == setting[type]
          }
        end
      end

      def expect_project(project)
        expect(page).to have_test_selector("project-specific-settings-list", text: project.name)
      end

      def add_project(project)
        click_link "Add project-specific notifications"
        container = page.find('[data-test-selector="my-notifications-project-autocompleter"] ng-select')
        select_autocomplete container, query: project.name, results_selector: "body"
        wait_for_network_idle
      end

      def configure_global(notification_types)
        notification_types.each { |type, checked| set_option(type, checked) }
      end

      def set_option(type, checked)
        checkbox = page.find "input[type='checkbox'][data-test-selector='global-notification-type-#{type}']"
        checked ? checkbox.check : checkbox.uncheck
      end

      def enable_date_alert(type, checked)
        selector =
          "input[type='checkbox'][data-test-selector='global-notification-type-op-settings-#{type}-date-active']"
        checkbox = page.find selector
        checked ? checkbox.check : checkbox.uncheck
      end

      def set_reminder(label, time)
        selector =
          "select[data-test-selector='global-notification-type-op-reminder-settings-#{label.underscore}-alerts']"
        select_box = page.find selector
        select_box.select time
      end

      def expect_no_date_alert_setting(label)
        expect(page).to have_no_css(
          "select[data-test-selector='global-notification-type-op-reminder-settings-#{label.underscore}-alerts']"
        )
      end

      def edit_project(project)
        within_test_selector "project-specific-settings-list", text: project.name do
          within_test_selector("project-specific-settings-list--action-menu") do
            click_on
          end
        end
        click_on "Edit"
      end

      def delete_project(project)
        within_test_selector "project-specific-settings-list", text: project.name do
          within_test_selector("project-specific-settings-list--action-menu") do
            click_on
          end
        end
        accept_confirm { click_on "Delete" }
      end

      def save_project
        within_test_selector "project-specific-settings-form" do
          click_button "Save"
        end
        expect_and_dismiss_flash
      end

      def configure_project(project: nil, **types)
        return unless project || types.any?

        add_project project
        within_test_selector "project-specific-settings-form" do
          types.each { |type| set_option(*type) }
        end
      end

      def set_project_reminder(label, time)
        within_test_selector "project-specific-settings-form" do
          enable_date_alert label, true

          select_box =
            page.find_test_selector "global-notification-type-op-reminder-settings-#{label.underscore}-alerts"
          select_box.select time
        end
      end

      def disable_project_date_alert(label)
        within_test_selector "project-specific-settings-form" do
          enable_date_alert label, false
        end
      end

      def expect_no_project_date_alert_setting(label)
        within_test_selector "project-specific-settings-form" do
          expect(page).to have_no_css(
            "select[data-test-selector='op-reminder-settings-#{label.underscore}-alerts']"
          )
        end
      end

      def save_participating
        within_test_selector "participating-form" do
          click_button "Update preferences"
        end

        expect_and_dismiss_flash
      end

      def save_non_participating
        within_test_selector "non-participating-form" do
          click_button "Update preferences"
        end

        expect_and_dismiss_flash
      end

      def save_date_alerts
        within_test_selector "date-alerts-form" do
          click_button "Update date alerts"
        end

        expect_and_dismiss_flash
      end
    end
  end
end
