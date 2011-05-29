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

class AdminController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  include SortHelper	

  def index
    @no_configuration_data = Redmine::DefaultData::Loader::no_data?
  end
	
  def projects
    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])
    
    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(identifier) LIKE ? OR LOWER(name) LIKE ?", name, name]
    end
    
    @projects = Project.find :all, :order => 'lft',
                                   :conditions => c.conditions

    render :action => "projects", :layout => false if request.xhr?
  end
  
  def plugins
    @plugins = Redmine::Plugin.all
  end
  
  # Loads the default configuration
  # (roles, trackers, statuses, workflow, enumerations)
  def default_configuration
    if request.post?
      begin
        Redmine::DefaultData::Loader::load(params[:lang])
        flash[:notice] = l(:notice_default_data_loaded)
      rescue Exception => e
        flash[:error] = l(:error_can_t_load_default_data, e.message)
      end
    end
    redirect_to :action => 'index'
  end
  
  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = Mailer.deliver_test(User.current)
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => 'settings', :action => 'edit', :tab => 'notifications'
  end
  
  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    @checklist = [
      [:text_default_administrator_account_changed, User.find(:first, :conditions => ["login=? and hashed_password=?", 'admin', User.hash_password('admin')]).nil?],
      [:text_file_repository_writable, File.writable?(Attachment.storage_path)],
      [:text_plugin_assets_writable, File.writable?(Engines.public_directory)],
      [:text_rmagick_available, Object.const_defined?(:Magick)]
    ]
  end  
end
