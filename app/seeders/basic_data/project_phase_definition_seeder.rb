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

module BasicData
  class ProjectPhaseDefinitionSeeder < ModelSeeder
    self.model_class = Project::PhaseDefinition
    self.seed_data_model_key = "project_phases"
    self.needs = [
      BasicData::ProjectPhaseColorSeeder
    ]

    self.attribute_names_for_lookups = %i[name]

    def model_attributes(phase_data)
      start_gate_name = phase_data["start_gate"]
      start_gate = !start_gate_name.nil?

      {
        name: phase_data["name"],
        color_id: color_id(phase_data["color_name"]),
        start_gate:,
        start_gate_name:
      }
    end
  end
end
