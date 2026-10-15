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

module Admin::Settings
  class PushNotificationsSettingsController < ::Admin::SettingsController
    guard_feature_flag :progressive_web_app

    current_menu_item [:show, :check] do
      :push_notifications
    end

    def show
      @reachability = flash[:_web_push_reachability]&.map do |result|
        OpenProject::WebPush::ReachabilityCheck::Result.new(**result.symbolize_keys)
      end
    end

    def check
      results = OpenProject::WebPush::ReachabilityCheck.call
      flash[:_web_push_reachability] = results.map(&:to_h)
      redirect_to admin_settings_push_notifications_path, status: :see_other
    end

    def regenerate_key
      if OpenProject::WebPush.key_managed_by_environment?
        flash[:error] = t("admin.settings.push_notifications.key_managed_by_environment")
      else
        OpenProject::WebPush.regenerate_key!
        flash[:notice] = t("admin.settings.push_notifications.key_regenerated")
      end

      redirect_to admin_settings_push_notifications_path, status: :see_other
    end
  end
end
