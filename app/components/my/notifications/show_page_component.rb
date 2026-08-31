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
    class ShowPageComponent < ApplicationComponent
      include OpPrimer::FormHelpers
      include OpPrimer::ComponentHelpers

      attr_reader :global_notification_setting,
                  :update_participating_url,
                  :update_non_participating_url,
                  :update_date_alerts_url,
                  :new_project_settings_url,
                  :project_notification_settings

      def initialize(user:,
                     global_notification_setting:,
                     update_participating_url:,
                     update_non_participating_url:,
                     update_date_alerts_url:,
                     new_project_settings_url:,
                     edit_project_settings_url:,
                     project_setting_url:)
        super

        @user = user
        @global_notification_setting = global_notification_setting
        @update_participating_url = update_participating_url
        @update_non_participating_url = update_non_participating_url
        @update_date_alerts_url = update_date_alerts_url
        @new_project_settings_url = new_project_settings_url
        @edit_project_settings_url_builder = edit_project_settings_url
        @project_setting_url_builder = project_setting_url
        @project_notification_settings = user.notification_settings.where.not(project: nil).includes(:project)
      end

      def edit_project_settings_url(project_id)
        @edit_project_settings_url_builder.call(project_id)
      end

      def project_setting_url(project_id)
        @project_setting_url_builder.call(project_id)
      end

      def date_alerts_available?
        EnterpriseToken.allows_to?(:date_alerts)
      end
    end
  end
end
