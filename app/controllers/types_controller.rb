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

class TypesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_filter :require_admin

  def index
    @types = Type.page(params[:page]).per_page(per_page_param)
  end

  def type
    @type
  end

  def new
    @type = Type.new(params[:type])
    @types = Type.find(:all, order: 'position')
    @projects = Project.find(:all)
  end

  def create
    @type = Type.new(permitted_params.type)
    if @type.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Type.find_by_id(params[:copy_workflow_from]))
        @type.workflows.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'index'
    else
      @types = Type.find(:all, order: 'position')
      @projects = Project.find(:all)
      render action: 'new'
    end
  end

  def edit
    @projects = Project.all
    @type  = Type.find(params[:id])
  end

  def update
    @type = Type.find(params[:id])

    # forbid renaming if it is a standard type
    params[:type].delete :name if @type.is_standard?

    if @type.update_attributes(permitted_params.type)
      redirect_to types_path, notice: t(:notice_successful_update)
    else
      @projects = Project.all
      render action: 'edit'
    end
  end

  def move
    @type = Type.find(params[:id])

    if @type.update_attributes(permitted_params.type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('type_could_not_be_saved')
      render action: 'edit'
    end
    redirect_to types_path
  end

  def destroy
    @type = Type.find(params[:id])
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
end
