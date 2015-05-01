#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class SettingsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def index
    edit
    render action: 'edit'
  end

  def edit
    @notifiables = Redmine::Notifiable.all
    if request.post? && params[:settings] && params[:settings].is_a?(Hash)
      settings = (params[:settings] || {}).dup.symbolize_keys.tap do |set|
        set.except! *password_settings if OpenProject::Configuration.disable_password_login?
      end

      settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if(&:blank?) if value.is_a?(Array)
        Setting[name] = value
      end

      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'edit', tab: params[:tab]
    else
      @options = {}
      @options[:user_format] = User::USER_FORMATS.keys.map { |f| [User.current.name(f), f.to_s] }
      @deliveries = ActionMailer::Base.perform_deliveries

      @guessed_host = request.host_with_port.dup
    end
  end

  def plugin
    @plugin = Redmine::Plugin.find(params[:id])
    if request.post?
      Setting["plugin_#{@plugin.id}"] = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'plugin', id: @plugin.id
    else
      @partial = @plugin.settings[:partial]
      @settings = Setting["plugin_#{@plugin.id}"]
    end
  rescue Redmine::PluginNotFound
    render_404
  end

  def default_breadcrumb
    l(:label_settings)
  end

  private

  ##
  # Returns all password-login related setting keys.
  def password_settings
    [
      :password_min_length, :password_active_rules, :password_min_adhered_rules,
      :password_days_valid, :password_count_former_banned, :lost_password
    ]
  end
end
