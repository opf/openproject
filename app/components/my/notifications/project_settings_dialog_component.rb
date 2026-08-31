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
  module Notifications
    class ProjectSettingsDialogComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::FormHelpers

      DIALOG_ID = "project-notification-settings-dialog"
      FORM_ID = "project-notification-settings-form"

      def initialize(user:, form_url:, notification_setting: nil)
        super
        @user = user
        @form_url = form_url
        @provided_setting = notification_setting
      end

      private

      def notification_setting
        @notification_setting ||= @provided_setting || @user.notification_settings.build
      end

      def edit_mode?
        notification_setting.persisted?
      end

      def date_alerts_available?
        EnterpriseToken.allows_to?(:date_alerts)
      end
    end
  end
end
