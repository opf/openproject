# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

class Admin::Settings::GithubIntegrationSettingsController < ApplicationController
  layout "admin"
  menu_item :admin_github_integration

  before_action :require_admin

  def show; end

  def update
    Setting.plugin_openproject_github_integration = update_settings
    flash[:notice] = I18n.t(:notice_successful_update)

    redirect_to action: :show
  end

  def show_local_breadcrumb
    true
  end

  def default_breadcrumb
    I18n.t(:project_module_github)
  end

  private

  def update_settings
    @update_settings ||= params.permit(custom_field_mappings: {}).to_h
  end
end
