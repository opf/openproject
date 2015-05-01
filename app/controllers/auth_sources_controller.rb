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

class AuthSourcesController < ApplicationController
  include PaginationHelper
  layout 'admin'

  before_filter :require_admin
  before_filter :block_if_password_login_disabled

  def index
    @auth_sources = AuthSource.page(params[:page])
                    .per_page(per_page_param)

    render 'auth_sources/index'
  end

  def new
    @auth_source = auth_source_class.new
    render 'auth_sources/new'
  end

  def create
    @auth_source = auth_source_class.new permitted_params.auth_source
    if @auth_source.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'index'
    else
      render 'auth_sources/new'
    end
  end

  def edit
    @auth_source = AuthSource.find(params[:id])
    render 'auth_sources/edit'
  end

  def update
    @auth_source = AuthSource.find(params[:id])
    if @auth_source.update_attributes permitted_params.auth_source
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'index'
    else
      render 'auth_sources/edit'
    end
  end

  def test_connection
    @auth_method = AuthSource.find(params[:id])
    begin
      @auth_method.test_connection
      flash[:notice] = l(:notice_successful_connection)
    rescue => text
      flash[:error] = l(:error_unable_to_connect, text.message)
    end
    redirect_to action: 'index'
  end

  def destroy
    @auth_source = AuthSource.find(params[:id])
    unless @auth_source.users.find(:first)
      @auth_source.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to action: 'index'
  end

  protected

  def auth_source_class
    AuthSource
  end

  def default_breadcrumb
    l(:label_auth_source_plural)
  end

  def block_if_password_login_disabled
    render_404 if OpenProject::Configuration.disable_password_login?
  end
end
