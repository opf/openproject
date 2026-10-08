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
        include Backlogs::Concerns::TimeConsciousScope

        param :sprint
        param :project

        def title
          t("backlogs.show_epic_progress")
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          EnterpriseToken.allows_to?(:sprint_report_pro_widgets) &&
            user_allowed?(:view_sprints) && epic_type.present?
        end

        private

        def relevant_epics
          @relevant_epics ||= begin
            epic_ids = historic? ? historic_relevant_epic_ids : live_relevant_epic_ids

            as_of.where(id: epic_ids, type_id: epic_type.id).visible
          end
        end

        def epic_type
          return @epic_type if defined?(@epic_type)

          @epic_type = Type.find_by(name: "Epic")
        end

        def work_packages_in_sprint
          as_of.where(sprint_id: sprint.id, project_id: project.id).visible
        end

        def live_relevant_epic_ids
          work_package_ids = work_packages_in_sprint.select(:id)

          WorkPackageHierarchy
            .where(descendant_id: work_package_ids)
            .distinct
            .pluck(:ancestor_id)
        end

        def historic_relevant_epic_ids
          work_package_ids = work_packages_in_sprint.pluck(:id)

          work_package_ids | historic_ancestor_ids(work_package_ids)
        end

        def historic_ancestor_ids(ids)
          found = Set.new
          parents = ids

          until parents.empty?
            parents = as_of.where(id: parents).pluck(:parent_id).compact.uniq - found.to_a
            found.merge(parents)
          end

          found.to_a
        end
      end
    end
  end
end
