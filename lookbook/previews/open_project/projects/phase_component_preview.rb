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

module OpenProject::Projects
  # @logical_path OpenProject/Projects
  class PhaseComponentPreview < Lookbook::Preview
    def phase_with_both_gates
      phase = Project::Phase.new(id: 1,
                                 definition: definition(start_gate: true, finish_gate: true),
                                 start_date: Date.current - 2.days,
                                 finish_date: Date.current + 2.days)

      render_with_template(locals: { phase: })
    end

    def phase_with_both_gates_dates_not_set
      phase = Project::Phase.new(id: 1,
                                 definition: definition(start_gate: true, finish_gate: true))

      render_with_template(locals: { phase: })
    end

    def phase_with_start_gate
      phase = Project::Phase.new(id: 1,
                                 definition: definition(start_gate: true),
                                 start_date: Date.current - 2.days,
                                 finish_date: Date.current + 2.days)

      render_with_template(locals: { phase: })
    end

    def phase_with_finish_gate
      phase = Project::Phase.new(id: 1,
                                 definition: definition(finish_gate: true),
                                 start_date: Date.current - 2.days,
                                 finish_date: Date.current + 2.days)

      render_with_template(locals: { phase: })
    end

    def phase_without_gate
      phase = Project::Phase.new(id: 1,
                                 definition: definition,
                                 start_date: Date.current - 2.days,
                                 finish_date: Date.current + 2.days)

      render_with_template(locals: { phase: })
    end

    private

    def definition(start_gate: false, finish_gate: false)
      Project::PhaseDefinition.new(id: 1,
                                   name: "The first gate",
                                   start_gate: start_gate,
                                   start_gate_name: start_gate ? "Before the phase" : nil,
                                   finish_gate: finish_gate,
                                   finish_gate_name: finish_gate ? "After the phase" : nil)
    end
  end
end
