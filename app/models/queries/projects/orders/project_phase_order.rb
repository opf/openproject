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

class Queries::Projects::Orders::ProjectPhaseOrder < Queries::Orders::Base
  self.model = Project

  validates :project_phase_definition, presence: { message: I18n.t(:"activerecord.errors.messages.does_not_exist") }

  def self.key
    /\Aproject_phase_(\d+)\z/
  end

  def project_phase_definition
    return @project_phase_definition if defined?(@project_phase_definition)

    @project_phase_definition = Project::PhaseDefinition.find_by(id: attribute[/\Aproject_phase_(\d+)\z/, 1])
  end

  def available?
    project_phase_definition.present? &&
      User.current.allowed_in_any_project?(:view_project_phases)
  end

  private

  def joins
    join = <<~SQL.squish
      LEFT JOIN (
              SELECT project_phases.*, project_phases.definition_id as def_id
              FROM project_phases
              WHERE
                project_phases.active = true
                AND project_phases.definition_id = :definition_id
                AND project_phases.project_id IN (#{viewable_project_ids.to_sql})
            ) #{subquery_table_name} ON #{subquery_table_name}.project_id = projects.id
    SQL

    ActiveRecord::Base.sanitize_sql([join, { definition_id: project_phase_definition.id }])
  end

  # Since we can combine multiple queries with their respective ORDER BY clauses, we need to make sure
  # that the names of our tables are unique. It suffices to include the definition id into the name as there can only
  # ever be one order statement per definition.
  def subquery_table_name
    definition_id = project_phase_definition.id

    :"project_phase_subquery_#{definition_id}"
  end

  def order(scope)
    with_raise_on_invalid do
      scope.where(order_condition)
           .order(*order_by_start_and_finish_date)
    end
  end

  # Ensure that only life cycle columns viewable to the current user are considered
  # for ordering the query result.
  def viewable_project_ids
    Project.allowed_to(User.current, :view_project_phases).select(:id)
  end

  def order_condition
    # To avoid SQL injection warnings, we use Arel to build the condition.
    # Note that this SQL query uses the subquery defined in `joins`.
    steps_table = Arel::Table.new(subquery_table_name.to_s)

    # WHERE subquery_table_name.def_id = project_phase_definition.id OR subquery_table_name.def_id IS NULL
    steps_table[:def_id]
      .eq(project_phase_definition.id)
      .or(steps_table[:def_id].eq(nil))
  end

  def order_by_start_and_finish_date
    steps_table = Arel::Table.new(subquery_table_name.to_s)

    # Even though a gate does not define an finish_date, this code still works.
    [
      steps_table[:start_date].send(direction),
      steps_table[:finish_date].send(direction)
    ]
  end
end
