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

class Queries::Projects::Filters::UserActionFilter < Queries::Projects::Filters::Base
  def allowed_values
    @allowed_values ||= Action.default.pluck(:id, :id)
  end

  def type
    :list_all
  end

  def where
    operator = if operator_class <= ::Queries::Operators::Equals || operator_class <= ::Queries::Operators::EqualsAll
                 "IN"
               elsif operator_class <= ::Queries::Operators::NotEquals
                 "NOT IN"
               else
                 raise ArgumentError
               end

    capability_select_queries
      .map { |query| "#{Project.table_name}.id #{operator} (#{query.to_sql})" }
      .join(" AND ")
  end

  private

  def capability_select_queries
    if operator_class <= ::Queries::Operators::EqualsAll
      values.map do |val|
        Capability
          .where(action: val)
          .where(principal: User.current)
          .reselect(:context_id)
      end
    else
      [Capability
         .where(action: values)
         .where(principal: User.current)
         .reselect(:context_id)]
    end
  end
end
