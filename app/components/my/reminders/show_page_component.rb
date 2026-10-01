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

module My
  module Reminders
    class ShowPageComponent < ApplicationComponent
      include OpPrimer::FormHelpers

      attr_reader :global_notification_setting, :update_url, :update_workdays_url, :update_email_alerts_url

      def initialize(user:, global_notification_setting:, update_url:, update_workdays_url:, update_email_alerts_url:)
        super

        @user = user
        @global_notification_setting = global_notification_setting
        @update_url = update_url
        @update_workdays_url = update_workdays_url
        @update_email_alerts_url = update_email_alerts_url
      end

      def daily_reminders_form_model
        daily_reminders = @user.pref.daily_reminders
        My::Reminders::DailyRemindersForm::DailyRemindersFormModel.new(
          enabled: daily_reminders[:enabled],
          times: daily_reminders[:times]
        )
      end

      def pause_reminders_form_model
        pause_reminders = @user.pref.pause_reminders
        My::Reminders::PauseRemindersForm::PauseRemindersFormModel.new(
          enabled: pause_reminders[:enabled],
          first_day: pause_reminders[:first_day],
          last_day: pause_reminders[:last_day]
        )
      end
    end
  end
end
