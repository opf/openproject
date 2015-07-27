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

class AdminController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  include SortHelper

  menu_item :projects, only: [:projects]
  menu_item :plugins, only: [:plugins]
  menu_item :info, only: [:info]

  def index
    redirect_to action: 'projects'
  end

  def projects
    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? 'status <> 0' : ['status = ?', @status])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ['LOWER(identifier) LIKE ? OR LOWER(name) LIKE ?', name, name]
    end

    @projects = Project.find :all, order: 'lft',
                                   conditions: c.conditions

    render action: 'projects', layout: false if request.xhr?
  end

  def plugins
    @plugins = Redmine::Plugin.all.sort
  end

  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = UserMailer.test_mail(User.current).deliver
      flash[:notice] = l(:notice_email_sent, ERB::Util.h(User.current.mail))
    rescue => e
      flash[:error] = l(:notice_email_error, ERB::Util.h(Redmine::CodesetUtil.replace_invalid_utf8(e.message.dup)))
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to controller: '/settings', action: 'edit', tab: 'notifications'
  end

  def force_user_language
    available_languages = Setting.find_by_name('available_languages').value
    User.find(:all, conditions: ['language not in (?)', available_languages]).each do |u|
      u.language = Setting.default_language
      u.save
    end

    redirect_to :back
  end

  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    repository_writable = File.writable?(OpenProject::Configuration.attachments_storage_path)
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_file_repository_writable, repository_writable]
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
