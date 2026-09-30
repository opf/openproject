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

module DemoData
  class ProjectPhaseSeeder < Seeder
    attr_reader :project
    alias_method :project_data, :seed_data

    def initialize(project, project_data)
      super(project_data)
      @project = project
    end

    def seed_data!
      print_status "    ↳ Activating project phases with dates"

      return unless should_seed_phases?

      ApplicationRecord.transaction do
        activate_phases
        configure_phases
      end
    end

    private

    def should_seed_phases?
      project_data.lookup("project_phases") && project.phases.empty?
    end

    def phases_by_definition_id
      @phases_by_definition_id ||=
        Array(project_data.lookup("project_phases")).index_by do |config|
          seed_data.find_reference(config["definition"]).id
        end
    end

    def definitions
      @definitions ||= begin
        definition_refs = Array(project_data.lookup("project_phases")).pluck("definition")
        seed_data.find_references(definition_refs).sort_by(&:position)
      end
    end

    def activate_phases
      ProjectPhases::ActivationService
        .new(user: admin_user, project:, definitions:)
        .call(active: true)
    end

    def configure_phases
      initiating_date = Date.current
      phases = project.phases.where(definition: definitions)

      phases.each { |phase| set_phase_attributes(phase, initiating_date) }

      ProjectPhases::RescheduleService
        .new(user: admin_user, project:)
        .call(phases:, from: initiating_date)
    end

    def set_phase_attributes(phase, initiating_date)
      phase.duration = phases_by_definition_id[phase.definition_id]["duration"]
      # Set the default initiating date in order to trigger the scheduler
      phase.start_date = phase.finish_date = initiating_date
      phase.save!(validate: false)
    end
  end
end
