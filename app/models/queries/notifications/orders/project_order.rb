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

class Queries::Notifications::Orders::ProjectOrder < Queries::Orders::Base
  self.model = Notification

  PROJECTS_ALIAS = "notification_projects"

  def self.key
    :project
  end

  def joins
    [
      Queries::Notifications::ResourceProject.joins,
      <<~SQL.squish
        LEFT OUTER JOIN #{Project.table_name} #{PROJECTS_ALIAS}
        ON #{PROJECTS_ALIAS}.id = #{Queries::Notifications::ResourceProject.project_id_sql}
      SQL
    ]
  end

  protected

  def order(scope)
    with_raise_on_invalid do
      order_string = "#{PROJECTS_ALIAS}.name"
      order_string += " DESC" if direction == :desc

      scope.order(order_string)
    end
  end
end
