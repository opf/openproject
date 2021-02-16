#-- encoding: UTF-8

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

module Admin
  class SettingsController < ApplicationController
    layout 'admin'
    before_action :require_admin

    helper_method :gon

    current_menu_item [:show] do
      :settings
    end

    current_menu_item :plugin do |controller|
      plugin = Redmine::Plugin.find(controller.params[:id])
      plugin.settings[:menu_item] || :settings
    rescue Redmine::PluginNotFound
      :settings
    end

    def show
      redirect_to general_admin_settings_path
    end

    def update
      if params[:settings]
        call = ::Settings::UpdateService
          .new(user: current_user)
          .call(settings_params)

        call.on_success { flash[:notice] = t(:notice_successful_update) }
        call.on_failure { flash[:error] = call.message || I18n.t(:notice_internal_server_error) }
        redirect_to action: 'show', tab: params[:tab]
      end
    end

    def plugin
      @plugin = Redmine::Plugin.find(params[:id])
      if request.post?
        Setting["plugin_#{@plugin.id}"] = params[:settings].permit!.to_h
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: 'plugin', id: @plugin.id
      else
        @partial = @plugin.settings[:partial]
        @settings = Setting["plugin_#{@plugin.id}"]
      end
    rescue Redmine::PluginNotFound
      render_404
    end

    def show_local_breadcrumb
      true
    end

    protected

    def settings_params
      permitted_params.settings.to_h
    end
  end
end