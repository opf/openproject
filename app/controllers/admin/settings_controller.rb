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

module Admin
  class SettingsController < ApplicationController
    layout "admin"
    before_action :require_admin
    before_action :find_plugin, only: %i[show_plugin update_plugin]

    current_menu_item [:show] do
      :settings
    end

    current_menu_item :show_plugin do |controller|
      plugin = Redmine::Plugin.find(controller.params[:id])
      plugin.settings[:menu_item] || :settings
    rescue Redmine::PluginNotFound
      :settings
    end

    def show
      respond_to :html
    end

    def update
      return unless params[:settings]

      call = update_service
        .new(user: current_user)
        .call(settings_params)

      call.on_success { success_callback(call) }
      call.on_failure { failure_callback(call) }
    end

    def show_plugin
      @partial = @plugin.settings[:partial]
      @settings = Setting["plugin_#{@plugin.id}"]
    end

    def update_plugin
      Setting["plugin_#{@plugin.id}"] = params[:settings].permit!.to_h
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: :show_plugin, id: @plugin.id
    end

    def show_local_breadcrumb
      false
    end

    def default_breadcrumb
      if @plugin
        @plugin.name
      else
        I18n.t(:label_setting_plural)
      end
    end

    protected

    def find_plugin
      @plugin = Redmine::Plugin.find(params[:id])
    rescue Redmine::PluginNotFound
      render_404
    end

    def settings_params
      permitted_params.settings(*extra_permitted_filters).to_h
    end

    # Override to allow additional permitted parameters.
    #
    # Useful when the format of the setting in the parameters is different from
    # the expected format in the setting definition, for instance a setting is
    # an array in the definition but is passed as a string to be split in the
    # parameters.
    def extra_permitted_filters
      nil
    end

    def update_service
      ::Settings::UpdateService
    end

    def success_callback(_call)
      flash[:notice] = t(:notice_successful_update)
      redirect_to action: "show", tab: params[:tab]
    end

    def failure_callback(call)
      flash[:error] = call.message || I18n.t(:notice_internal_server_error)
      redirect_to action: "show", tab: params[:tab]
    end
  end
end
