#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class RolesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_action :require_admin

  menu_item :roles, except: :report
  menu_item :permissions_report, only: :report

  def index
    @roles = roles_scope
             .page(page_param)
             .per_page(per_page_param)

    render action: 'index', layout: false if request.xhr?
  end

  def new
    @role = ProjectRole.new(permitted_params.role? || { permissions: ProjectRole.non_member.permissions })

    @roles = roles_scope
  end

  def edit
    @role = Role.find(params[:id])
    @call = set_role_attributes(@role, 'update')
  end

  def create
    @call = Roles::CreateService.new(user: current_user).call(create_params)
    @role = @call.result

    if @call.success?
      flash[:notice] = t(:notice_successful_create)
      redirect_to action: 'index'
    else
      @roles = roles_scope

      render action: 'new'
    end
  end

  def update
    @role = Role.find(params[:id])
    @call = update_role(@role, permitted_params.role)

    if @call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: 'index'
    else
      render action: 'edit'
    end
  end

  def destroy
    service_result = Roles::DeleteService.new(
      model: Role.find(params[:id]),
      user: current_user
    ).call

    if service_result.success?
      flash[:notice] = I18n.t(:notice_successful_delete)
    else
      flash[:error] = I18n.t(:error_can_not_remove_role)
    end
    redirect_to action: 'index'
  end

  def report
    @roles = roles_scope
    @permissions = OpenProject::AccessControl.permissions.reject(&:public?)
  end

  def bulk_update
    @roles = roles_scope

    calls = bulk_update_roles(@roles)

    if calls.all?(&:success?)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: 'index'
    else
      @calls = calls
      @permissions = OpenProject::AccessControl.permissions.reject(&:public?)
      render action: 'report'
    end
  end

  private

  def set_role_attributes(role, create_or_update)
    contract = "Roles::#{create_or_update.camelize}Contract".constantize

    Roles::SetAttributesService
      .new(user: current_user, model: role, contract_class: contract)
      .call(new_params)
  end

  def update_role(role, params)
    Roles::UpdateService
      .new(user: current_user, model: role)
      .call(params)
  end

  def bulk_update_roles(roles)
    roles.map do |role|
      new_permissions = { permissions: params[:permissions][role.id.to_s].presence || [] }

      update_role(role, new_permissions)
    end
  end

  def roles_scope
    Role.visible.ordered_by_builtin_and_position
  end

  def default_breadcrumb
    if action_name == 'index'
      t('label_role_plural')
    else
      ActionController::Base.helpers.link_to(t('label_role_plural'), roles_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  def new_params
    permitted_params.role? || {}
  end

  def create_params
    new_params
      .merge(copy_workflow_from: params[:copy_workflow_from],
             global_role: params[:global_role])
  end
end
