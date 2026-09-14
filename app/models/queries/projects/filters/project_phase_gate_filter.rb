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

class Queries::Projects::Filters::ProjectPhaseGateFilter < Queries::Projects::Filters::Base
  include Queries::Projects::Filters::DynamicallyFromProjectPhase
  include Queries::Projects::Filters::FilterOnProjectPhase

  class << self
    def key
      /\Aproject_(?<gate>finish|start)_gate_(?<id>\d+)\z/
    end

    private

    def accessor_matches?(definition, match)
      super && match[:gate].in?(%w[start finish]) &&
        ((match[:gate] == "start" && definition.start_gate) ||
         (match[:gate] == "finish" && definition.finish_gate))
    end

    def create_from_phase(phase, context)
      filters = []
      filters << create!(name: "project_start_gate_#{phase.id}", context:) if phase.start_gate
      filters << create!(name: "project_finish_gate_#{phase.id}", context:) if phase.finish_gate
      filters
    end
  end

  def initialize(name, options = {})
    @project_phase_gate = name.match(key)[:gate]

    super
  end

  def human_name
    gate_name = if project_phase_gate == "start"
                  project_phase_definition.start_gate_name
                else
                  project_phase_definition.finish_gate_name
                end

    I18n.t("project.filters.project_phase_gate", gate: gate_name)
  end

  private

  attr_accessor :project_phase_gate

  def on_date
    gate_where(parsed_end)
  end

  def on_today
    gate_where(today, today)
  end

  def between_date
    gate_where(parsed_start, parsed_end)
  end

  def this_week
    gate_where(beginning_of_week.to_date, end_of_week.to_date)
  end

  def none
    project_phase_scope
      .where(column_name => nil)
  end

  def gate_where(start_date, finish_date = start_date)
    project_phase_scope
      .where(date_range_clause(Project::Phase.table_name,
                               column_name,
                               start_date,
                               finish_date))
  end

  def project_phase_scope_limit(scope)
    super
      .joins(:definition)
      .where(project_phase_definitions: {
               id: project_phase_definition.id,
               "#{project_phase_gate}_gate" => true
             })
  end

  def column_name
    "#{project_phase_gate}_date"
  end
end
