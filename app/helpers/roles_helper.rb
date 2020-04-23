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

module RolesHelper
  def setable_permissions(role)
    # Use the base contract for now as we are only interested in the setable permissions
    # which do not differentiate.
    contract = Roles::BaseContract.new(role, current_user)

    contract.assignable_permissions
  end

  def grouped_setable_permissions(role)
    group_permissions_by_module(setable_permissions(role))
  end

  private

  def group_permissions_by_module(perms)
    perms_by_module = perms.group_by { |p| p.project_module.to_s }
    ::OpenProject::AccessControl
      .sorted_module_names(false)
      .select { |module_name| perms_by_module[module_name].present? }
      .map do |module_name|
      [module_name, perms_by_module[module_name]]
    end
  end
end
