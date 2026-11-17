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
        include ChartBlankslate

        param :sprint
        param :project

        def title = t(".title")

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          sprint.date_range_set? &&
            EnterpriseToken.allows_to?(:sprint_report_pro_widgets) &&
            user_allowed?(:view_sprints) && epic_type_id.present?
        end

        private

        def blankslate_reason
          return if relevant_epics.any?

          work_packages_in_sprint.exists? ? :no_epics : :no_work
        end

        def relevant_epics
          @relevant_epics ||= begin
            epic_ids = historic? ? historic_relevant_epic_ids : live_relevant_epic_ids

            work_packages_at_report_time
              .where(id: epic_ids)
              .visible(current_user)
              .includes(:type, :status)
              .order(:subject)
          end
        end

        def epic_type_id
          return @epic_type_id if defined?(@epic_type_id)

          @epic_type_id = Type.where(name: "Epic").pick(:id)
        end

        def work_packages_in_sprint
          work_packages_at_report_time.where(sprint:, project:).visible(current_user)
        end

        def live_relevant_epic_ids
          WorkPackageHierarchy
            .joins(:ancestor)
            .where(descendant_id: work_packages_in_sprint.select(:id), ancestor: { type_id: epic_type_id })
            .select("DISTINCT ON (descendant_id) ancestor_id")
            .order(:descendant_id, :generations)
        end

        def historic_relevant_epic_ids
          epic_ids = Set.new
          visited = Set.new
          rows = hierarchy_rows(work_packages_in_sprint)

          until rows.empty?
            visited.merge(rows.map(&:first))
            found_epic_ids, parent_ids = epics_and_parents(rows)

            epic_ids.merge(found_epic_ids)
            rows = hierarchy_rows(work_packages_at_report_time.where(id: parent_ids - visited.to_a))
          end

          epic_ids.to_a
        end

        def hierarchy_rows(scope)
          scope.pluck(:id, :type_id, :parent_id)
        end

        def epics_and_parents(rows)
          epics, others = rows.partition { |_id, type_id, _parent_id| type_id == epic_type_id }

          [epics.map(&:first), others.filter_map(&:last).uniq]
        end
      end
    end
  end
end
