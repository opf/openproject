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

module Backlogs
  module SprintReports
    module Widgets
      class EpicProgress < Grids::WidgetComponent
        include Backlogs::CommonHelper

        param :sprint
        param :project

        def title
          # TODO
          "Epic progress"
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          user_allowed?(:view_sprints) && epic_type.present?
        end

        def resolved_percentage(epic)
          return 0 if total_work_packages_count(epic).zero?

          (resolved_work_packages_count(epic).to_f / total_work_packages_count(epic) * 100).round
        end

        private

        def work_packages_in_sprint
          WorkPackage.where(sprint:, project:).visible
        end

        def relevant_epics
          @relevant_epics ||= begin
            epic_ids = WorkPackageHierarchy
                         .where(descendant_id: work_packages_in_sprint.select(:id))
                         .distinct
                         .pluck(:ancestor_id)

            WorkPackage.where(id: epic_ids, type: epic_type).visible
          end
        end

        def work_packages_in_epic(epic)
          epic.descendants.visible
        end

        def resolved_work_packages_count(epic)
          work_packages_in_epic(epic).where(status_id: project.done_status_ids).count
        end

        def total_work_packages_count(epic)
          work_packages_in_epic(epic).count
        end

        def epic_type
          return @epic_type if defined?(@epic_type)

          @epic_type = Type.find_by(name: "Epic")
        end
      end
    end
  end
end
