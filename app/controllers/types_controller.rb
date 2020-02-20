#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class TypesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_action :require_admin
  helper_method :gon

  def index
    @types = ::Type.page(page_param).per_page(per_page_param)
  end

  def type
    @type
  end

  def new
    @type = Type.new(params[:type])
    load_projects_and_types
  end

  def create
    CreateTypeService
      .new(current_user)
      .call(permitted_type_params, copy_workflow_from: params[:copy_workflow_from]) do |call|

      @type = call.result

      call.on_success do
        redirect_to_type_tab_path(@type, t(:notice_successful_create))
      end

      call.on_failure do |result|
        flash[:error] = result.errors.full_messages.join("\n")
        load_projects_and_types
        render action: 'new'
      end
    end
  end

  def edit
    if params[:tab].blank?
      redirect_to tab: :settings
    else
      type = ::Type
             .includes(:projects,
                       :custom_fields)
             .find(params[:id])

      render_edit_tab(type)
    end
  end

  def update
    @type = ::Type.find(params[:id])

    UpdateTypeService
      .new(@type, current_user)
      .call(permitted_type_params) do |call|

      call.on_success do
        redirect_to_type_tab_path(@type, t(:notice_successful_update))
      end

      call.on_failure do |result|
        flash[:error] = result.errors.full_messages.join("\n")
        render_edit_tab(@type)
      end
    end
  end

  def move
    @type = ::Type.find(params[:id])

    if @type.update(permitted_params.type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = t('type_could_not_be_saved')
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
      flash[:error] = if @type.is_standard?
                        t(:error_can_not_delete_standard_type)
                      else
                        t(:error_can_not_delete_type)
                      end
    end
    redirect_to action: 'index'
  end

  protected

  def permitted_type_params
    # having to call #to_unsafe_h as a query hash the attribute_groups
    # parameters would otherwise still be an ActiveSupport::Parameter
    permitted_params.type.to_unsafe_h
  end

  def load_projects_and_types
    @types = ::Type.order(Arel.sql('position'))
    @projects = Project.all
  end

  def redirect_to_type_tab_path(type, notice)
    tab = params["tab"] || "settings"
    redirect_to(edit_type_tab_path(type, tab: tab),
                notice: notice)
  end

  def default_breadcrumb
    if action_name == 'index'
      t(:label_work_package_types)
    else
      ActionController::Base.helpers.link_to(t(:label_work_package_types), types_path)
    end
  end

  def render_edit_tab(type)
    @tab = params[:tab]
    @projects = Project.all
    @type = type

    render action: 'edit'
  end

  def show_local_breadcrumb
    true
  end
end
