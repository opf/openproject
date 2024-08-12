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

module TimeEntryActivities::Scopes
  module ActiveInProject
    extend ActiveSupport::Concern

    class_methods do
      def active_in_project(project)
        being_active_in_project(project)
          .or(being_not_inactive_in_project(project))
      end

      private

      # All activities, that have a specific setting for the project to be active.
      # The global active state has no effect in that case.
      def being_active_in_project(project)
        where(id: of_project(project).where(active: true))
      end

      # All activities that are active and do not have a project specific setting stating
      # the activity to be inactive. So there could either be no project specific setting (for that project) or
      # a project specific setting that is active.
      def being_not_inactive_in_project(project)
        where(active: true).where.not(id: of_project(project).where(active: false))
      end

      def of_project(project)
        TimeEntryActivitiesProject.where(project_id: project.id).select(:activity_id)
      end
    end
  end
end
