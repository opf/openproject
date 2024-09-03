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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::Roles::Filters::AllowsBecomingAssigneeFilter <
  Queries::Roles::Filters::RoleFilter
  def type
    :list
  end

  def where
    permission_ids = if values.first == OpenProject::Database::DB_VALUE_TRUE
                       assignable_permissions
                     else
                       unassignable_permissions
                     end

    if operator == "="
      ["role_permissions.id IN (?)", permission_ids]
    else
      ["role_permissions.id NOT IN (?)", permission_ids]
    end
  end

  def joins
    :role_permissions
  end

  def allowed_values
    [[I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
     [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE]]
  end

  private

  def assignable_permissions
    RolePermission.where(permission: "work_package_assigned")
                  .select("id")
  end

  def unassignable_permissions
    RolePermission.where.not(permission: "work_package_assigned")
                  .select("id")
  end
end
