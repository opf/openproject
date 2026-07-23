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
        return [].to_json unless view_project_phases_allowed?

        project.phases.active
               .eager_load(definition: :color)
               .order("project_phase_definitions.position")
               .map { |phase| phase_data(phase) }
               .to_json
      end

      def milestones_data
        milestones_scope
          .map { |wp| { id: wp.id, subject: wp.subject, date: wp.due_date.iso8601, typeId: wp.type_id } }
          .to_json
      end

      def any_content?
        any_phases? || milestones_scope.exists?
      end

      def render?
        view_project_phases_allowed? || view_work_packages_allowed?
      end

      def gantt_link
        return unless view_work_packages_allowed?

        result = ::Gantt::DefaultQueryGeneratorService.new(with_project: project).call(query_key: :milestones)
        return unless result

        params = JSON.parse(result[:query_props])
        params["hi"] = false
        helpers.project_gantt_index_path(project, query_props: params.to_json)
      end

      def wrapper_arguments
        { full_width: true }
      end

      private

      def view_work_packages_allowed?
        @view_work_packages_allowed ||= User.current.allowed_in_project?(:view_work_packages, project)
      end

      def view_project_phases_allowed?
        @view_project_phases_allowed ||= User.current.allowed_in_project?(:view_project_phases, project)
      end

      def any_phases?
        view_project_phases_allowed? && project.phases.active.with_timeline_content.exists?
      end

      def milestones_scope
        @milestones_scope ||= WorkPackage
          .visible(User.current)
          .where(project:)
          .joins(:type)
          .where(types: { is_milestone: true })
          .where.not(due_date: nil)
          .order(:due_date)
      end

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
