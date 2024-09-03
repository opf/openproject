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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Members::DeleteByPrincipalService
  attr_reader :user, :project, :principal

  def initialize(user:, project:, principal:)
    @user = user
    @project = project
    @principal = principal
  end

  def call(params)
    result = ServiceResult.success

    if params[:project].present?
      result.merge! delete_project_member
    end

    role_id = params[:work_package_shares_role_id]
    if role_id == "all"
      work_package_shares_scope.each do |share|
        result.merge! delete_work_package_share(share)
      end
    elsif role_id.present?
      work_package_shares_with_role_id_scope(role_id).each do |share|
        result.merge! delete_work_package_share_with_role_id(share, role_id)
      end
    end

    result
  end

  private

  def delete_project_member
    project_member = Member.of_project(project).find_by!(principal:)

    Members::DeleteService.new(user:, model: project_member).call
  end

  def delete_work_package_share(model)
    Shares::DeleteService.new(user:, model:, contract_class: Shares::WorkPackages::DeleteContract).call
  end

  def delete_work_package_share_with_role_id(model, role_id)
    Shares::DeleteRoleService.new(user:, model:, contract_class: Shares::WorkPackages::DeleteContract).call(role_id:)
  end

  def work_package_shares_scope
    Member
      .of_anything_in_project(project)
      .of_any_work_package
      .where(principal:)
      .without_inherited_roles
  end

  def work_package_shares_with_role_id_scope(role_id)
    work_package_shares_scope
      .where(member_roles: { role_id: })
  end
end
