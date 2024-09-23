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

class Queries::Projects::Filters::PrincipalFilter < Queries::Projects::Filters::Base
  def type
    :list_optional
  end

  def allowed_values
    @allowed_values ||= ::Principal.pluck(:id).map { |id| [id, id.to_s] }
  end

  def apply_to(_query_scope)
    if operator_strategy == Queries::Operators::NotEquals
      super
        .where.not(id: member_statement(Queries::Operators::Equals))
    elsif operator_strategy == Queries::Operators::None
      super
        .where.not(id: member_statement(Queries::Operators::All))
    else
      super
        .where(id: member_statement(operator_strategy))
    end
  end

  def where
    # handled by scope
    nil
  end

  private

  def member_statement(used_operator_strategy)
    Member
      .of_any_project
      .where(used_operator_strategy.sql_for_field(values, "members", "user_id"))
      .select(:project_id)
  end
end
