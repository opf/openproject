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

# The project of a notification is the project of its resource. Notifications are
# created for resources of different types (work packages and documents), all of which
# store their project in a `project_id` column.
module Queries::Notifications::ResourceProject
  module_function

  def resource_classes
    [WorkPackage, Document]
  end

  # LEFT OUTER JOINs every resource table under an alias of its own. Only the table
  # matching the notification's resource_type will have a matching row.
  # Identical in every query part using it so that Rails joins the tables only once
  # when a query is filtered, grouped and ordered by project at the same time.
  def joins
    resource_classes
      .map do |klass|
        table_alias = table_alias_for(klass)

        <<~SQL.squish
          LEFT OUTER JOIN #{klass.table_name} #{table_alias}
          ON #{table_alias}.id = #{Notification.table_name}.resource_id
          AND #{Notification.table_name}.resource_type = '#{klass.name}'
        SQL
      end
      .join(" ")
  end

  # The project id of the notification's resource. Requires the `joins`.
  def project_id_sql
    columns = resource_classes.map { |klass| "#{table_alias_for(klass)}.project_id" }

    "COALESCE(#{columns.join(', ')})"
  end

  def table_alias_for(klass)
    "notification_#{klass.table_name}"
  end
end
