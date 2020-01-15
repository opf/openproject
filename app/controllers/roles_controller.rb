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

class RolesController < ApplicationController
  include PaginationHelper
  include Roles::NotifyMixin

  layout 'admin'

  before_action :require_admin, except: [:autocomplete_for_role]

  def index
    @roles = roles_scope
             .page(page_param)
             .per_page(per_page_param)

    render action: 'index', layout: false if request.xhr?
  end

  def new
    @role = Role.new(permitted_params.role? || { permissions: Role.non_member.permissions })

    @roles = roles_scope
  end

  def create
    @call = create_role
    @role = @call.result

    if @call.success?
      flash[:notice] = t(:notice_successful_create)
      redirect_to action: 'index'
    else
      @roles = roles_scope

      render action: 'new'
    end
  end

  def edit
    @role = Role.find(params[:id])
    @call = set_role_attributes(@role, 'update')
  end

  def update
    @role = Role.find(params[:id])
    @call = update_role(@role, permitted_params.role)

    if @call.success?
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'index'
    else
      render action: 'edit'
    end
  end

  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: 'index'
    notify_changed_roles(:removed, @role)
  rescue
    flash[:error] = l(:error_can_not_remove_role)
    redirect_to action: 'index'
  end

  def report
    @roles = Role.order(Arel.sql('builtin, position'))
    @permissions = OpenProject::AccessControl.permissions.reject(&:public?)
  end

  def bulk_update
    @roles = roles_scope

    calls = bulk_update_roles(@roles)

    if calls.all?(&:success?)
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'index'
    else
      @calls = calls
      @permissions = OpenProject::AccessControl.permissions.reject(&:public?)
      render action: 'report'
    end
  end

  def autocomplete_for_role
    size = params[:page_limit].to_i
    page = params[:page].to_i

    @roles = Role.paginated_search(params[:q], page: page, page_limit: size)
    # we always get all the items on a page, so just check if we just got the last
    @more = @roles.total_pages > page
    @total = @roles.total_entries

    respond_to do |format|
      format.json
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

  def create_role
    Roles::CreateService
      .new(user: current_user)
      .call(create_params)
  end

  def roles_scope
    Role.order(Arel.sql('builtin, position'))
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
