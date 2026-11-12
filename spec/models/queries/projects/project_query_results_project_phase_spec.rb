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

RSpec.describe ProjectQuery, "results of a project phase filter" do
  let(:instance) { described_class.new }
  let(:filter_key) { "project_phase_#{phase.definition_id}" }

  shared_let(:view_role) { create(:project_role, permissions: %i[view_project_phases]) }

  shared_let(:phase_start_date) { Date.parse("2025-02-07") }
  shared_let(:phase_finish_date) { Date.parse("2025-02-17") }
  shared_let(:project_with_phase) { create(:project, name: "Project with phase") }
  shared_let(:phase) do
    create(:project_phase, project: project_with_phase, start_date: phase_start_date, finish_date: phase_finish_date)
  end

  # This is added to ensure that the filter only works on the phase provided.
  shared_let(:project_with_rival_phase) { create(:project, name: "Project with rival phase") }
  shared_let(:rival_phase) do
    create(:project_phase, project: project_with_rival_phase, start_date: phase_start_date, finish_date: phase_finish_date)
  end

  shared_let(:project_without_phase) { create(:project, name: "Project without phase") }

  shared_let(:user) do
    create(:user, member_with_permissions: {
             project_with_phase => %i[view_project_phases],
             project_with_rival_phase => %i[view_project_phases],
             project_without_phase => %i[view_project_phases]
           })
  end

  current_user { user }

  # rubocop:disable RSpec/ScatteredSetup
  def self.disable_phase
    before do
      Project::Phase.update_all(active: false)
    end
  end

  def self.remove_phase_dates
    before do
      phase.update_columns(finish_date: nil, start_date: nil)
    end
  end

  def self.remove_permissions
    before do
      # We keep the permission within the Project without phases so that the filter itself is available
      # but we check that the filter does not return values.
      RolePermission
        .where(role_id: Role.joins(:member_roles)
                            .where(member_roles: { member_id: Member.where(project: [project_with_phase]) }))
        .where(permission: :view_project_phases)
        .destroy_all
    end
  end
  # rubocop:enable RSpec/ScatteredSetup

  context "with a =d (on) operator" do
    before do
      instance.where(filter_key, "=d", values)
    end

    context "when filtering in the middle of the phase" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

      it "returns the project whose phase is covering an interval including the date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering on the first day of the phase" do
      let(:values) { [phase_start_date.to_s] }

      it "returns the project whose phase begins on that date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering on the last day of the phase" do
      let(:values) { [phase_finish_date.to_s] }

      it "returns the project whose phase ends on that date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering before the phase" do
      let(:values) { [(phase_start_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering after the phase" do
      let(:values) { [(phase_finish_date + 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the phase has no dates" do
      let(:values) { [phase_finish_date.to_s] }

      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the phase but with the phase being inactive" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the phase but without permissions" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

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

    context "when being in the middle of the phase" do
      it "returns the project whose phase is currently running" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on the first day of the phase" do
      it "returns the project whose phase begins on that date" do
        Timecop.travel(phase_start_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on the last day of the phase" do
      it "returns the project whose phase begins on that date" do
        Timecop.travel(phase_finish_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being before the phase" do
      it "returns no project" do
        Timecop.travel(phase_start_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the phase" do
      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when the phase has no dates" do
      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when being in the middle of the phase but with the phase being disabled" do
      disable_phase

      it "returns no project" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the phase but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  context "with a w (this week) operator" do
    before do
      instance.where(filter_key, "w", [])
    end

    context "when being in the middle of the phase" do
      it "returns the project whose phase is currently running" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when the current week overlaps the beginning of the phase" do
      it "returns the project whose phase begins within the week" do
        Timecop.travel((phase_start_date - 1.day).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when the current week overlaps the end of the phase" do
      it "returns the project whose phase begins within the week" do
        Timecop.travel(phase_finish_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being before the phase" do
      it "returns no project" do
        Timecop.travel(phase_start_date.noon - 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the phase" do
      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when the phase has no dates" do
      remove_phase_dates

      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the phase but with the phase disabled" do
      disable_phase

      it "returns no project" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the phase but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Monday, the phase ends on Sunday and the week is configured to start on Sunday",
            with_settings: { start_of_week: 7 } do
      before do
        phase.update_column(:finish_date, Date.parse("2025-02-16"))
      end

      it "returns the project whose phase has ended within the current week" do
        Timecop.travel(Date.parse("2025-02-17").noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on Monday, the phase ends on Sunday and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        phase.update_column(:finish_date, Date.parse("2025-02-16"))
      end

      it "returns no project as the phase ended in the week before" do
        Timecop.travel(Date.parse("2025-02-17").noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Sunday, the phase ends on Monday and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        phase.update_column(:finish_date, Date.parse("2025-02-17"))
      end

      it "returns the project whose phase has ended within the current week" do
        Timecop.travel(Date.parse("2025-02-23").noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on Sunday, the phase ends on Monday and the week is configured to start on Sunday",
            with_settings: { start_of_week: 7 } do
      before do
        phase.update_column(:finish_date, Date.parse("2025-02-17"))
      end

      it "returns no project as the phase ended in the week before" do
        Timecop.travel(Date.parse("2025-02-23").noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Wednesday before the phase, the phase starts on Monday and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        phase.update_column(:start_date, Date.parse("2025-02-03"))
      end

      it "returns no project as the phase starts in the next week" do
        Timecop.travel(Date.parse("2025-01-29").noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Sunday, same as the phase's start date and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        phase.update_column(:start_date, Date.parse("2025-02-09"))
      end

      it "returns the project whose gate is in the current week" do
        Timecop.travel(Date.parse("2025-02-09").noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end
  end

  context "with a <>d (between) operator" do
    before do
      instance.where(filter_key, "<>d", values)
    end

    context "when encompassing the phase completely" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when encompassing the phase precisely" do
      let(:values) { [phase_start_date.to_s, phase_finish_date.to_s] }

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the values overlap the phase's start date but not the end date" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values overlap the phase's end date but not the start date" do
      let(:values) { [(phase_start_date + 1.day).to_s, phase_finish_date.to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values are between the start and the end date of the phase" do
      let(:values) { [(phase_start_date + 1.day).to_s, (phase_finish_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the lower value is provided and that one is before the phase's start date" do
      let(:values) { [(phase_start_date - 1.day).to_s, ""] }

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when only the lower value is provided and that one is on the phase's start date" do
      let(:values) { [phase_start_date.to_s, ""] }

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when only the lower value is provided and that one after the phase's start date" do
      let(:values) { [(phase_start_date + 1.day).to_s, ""] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the upper value is provided and that one is after the phase's end date" do
      let(:values) { ["", (phase_finish_date + 1.day).to_s] }

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the phase has no dates" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when no value is provided" do
      let(:values) { ["", ""] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the phase completely but with the phase disabled" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the phase completely but without permissions" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

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

    context "when the phase is active but has no dates" do
      remove_phase_dates

      it "returns the project with the phase" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the phase is active and has dates" do
      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the phase is inactive and has no dates" do
      remove_phase_dates
      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end
end
