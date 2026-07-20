# frozen_string_literal: true

# -- copyright
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
# ++

module Grids
  module Widgets
    class ProjectTimeline < Grids::WidgetComponent
      param :project

      def title
        if project.portfolio?
          t("grids.widgets.project_timeline.title_portfolio")
        elsif project.program?
          t("grids.widgets.project_timeline.title_program")
        else
          t("grids.widgets.project_timeline.title")
        end
      end

      def phases_data
        project.phases.active
               .eager_load(definition: :color)
               .order("project_phase_definitions.position")
               .map { |phase| phase_data(phase) }
               .to_json
      end

      def any_phases?
        project.phases.active.with_timeline_content.exists?
      end

      def render?
        User.current.allowed_in_project?(:view_project_phases, project)
      end

      def wrapper_arguments
        { full_width: true }
      end

      private

      def phase_data(phase) # rubocop:disable Metrics/AbcSize
        {
          id: phase.id,
          definitionId: phase.definition.id,
          name: phase.definition.name,
          startDate: phase.start_date&.iso8601,
          endDate: phase.finish_date&.iso8601,
          startGate: phase.definition.start_gate && phase.date_range_set?,
          startGateName: phase.definition.start_gate_name,
          finishGate: phase.definition.finish_gate && phase.date_range_set?,
          finishGateName: phase.definition.finish_gate_name
        }
      end
    end
  end
end
