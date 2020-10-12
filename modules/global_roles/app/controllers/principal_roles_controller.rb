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

class PrincipalRolesController < ApplicationController
  def create
    @principal_roles = new_principal_roles_from_params
    @global_roles = GlobalRole.all
    @user = Principal.find(principle_role_params[:principal_id])

    call_hook :principal_roles_controller_create_before_save,
              principal_roles: @principal_roles

    @principal_roles.each(&:save) unless performed?

    call_hook :principal_roles_controller_create_before_respond,
              principal_roles: @principal_roles

    redirect_to_edit_user(@user) unless performed?
  end

  def destroy
    @principal_role = PrincipalRole.find(params[:id])
    @user = Principal.find(@principal_role.principal_id)
    @global_roles = GlobalRole.all

    call_hook :principal_roles_controller_destroy_before_destroy,
              principal_role: @principal_role

    @principal_role.destroy unless performed?

    call_hook :principal_roles_controller_destroy_before_respond,
              principal_role: @principal_role

    redirect_to_edit_user(@user) unless performed?
  end

  private

  def new_principal_roles_from_params
    pr_params = principle_role_params.dup
    role_ids = pr_params[:role_id] ? [pr_params.delete(:role_id)] : pr_params.delete(:role_ids)
    principal_id = pr_params.delete(:principal_id)

    roles = Role.find role_ids

    principal_roles = []
    role_ids.map(&:to_i).each do |role_id|
      role = PrincipalRole.new(pr_params)
      role.principal_id = principal_id
      role.role = roles.detect { |r| r.id == role_id }
      principal_roles << role
    end
    principal_roles
  end

  private

  def redirect_to_edit_user(user)
    redirect_to tab_edit_user_path user, tab: 'global_roles'
  end

  def principle_role_params
    params.require(:principal_role).permit(*PermittedParams.permitted_attributes[:global_roles_principal_role])
  end
end
