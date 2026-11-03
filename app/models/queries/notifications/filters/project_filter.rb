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

class Queries::Notifications::Filters::ProjectFilter < Queries::Notifications::Filters::NotificationFilter
  include Queries::Filters::Shared::ProjectFilter::Optional

  # Notifications are matched if their resource (e.g. a work package or a document)
  # matches the filter on its project. The condition is evaluated per resource type
  # within a subquery so that each operator (including the negating ones) is applied
  # only to the resource the notification is about.
  def where
    conditions = Queries::Notifications::ResourceProject.resource_classes.map do |klass|
      <<~SQL.squish
        (#{Notification.table_name}.resource_type = '#{klass.name}'
        AND #{Notification.table_name}.resource_id IN (
          SELECT #{klass.table_name}.id
          FROM #{klass.table_name}
          WHERE #{operator_strategy.sql_for_field(values, klass.table_name, :project_id)}
        ))
      SQL
    end

    "(#{conditions.join(' OR ')})"
  end
end
