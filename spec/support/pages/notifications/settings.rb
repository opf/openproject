#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  module Notifications
    class Settings < ::Pages::Page
      include ::Components::NgSelectAutocompleteHelpers

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def path
        edit_user_path(user, tab: :notifications)
      end

      def expect_represented
        user.notification_settings.each do |setting|
          within_channel(setting.channel, project: setting.project&.name) do
            expect_setting setting.attributes.symbolize_keys
          end
        end
      end

      def expect_setting(setting)
        channel_name = I18n.t("js.notifications.channels.#{setting[:channel]}")
        expect(page).to have_selector('td', text: channel_name)

        %i[involved mentioned watched all].each do |type|
          expect(page).to have_selector("input[type='checkbox'][data-qa-notification-type='#{type}']") do |checkbox|
            if setting[:all] && type != :all
              checkbox.disabled?
            else
              checkbox.checked? == setting[type]
            end
          end
        end
      end

      def expect_project(project)
        expect(page).to have_selector('td', text: project.name)
      end

      def add_row(project)
        click_button 'Add setting for project'
        container = page.find('[data-qa-selector="notification-setting-inline-create"] ng-select')
        select_autocomplete container, query: project.name, results_selector: 'body'
        expect_project project
      end

      def configure_channel(channel, project: nil, **types)
        within_channel(channel, project: project) do
          types.each(&method(:set_option))
        end
      end

      def set_option(type, checked)
        checkbox = page.find "input[type='checkbox'][data-qa-notification-type='#{type}']"
        checked ? checkbox.check : checkbox.uncheck
      end

      def save
        click_button 'Save'
        expect_notification message: 'Successful update.'
      end

      def within_channel(channel, project: nil, &block)
        raise(ArgumentError, "Invalid channel") unless NotificationSetting.channels.include?(channel.to_sym)

        project = 'global' if project.nil?
        page.within(
          "[data-qa-notification-project='#{project}'][data-qa-notification-channel='#{channel}']",
          &block
        )
      end
    end
  end
end