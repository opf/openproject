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

module GitlabIntegration
  module Admin
    class SettingsController < ApplicationController
      layout "admin"

      menu_item :admin_gitlab_integration

      before_action :require_admin

      def show
        settings = plugin_settings
        user_id = settings[:gitlab_user_id].presence
        @gitlab_comment_user = user_id ? User.find_by(id: user_id) : nil
        @webhook_secret = settings[:webhook_secret]
      end

      def update
        merged = plugin_settings.merge(permitted_params)
        Setting.plugin_openproject_gitlab_integration = merged
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to gitlab_integration_admin_settings_path
      end

      private

      def permitted_params
        params.permit(:gitlab_user_id, :webhook_secret).to_h
      end

      def plugin_settings
        Hash(Setting.plugin_openproject_gitlab_integration).with_indifferent_access
      end
    end
  end
end
