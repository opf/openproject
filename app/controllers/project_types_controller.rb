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

class ProjectTypesController < ApplicationController
  unloadable
  helper :timelines

  before_filter :disable_api
  before_filter :check_permissions
  accept_key_auth :index, :show

  helper :timelines
  layout 'admin'

  def index
    @project_types = ProjectType.all
    respond_to do |format|
      format.html
    end
  end

  def new
    @project_type = ProjectType.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @project_type = ProjectType.new(permitted_params.project_type)

    if @project_type.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_types_path
    else
      render action: 'new'
    end
  end

  def show
    @project_type = ProjectType.find(params[:id])
    respond_to do |_format|
    end
  end

  def edit
    @project_type = ProjectType.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @project_type = ProjectType.find(params[:id])

    if @project_type.update_attributes(permitted_params.project_type)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_types_path
    else
      render action: :edit
    end
  end

  def confirm_destroy
    @project_type = ProjectType.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @project_type = ProjectType.find(params[:id])
    flash[:notice] = l(:notice_successful_delete) if @project_type.destroy
    redirect_to project_types_path
  end

  def move
    @project_type = ProjectType.find(params[:id])

    if @project_type.update_attributes(permitted_params.project_type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('timelines.project_type_could_not_be_saved')
      render action: 'edit'
    end
    redirect_to project_types_path
  end

  protected

  def default_breadcrumb
    l('timelines.admin_menu.project_types')
  end

  def check_permissions
    render_403 unless readonly_api_request or User.current.allowed_to_globally?(:edit_timelines)
  end

  def readonly_api_request
    api_request? and %w[index show].include? params[:action]
  end
end
