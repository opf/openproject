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
          expect(page).to have_css("input[type='checkbox'][data-qa-global-notification-type='#{type}']") { |checkbox|
            checkbox.checked? == setting[type]
          }
        end
      end

      def expect_project(project)
        expect(page).to have_css("th", text: project.name)
      end

      def add_project(project)
        click_button "Add setting for project"
        container = page.find('[data-test-selector="notification-setting-inline-create"] ng-select')
        select_autocomplete container, query: project.name, results_selector: "body"
        wait_for_network_idle
        expect_project project
      end

      def configure_global(notification_types)
        notification_types.each { |type, checked| set_global_option(type, checked) }
      end

      def set_global_option(type, checked)
        checkbox = page.find "input[type='checkbox'][data-qa-global-notification-type='#{type}']"
        checked ? checkbox.check : checkbox.uncheck
      end

      def enable_date_alert(type, checked)
        checkbox = page.find "input[type='checkbox'][data-qa-global-notification-type='op-settings-#{type}-date-active']"
        checked ? checkbox.check : checkbox.uncheck
      end

      def set_reminder(label, time)
        select_box = page.find "select[data-qa-global-notification-type='op-reminder-settings-#{label}-alerts']"
        select_box.select time
      end

      def expect_no_date_alert_setting(label)
        expect(page).to have_no_css(
          "select[data-qa-global-notification-type='op-reminder-settings-#{label}-alerts']"
        )
      end

      def configure_project(project: nil, **types)
        types.each { |type| set_project_option(*type, project) }
      end

      def set_project_option(type, checked, project)
        checkbox = page.find "input[type='checkbox'][data-qa-project='#{project}'][data-qa-project-notification-type='#{type}']"
        checked ? checkbox.check : checkbox.uncheck
      end

      def set_project_reminder(label, time, project)
        select_box =
          page.find "select[data-qa-project='#{project}']" \
                    "[data-qa-project-notification-type='op-reminder-settings-#{label}-alerts']"
        select_box.select time
      end

      def expect_no_project_date_alert_setting(label, project)
        expect(page).to have_no_css(
          "select[data-qa-project='#{project}'][data-qa-project-notification-type='op-reminder-settings-#{label}-alerts']"
        )
      end

      def save
        click_button "Save"
        expect_toast message: "Successful update."
      end
    end
  end
end
