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

class Queries::WorkPackages::Selects::ProjectPhaseSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  include Queries::ProjectPhaseDefinitions::DatabaseQueries

  def initialize
    super(:project_phase,
          group_by_column_name: :project_phase_definition,
          sortable: sortable_statement,
          groupable: group_by_statement,
          groupable_join: group_by_join_statement,
          groupable_select: groupable_select
    )
  end

  def groupable_select
    group_by_statement
  end

  def group_by_statement
    "active_phases.project_phase_definition_id"
  end

  def order_for_count
    active_phase_null_case(true_case: "1", false_case: "0")
  end

  def group_by_join_statement
    join_project_phase_definitions_based_on_permissions_and_active_phases
  end

  def sortable_join_statement(_query)
    # Replicate the group by join to ensure the same conditions are applied (and the same alias for the join is used)
    group_by_join_statement
  end

  def sortable_statement
    # We use the join alias from the group by join statement to ensure that work packages with an *inactive* project
    # phase are treated like work packages *without* a project phase. In the result list, they will belong to the
    # same group: without an active project phase.
    active_phase_null_case(true_case: "-1", false_case: "active_phases.position")
  end

  def self.instances(context = nil)
    allowed = if context
                User.current.allowed_in_project?(:view_project_phases, context)
              else
                User.current.allowed_in_any_project?(:view_project_phases)
              end

    if allowed
      [new]
    else
      []
    end
  end

  private

  def project_with_view_phases_permissions
    Project.allowed_to(User.current, :view_project_phases).select(:id)
  end

  def active_phase_null_case(true_case:, false_case:)
    "(CASE WHEN ACTIVE_PHASES.ID IS NULL THEN #{true_case} ELSE #{false_case} END)"
  end
end
