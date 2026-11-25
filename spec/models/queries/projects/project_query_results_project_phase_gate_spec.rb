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

require "spec_helper"

RSpec.describe ProjectQuery, "results of a project phase gate filter" do
  let(:instance) { described_class.new }

  shared_let(:view_role) { create(:project_role, permissions: %i[view_project_phases]) }

  shared_let(:gate_definition) { create(:project_phase_definition, :with_start_gate, :with_finish_gate) }
  shared_let(:start_gate_date) { Date.parse("2025-03-04") }
  shared_let(:finish_gate_date) { Date.parse("2025-03-07") }
  shared_let(:project_with_gate) { create(:project, name: "Project with gate") }
  shared_let(:gate) do
    create(:project_phase,
           project: project_with_gate,
           start_date: start_gate_date,
           finish_date: finish_gate_date,
           definition: gate_definition)
  end

  # This is added to ensure that the filter only works on the gate provided.
  shared_let(:rival_gate_definition) { create(:project_phase_definition, :with_start_gate, :with_finish_gate) }
  shared_let(:project_with_rival_gate) { create(:project, name: "Project with rival gate") }
  shared_let(:rival_gate) do
    create(:project_phase,
           project: project_with_rival_gate,
           start_date: start_gate_date,
           finish_date: finish_gate_date,
           definition: rival_gate_definition)
  end

  shared_let(:project_without_phase) { create(:project, name: "Project without phase") }

  shared_let(:user) do
    create(:user, member_with_permissions: {
             project_with_gate => %i[view_project_phases],
             project_with_rival_gate => %i[view_project_phases],
             project_without_phase => %i[view_project_phases]
           })
  end

  current_user { user }

  # rubocop:disable RSpec/ScatteredSetup
  def self.disable_gate
    before do
      Project::Phase.update_all(active: false)
    end
  end

  def self.remove_gate_date
    before do
      gate.update_columns("#{boundary}_date": nil)
    end
  end

  def self.remove_permissions
    before do
      # We keep the permission within the Project without phases so that the filter itself is available,
      # but we check that the filter does not return values.
      RolePermission
        .where(role_id: Role.joins(:member_roles)
                            .where(member_roles: { member_id: Member.where(project: [project_with_gate]) }))
        .where(permission: :view_project_phases)
        .destroy_all
    end
  end
  # rubocop:enable RSpec/ScatteredSetup

  shared_examples_for "a project phase gate filter" do
    let(:filter_key) { "project_#{boundary}_gate_#{gate.definition_id}" }

    context "with a =d (on) operator" do
      before do
        instance.where(filter_key, "=d", values)
      end

      context "when filtering on the day of the gate" do
        let(:values) { [filter_reference_date.to_s] }

        it "returns the project whose gate is on the date of the value" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when filtering before the gate" do
        let(:values) { [(filter_reference_date - 1.day).to_s] }

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when filtering after the gate" do
        let(:values) { [(filter_reference_date + 1.day).to_s] }

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when the gate has no dates" do
        let(:values) { [filter_reference_date.to_s] }

        remove_gate_date

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when filtering on the day of the gate but with the gate being inactive" do
        let(:values) { [filter_reference_date.to_s] }

        disable_gate

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when filtering on the day of the gate but without permissions" do
        let(:values) { [filter_reference_date.to_s] }

        remove_permissions

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end
    end

    context "with a t (today) operator" do
      before do
        instance.where(filter_key, "t", [])
      end

      context "when being on the day of the gate" do
        it "returns the project whose gate is on the date of the value" do
          Timecop.travel(filter_reference_date.noon) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end

      context "when being before the day of the gate" do
        it "returns no project" do
          Timecop.travel(filter_reference_date.noon - 1.day) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being after the day of the gate" do
        it "returns no project" do
          Timecop.travel(filter_reference_date.noon + 1.day) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when the gate has no dates" do
        remove_gate_date

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on the day of the gate but with the gate being disabled" do
        disable_gate

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on the day of the gate but without permissions" do
        remove_permissions

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon) do
            expect(instance.results).to be_empty
          end
        end
      end
    end

    context "with a w (this week) operator" do
      before do
        instance.where(filter_key, "w", [])
      end

      context "when being a day before the gate" do
        it "returns the project whose gate is within the current week" do
          Timecop.travel(filter_reference_date.noon - 1.day) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end

      context "when being a day after the gate" do
        it "returns the project whose gate is within the current week" do
          Timecop.travel(filter_reference_date.noon + 1.day) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end

      context "when being in the week before the day of the gate" do
        it "returns no project" do
          Timecop.travel(filter_reference_date.noon - 7.days) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being in the week after the day of the gate" do
        it "returns no project" do
          Timecop.travel(filter_reference_date.noon + 7.days) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being a day before the gate but with the gate disabled" do
        disable_gate

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon - 1.day) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being a day before the gate but without permissions" do
        remove_permissions

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon - 1.day) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being a day before the gate but without the gate having dates" do
        remove_gate_date

        it "returns no project" do
          Timecop.travel(filter_reference_date.noon - 1.day) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on Monday, the gate is on Sunday and the week is configured to start on Sunday",
              with_settings: { start_of_week: 7 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-02"))
        end

        it "returns the project whose gate is in the current week" do
          Timecop.travel(Date.parse("2025-03-03").noon) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end

      context "when being on Monday, the gate is on Sunday and the week is configured to start on Monday",
              with_settings: { start_of_week: 1 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-02"))
        end

        it "returns no project as the gate is in the week before" do
          Timecop.travel(Date.parse("2025-03-03").noon) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on Sunday after the gate, the gate is on Monday and the week is configured to start on Monday",
              with_settings: { start_of_week: 1 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-03"))
        end

        it "returns the project whose gate is in the current week" do
          Timecop.travel(Date.parse("2025-03-09").noon) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end

      context "when being on Sunday, the gate is on Monday and the week is configured to start on Sunday",
              with_settings: { start_of_week: 7 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-03"))
        end

        it "returns no project as the gate is in the week before" do
          Timecop.travel(Date.parse("2025-03-09").noon) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on Wednesday before the gate, the gate is Monday and the week is configured to start on Monday",
              with_settings: { start_of_week: 1 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-03"))
        end

        it "returns no project as the gate is in the week after" do
          Timecop.travel(Date.parse("2025-02-26").noon) do
            expect(instance.results).to be_empty
          end
        end
      end

      context "when being on Sunday, same as the gate and the week is configured to start on Monday",
              with_settings: { start_of_week: 1 } do
        before do
          # This might produce invalid phases where the start date is after the end date.
          # For the sake of the test, this is irrelevant.
          gate.update_column(:"#{boundary}_date", Date.parse("2025-03-02"))
        end

        it "returns the project whose gate is in the current week" do
          Timecop.travel(Date.parse("2025-03-02").noon) do
            expect(instance.results).to contain_exactly(project_with_gate)
          end
        end
      end
    end

    context "with a <>d (between) operator" do
      before do
        instance.where(filter_key, "<>d", values)
      end

      context "when encompassing the gate completely" do
        let(:values) { [(filter_reference_date - 1.day).to_s, (filter_reference_date + 1.day).to_s] }

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when encompassing the gate precisely" do
        let(:values) { [filter_reference_date.to_s, filter_reference_date.to_s] }

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when only the lower value is provided and that one is before the gate's date" do
        let(:values) { [(filter_reference_date - 1.day).to_s, ""] }

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when only the upper value is provided and that one is after the gate's date" do
        let(:values) { ["", (filter_reference_date + 1.day).to_s] }

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when only the upper value is provided and that one is on the gate's date" do
        let(:values) { ["", filter_reference_date.to_s] }

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when only the upper value is provided and that one is before the gate's date" do
        let(:values) { ["", (filter_reference_date - 1.day).to_s] }

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when the gate has no dates" do
        let(:values) { [(filter_reference_date - 1.day).to_s, (filter_reference_date + 1.day).to_s] }

        remove_gate_date

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when encompassing the gate precisely but with the gate disabled" do
        let(:values) { [filter_reference_date.to_s, filter_reference_date.to_s] }

        disable_gate

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when encompassing the gate precisely but without permissions" do
        let(:values) { [filter_reference_date.to_s, filter_reference_date.to_s] }

        remove_permissions

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end
    end

    context "with a !* (none) operator" do
      before do
        instance.where(filter_key, "!*", [])
      end

      context "when the gate is active but has no dates" do
        remove_gate_date

        it "returns the project with the gate" do
          expect(instance.results).to contain_exactly(project_with_gate)
        end
      end

      context "when the gate is active and has dates" do
        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end

      context "when the gate is inactive and has no dates" do
        remove_gate_date
        disable_gate

        it "returns no project" do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  context "for a gate on the start date" do
    let(:boundary) { "start" }
    let(:filter_reference_date) { start_gate_date }

    it_behaves_like "a project phase gate filter"
  end

  context "for a gate on the finish date" do
    let(:boundary) { "finish" }
    let(:filter_reference_date) { finish_gate_date }

    it_behaves_like "a project phase gate filter"
  end
end
