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

# This filters for the type of role (project or global)
class Queries::Roles::Filters::UnitFilter < Queries::Roles::Filters::RoleFilter
  def type
    :list
  end

  def where
    if operator == '!'
      ["roles.type != ?", db_values]
    elsif values.first == 'project'
      ["roles.type = ? AND roles.builtin = ?", db_values, Role::NON_BUILTIN]
    else
      ["roles.type = ?", db_values]
    end
  end

  def allowed_values
    [%w(system system),
     %w(project project)]
  end

  private

  def db_values
    if values.first == 'system'
      [GlobalRole.name.to_s]
    else
      [ProjectRole.name.to_s]
    end
  end
end
