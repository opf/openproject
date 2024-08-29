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

module NotificationSettings::Scopes
  module Applicable
    extend ActiveSupport::Concern

    class_methods do
      # Return notifications settings that prevail in the selected context (project)
      # If there is only the global notification setting in place, those are authoritative.
      # If there is a project specific setting in place, it is the project specific setting instead.
      # rubocop:disable Metrics/AbcSize
      def applicable(project)
        global_notifications = NotificationSetting.arel_table
        project_notifications = NotificationSetting.arel_table.alias("project_settings")

        subselect = global_notifications
                    .where(global_notifications[:project_id].eq(nil))
                    .join(project_notifications, Arel::Nodes::OuterJoin)
                    .on(project_notifications[:project_id].eq(project.id),
                        global_notifications[:user_id].eq(project_notifications[:user_id]))
                    .project(global_notifications.coalesce(project_notifications[:id], global_notifications[:id]))

        where(global_notifications[:id].in(subselect))
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
