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

# This does filter for whether a role can be assigned to a member.
class Queries::Roles::Filters::GrantableFilter < Queries::Roles::Filters::RoleFilter
  def type
    :list
  end

  def where
    db_values = if values.first == OpenProject::Database::DB_VALUE_TRUE
                  [Role::NON_BUILTIN]
                else
                  [Role::BUILTIN_ANONYMOUS, Role::BUILTIN_NON_MEMBER]
                end

    if operator == '='
      ["roles.builtin IN (?)", db_values]
    else
      ["roles.builtin NOT IN (?)", db_values]
    end
  end

  def allowed_values
    [[I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
     [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE]]
  end
end
