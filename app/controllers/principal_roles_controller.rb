#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

    respond_to_create @principal_roles, @user, @global_roles unless performed?
  end

  def update
    @principal_role = PrincipalRole.find(principle_role_params[:id])

    call_hook :principal_roles_controller_update_before_save,
              principal_role: @principal_role

    @principal_role.update_attributes(principle_role_params) unless performed?

    call_hook :principal_roles_controller_update_before_respond,
              principal_role: @principal_role

    respond_to_update @principal_role unless performed?
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

    respond_to_destroy @principal_role, @user, @global_roles unless performed?
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

  def respond_to_create(principal_roles, user, global_roles)
    respond_to do |format|
      format.js do
        render(:update) do |page|
          if principal_roles.all?(&:valid?)
            principal_roles.each do |role|
              page.insert_html :top, 'table_principal_roles_body',
                               partial: 'principal_roles/show_table_row',
                               locals: { principal_role: role }

              call_hook :principal_roles_controller_create_respond_js_role,
                        page: page, principal_role: role
            end

            page.replace 'available_principal_roles',
                         partial: 'users/available_global_roles',
                         locals: { global_roles: global_roles,
                                   user: user }
          else
            page.insert_html :top, 'tab-content-global_roles', partial: 'errors'
          end
        end
      end
    end
  end

  def respond_to_update(role)
    respond_to do |format|
      format.js do
        render(:update) do |page|
          if role.valid?
            page.replace "principal_role-#{role.id}",
                         partial: 'principal_roles/show_table_row',
                         locals: { principal_role: role }
          else
            page.insert_html :top, 'tab-content-global_roles', partial: 'errors'
          end

          call_hook :principal_roles_controller_update_respond_js_role,
                    page: page, principal_role: role
        end
      end
    end
  end

  def respond_to_destroy(principal_role, user, global_roles)
    respond_to do |format|
      format.js do
        render(:update) do |page|
          page.remove "principal_role-#{principal_role.id}"
          page.replace 'available_principal_roles',
                       partial: 'users/available_global_roles',
                       locals: { user: user, global_roles: global_roles }

          call_hook :principal_roles_controller_update_respond_js_role,
                    page: page, principal_role: principal_role
        end
      end
    end
  end

  private

  def principle_role_params
    params.require(:principal_role).permit(:principal_id, :role_id, role_ids: [])
  end
end
