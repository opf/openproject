# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LdapDepartments
  class SynchronizedDepartmentsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    guard_enterprise_feature(:ldap_groups, except: %i[deletion_dialog destroy]) do
      redirect_to ldap_departments_synchronized_trees_path, status: :see_other
    end

    before_action :find_department, only: %i[deletion_dialog destroy]

    layout "admin"
    menu_item :plugin_ldap_departments

    def deletion_dialog
      respond_with_dialog SynchronizedDepartments::DeleteDialogComponent.new(department: @department)
    end

    # Removing the mapping unmanages the department (it and externally-added members are kept).
    def destroy
      tree_id = @department.synchronized_tree_id

      if @department.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_can_not_delete_entry)
      end

      redirect_to ldap_departments_synchronized_tree_path(tree_id:), status: :see_other
    end

    private

    def find_department
      @department = SynchronizedDepartment.find(params.expect(:department_id))
    end
  end
end
