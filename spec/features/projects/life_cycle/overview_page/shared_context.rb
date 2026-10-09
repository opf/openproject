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

RSpec.shared_context "with seeded projects and phases" do
  shared_let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }
  shared_let(:standard) { create(:standard_global_role) }
  shared_let(:admin) { create(:admin) }

  shared_let(:life_cycle_initiating_definition) do
    create :project_phase_definition, name: "Initiating"
  end
  shared_let(:life_cycle_planning_definition) do
    create :project_phase_definition, :with_gates, name: "Planning"
  end
  shared_let(:life_cycle_executing_definition) do
    create :project_phase_definition, :with_gates, name: "Executing"
  end
  shared_let(:life_cycle_closing_definition) do
    create :project_phase_definition, name: "Closing"
  end

  let(:start_date) { Time.zone.today.next_week }

  let(:initiating_start_date) { start_date }
  let(:initiating_finish_date) { start_date + 1.day }
  let(:initiating_duration) { 2 }
  let(:planning_start_date) { start_date + 2.days }
  let(:planning_finish_date) { start_date + 5.days }
  let(:planning_duration) { 4 }
  let(:executing_start_date) { start_date + 6.days }
  let(:executing_finish_date) { start_date + 7.days }
  let(:executing_duration) { 2 }
  let(:closing_start_date) { start_date + 8.days }
  let(:closing_finish_date) { start_date + 12.days }
  let(:closing_duration) { 4 }

  let(:life_cycle_initiating) do
    create :project_phase,
           definition: life_cycle_initiating_definition,
           start_date: initiating_start_date,
           finish_date: initiating_finish_date,
           project:
  end
  let(:life_cycle_planning) do
    create :project_phase,
           definition: life_cycle_planning_definition,
           start_date: planning_start_date,
           finish_date: planning_finish_date,
           project:
  end
  let(:life_cycle_executing) do
    create :project_phase,
           definition: life_cycle_executing_definition,
           start_date: executing_start_date,
           finish_date: executing_finish_date,
           project:
  end
  let(:life_cycle_closing) do
    create :project_phase,
           definition: life_cycle_closing_definition,
           start_date: closing_start_date,
           finish_date: closing_finish_date,
           project:
  end

  let!(:project_life_cycles) do
    [
      life_cycle_initiating,
      life_cycle_planning,
      life_cycle_executing,
      life_cycle_closing
    ]
  end

  before do
    project.add_journal(user: SystemUser.first)

    project.save_journals
  end
end
