#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class TypesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_action :require_admin

  def index
    @types = ::Type.page(params[:page]).per_page(per_page_param)
  end

  def type
    @type
  end

  def new
    @type = ::Type.new(params[:type])
    @types = ::Type.order('position')
    @projects = Project.all
  end

  def create
    service = CreateTypeService.new
    result = service.call(permitted_params: permitted_params.type)
    @type = service.type

    if result.success?
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = ::Type.find_by(id: params[:copy_workflow_from]))
        @type = service.type
        @type.workflows.copy_from_type(copy_from)
      end
      flash[:notice] = t(:notice_successful_create)
      redirect_to edit_type_tab_path(id: @type.id, tab: 'settings')
    else
      @types = ::Type.order('position')
      @projects = Project.all
      render action: 'new'
    end
  end

  def edit
    if params[:tab].blank?
      redirect_to tab: :settings
    else
      @tab = params[:tab]
      @projects = Project.all
      @type = ::Type.includes(:projects,
                              :custom_fields)
                    .find(params[:id])
    end
  end

  def update
    @tab = params["tab"] || "settings"
    @type = ::Type.find(params[:id])

    # forbid renaming if it is a standard type
    params[:type].delete :name if @type.is_standard?

    service = UpdateTypeService.new(type: @type)

    result = service.call(permitted_params: permitted_params.type, unsafe_params: params[:type])
    if result.success?
      redirect_to(edit_type_tab_path(id: @type.id, tab: @tab),
                  notice: t(:notice_successful_update))
    else
      @projects = Project.all
      render action: 'edit'
    end
  end

  def move
    @type = ::Type.find(params[:id])

    if @type.update_attributes(permitted_params.type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('type_could_not_be_saved')
      render action: 'edit'
    end
    redirect_to types_path
  end

  def destroy
    @type = ::Type.find(params[:id])
    # types cannot be deleted when they have work packages
    # or they are standard types
    # put that into the model and do a `if @type.destroy`
    if @type.work_packages.empty? && !@type.is_standard?
      @type.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      if @type.is_standard?
        flash[:error] = t(:error_can_not_delete_standard_type)
      else
        flash[:error] = t(:error_can_not_delete_type)
      end
    end
    redirect_to action: 'index'
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t(:label_type_plural)
    else
      ActionController::Base.helpers.link_to(t(:label_type_plural), types_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
