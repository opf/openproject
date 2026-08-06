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
module Projects::Exports
  module Formatters
    class ProjectPhase < ::Exports::Formatters::Default
      def self.apply?(attribute, _export_format)
        Queries::Projects::Selects::ProjectPhase.id_from_key(attribute).present?
      end

      ##
      # Takes a project and returns the active phase's date range as "start - finish",
      # or a blank string when there is no phase the user may see.
      def format(project, **)
        return "" unless User.current.allowed_in_project?(:view_project_phases, project)

        phase = phase_for(project)
        return "" unless phase

        format_phase_value(phase)
      end

      private

      def phase_for(project)
        definition_id = Queries::Projects::Selects::ProjectPhase.id_from_key(attribute)
        definition = Project::PhaseDefinition.find_by(id: definition_id)
        return nil unless definition

        project.phases.active.find_by(definition:)
      end

      def format_phase_value(phase)
        start = phase.start_date ? format_date(phase.start_date) : I18n.t("js.label_no_start_date")
        finish = phase.finish_date ? format_date(phase.finish_date) : I18n.t("js.label_no_due_date")

        "#{start} - #{finish}"
      end
    end
  end
end
