# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class SettingsController < ApplicationController
  layout 'base'	
  before_filter :require_admin
  
  def index
    edit
    render :action => 'edit'
  end

  def edit
    @notifiables = %w(issue_added issue_updated news_added document_added file_added message_posted)
    if request.post? && params[:settings] && params[:settings].is_a?(Hash)
      settings = (params[:settings] || {}).dup.symbolize_keys
      settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if {|v| v.blank? } if value.is_a?(Array)
        Setting[name] = value
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'edit', :tab => params[:tab]
      return
    end
    @options = {}
    @options[:user_format] = User::USER_FORMATS.keys.collect {|f| [User.current.name(f), f.to_s] }
    @deliveries = ActionMailer::Base.perform_deliveries
  end
  
  def plugin
    plugin_id = params[:id].to_sym
    @plugin = Redmine::Plugin.registered_plugins[plugin_id]
    if request.post?
      Setting["plugin_#{plugin_id}"] = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'plugin', :id => params[:id]
    end
    @partial = @plugin.settings[:partial]
    @settings = Setting["plugin_#{plugin_id}"]
  end
end
