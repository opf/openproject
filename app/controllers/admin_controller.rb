#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AdminController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  include SortHelper

  menu_item :projects, :only => [:projects]
  menu_item :plugins, :only => [:plugins]
  menu_item :info, :only => [:info]

  def index
    redirect_to :action => 'projects'
  end

  def projects
    @no_configuration_data = Redmine::DefaultData::Loader::no_data?

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
    @plugins = Redmine::Plugin.all.sort
  end

  # Loads the default configuration
  # (roles, types, statuses, workflow, enumerations)
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
      @test = UserMailer.test_mail(User.current).deliver
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => '/settings', :action => 'edit', :tab => 'notifications'
  end

  def force_user_language
    available_languages = Setting.find_by_name("available_languages").value
    User.find(:all, :conditions => ["language not in (?)", available_languages]).each do |u|
      u.language = Setting.default_language
      u.save
    end

    redirect_to :back
  end

  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_file_repository_writable, File.writable?(Attachment.storage_path)],
      [:text_rmagick_available, Object.const_defined?(:Magick)]
    ]
  end

  def default_breadcrumb
    case params[:action]
    when 'projects'
      l(:label_project_plural)
    when 'plugins'
      l(:label_plugins)
    when 'info'
      l(:label_information)
    end
  end
end
