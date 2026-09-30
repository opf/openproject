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

class Queries::WorkPackages::Filter::ProjectPhaseFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  include Queries::ProjectPhaseDefinitions::DatabaseQueries

  def allowed_values
    @allowed_values ||= project_phase_definitions.map { |s| [s.name, s.id.to_s] }
  end

  def available?
    project_phase_definitions.any?
  end

  def type
    :list_optional
  end

  def self.key
    :project_phase_definition_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    available_definitions = project_phase_definitions.index_by(&:id)

    values.filter_map { |id| available_definitions[id.to_i] }
  end

  def joins
    join_project_phase_definitions_based_on_permissions_and_active_phases
  end

  def where
    operator_strategy.sql_for_field(values, :active_phases, :project_phase_definition_id)
  end

  private

  def project_phase_feature_available?
    if (project = context&.project)
      User.current.allowed_in_project?(:view_project_phases, project)
    else
      User.current.allowed_in_any_project?(:view_project_phases)
    end
  end

  def project_phase_definitions
    return Project::PhaseDefinition.none unless project_phase_feature_available?

    Project::PhaseDefinition.order(position: :asc)
  end
end
