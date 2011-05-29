#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

class SettingsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  def index
    edit
    render :action => 'edit'
  end

  def edit
    @notifiables = Redmine::Notifiable.all
    if request.post? && params[:settings] && params[:settings].is_a?(Hash)
      settings = (params[:settings] || {}).dup.symbolize_keys
      settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if {|v| v.blank? } if value.is_a?(Array)
        Setting[name] = value
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'edit', :tab => params[:tab]
    else
      @options = {}
      @options[:user_format] = User::USER_FORMATS.keys.collect {|f| [User.current.name(f), f.to_s] }
      @deliveries = ActionMailer::Base.perform_deliveries

      @guessed_host_and_path = request.host_with_port.dup
      @guessed_host_and_path << ('/'+ Redmine::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Redmine::Utils.relative_url_root.blank?
    
      Redmine::Themes.rescan
    end
  end

  def plugin
    @plugin = Redmine::Plugin.find(params[:id])
    if request.post?
      Setting["plugin_#{@plugin.id}"] = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'plugin', :id => @plugin.id
    else
      @partial = @plugin.settings[:partial]
      @settings = Setting["plugin_#{@plugin.id}"]
    end
  rescue Redmine::PluginNotFound
    render_404
  end
end
