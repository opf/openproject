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

module Queries::NamedReferences::Filters::MemberExists
  private

  def member_exists(condition, binds, extra_joins: nil)
    honouring_negation(member_exists_sql(condition, extra_joins:), binds)
  end

  def member_exists_sql(condition, extra_joins: nil)
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM type_variants members
        #{extra_joins}
        WHERE members.#{model.variant_reflection.foreign_key} = #{model.table_name}.id
          AND #{condition}
      )
    SQL
  end

  def honouring_negation(sql, binds)
    [negated? ? "NOT (#{sql})" : "(#{sql})", binds]
  end

  def negated?
    operator_strategy == Queries::Operators::NotEquals
  end

  def integer_values
    values.map(&:to_i)
  end
end
