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

require "rails_helper"

RSpec.describe Projects::Phases::ApplyWorkingDaysChangeJob do
  shared_let(:user) { create(:user) }

  current_user { user }

  let(:today) { Date.current }
  let(:work_week) { week_with_saturday_and_sunday_as_weekend }
  let(:previous_working_days) { work_week }
  let(:previous_non_working_days) { [today + 1, today + 2] }
  let(:new_working_days) { previous_working_days }
  let(:new_non_working_days) { previous_non_working_days }

  before do
    allow(Setting).to receive(:working_days).and_return(new_working_days)
    allow(NonWorkingDay).to receive(:pluck).with(:date).and_return(new_non_working_days)

    # for available_phases to return phases
    allow(Project).to receive(:allowed_to).with(user, :view_project_phases).and_return(Project.all)
  end

  describe "#perform" do
    let(:date) { Date.new(2025, 4, 9) }

    subject { described_class.perform_now(user_id: user.id, previous_working_days:, previous_non_working_days:) }

    describe "determining changed days/dates" do
      before do
        allow(Project::Phase)
          .to receive(:covering_dates_or_days_of_week)
          .and_return(Project::Phase.none)
      end

      context "when adding working days" do
        let(:new_working_days) { [*1..6] }

        it "requests phases for added days" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [6], dates: [])
        end
      end

      context "when removing working days" do
        let(:new_working_days) { [1, 2, 4, 5] }

        it "requests phases for deleted days" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [3], dates: [])
        end
      end

      context "when moving working days" do
        let(:new_working_days) { [*2..6] }

        it "requests phases for changed days" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [1, 6], dates: [])
        end
      end

      context "when adding non working dates" do
        let(:new_non_working_days) { [today + 1, today + 2, today + 3] }

        it "requests phases for changed dates" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [], dates: [today + 3])
        end
      end

      context "when removing non working dates" do
        let(:new_non_working_days) { [today + 2] }

        it "requests phases for changed dates" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [], dates: [today + 1])
        end
      end

      context "when changing non working dates" do
        let(:new_non_working_days) { [today + 1, today + 3] }

        it "requests phases for changed dates" do
          subject

          expect(Project::Phase)
            .to have_received(:covering_dates_or_days_of_week)
            .with(days_of_week: [], dates: contain_exactly(today + 2, today + 3))
        end
      end
    end

    describe "calling RescheduleService" do
      before do
        allow(Project::Phase).to receive(:covering_dates_or_days_of_week).and_return(Project::Phase.all)
      end

      context "when there are multiple projects" do
        let!(:project_a) { create(:project) }
        let!(:project_b) { create(:project) }
        let!(:phases_a) do
          [
            create(:project_phase, project: project_a, start_date: date, finish_date: date + 1),
            create(:project_phase, project: project_a, start_date: date + 2, finish_date: date + 3)
          ]
        end
        let!(:phases_b) do
          [
            create(:project_phase, project: project_b, start_date: date + 4, finish_date: date + 5),
            create(:project_phase, project: project_b, start_date: date + 6, finish_date: date + 7)
          ]
        end
        let(:reschedule_service_a) { instance_double(ProjectPhases::RescheduleService, call: nil) }
        let(:reschedule_service_b) { instance_double(ProjectPhases::RescheduleService, call: nil) }

        before do
          where = double
          allow(Project).to receive(:where).with(id: Project::Phase.select(:project_id)).and_return(where)
          allow(where).to receive(:find_each).and_yield(project_a).and_yield(project_b)

          {
            project_a => reschedule_service_a,
            project_b => reschedule_service_b
          }.each do |project, reschedule_service|
            allow(ProjectPhases::RescheduleService)
              .to receive(:new).with(user:, project:).and_return(reschedule_service)
            allow(project).to receive(:touch_and_save_journals)
          end
        end

        it "calls RescheduleService once per project" do
          subject

          expect(ProjectPhases::RescheduleService)
            .to have_received(:new).with(user:, project: project_a).once
          expect(reschedule_service_a)
            .to have_received(:call).with(phases: phases_a, from: date).once

          expect(ProjectPhases::RescheduleService)
            .to have_received(:new).with(user:, project: project_b).once
          expect(reschedule_service_b)
            .to have_received(:call).with(phases: phases_b, from: date + 4).once
        end

        it "journals all projects with correct cause" do
          subject

          expect(project_a).to have_received(:touch_and_save_journals)
          expect(project_a).to have_attributes(journal_cause: an_instance_of(Journal::CausedByWorkingDayChanges))

          expect(project_b).to have_received(:touch_and_save_journals)
          expect(project_b).to have_attributes(journal_cause: an_instance_of(Journal::CausedByWorkingDayChanges))
        end
      end

      context "when project is deleted in the process" do
        let!(:project) { create(:project) }
        let!(:phases) { create_list(:project_phase, 2, project:) }

        before do
          where = double
          allow(Project).to receive(:where).with(id: Project::Phase.select(:project_id)).and_return(where)
          allow(where).to receive(:find_each)

          allow(ProjectPhases::RescheduleService).to receive(:new)
          allow(project).to receive(:touch_and_save_journals)
        end

        it "doesn't cause exception" do
          subject

          expect(ProjectPhases::RescheduleService).not_to have_received(:new)
        end

        it "doesn't journal" do
          subject

          expect(project).not_to have_received(:touch_and_save_journals)
        end
      end

      context "when phases don't have all dates set" do
        let!(:project) { create(:project) }
        let!(:phases) do
          [
            create(:project_phase, project:, start_date: nil, finish_date: nil),
            create(:project_phase, project:, start_date: nil, finish_date: date),
            create(:project_phase, project:, start_date: date + 1, finish_date: nil),
            create(:project_phase, project:, start_date: date + 2, finish_date: date + 3)
          ]
        end
        let(:reschedule_service) { instance_double(ProjectPhases::RescheduleService, call: nil) }

        before do
          where = double
          allow(Project).to receive(:where).with(id: Project::Phase.select(:project_id)).and_return(where)
          allow(where).to receive(:find_each).and_yield(project)

          allow(ProjectPhases::RescheduleService)
            .to receive(:new).and_return(reschedule_service)
          allow(project).to receive(:touch_and_save_journals)
        end

        it "calls RescheduleService with first start_date and only with phases after the start date" do
          subject

          expect(ProjectPhases::RescheduleService)
            .to have_received(:new).with(user:, project:).once
          expect(reschedule_service)
            .to have_received(:call).with(phases: phases[2..3], from: date + 1).once
        end

        it "journals project with correct cause" do
          subject

          expect(project).to have_received(:touch_and_save_journals)
          expect(project).to have_attributes(journal_cause: an_instance_of(Journal::CausedByWorkingDayChanges))
        end
      end

      context "when no phase have start date set" do
        let!(:project) { create(:project) }
        let!(:phases) do
          [
            create(:project_phase, project:, start_date: nil, finish_date: nil),
            create(:project_phase, project:, start_date: nil, finish_date: date)
          ]
        end

        before do
          where = double
          allow(Project).to receive(:where).with(id: Project::Phase.select(:project_id)).and_return(where)
          allow(where).to receive(:find_each).and_yield(project)

          allow(ProjectPhases::RescheduleService).to receive(:new)
          allow(project).to receive(:touch_and_save_journals)
        end

        it "no call RescheduleService is done" do
          subject

          expect(ProjectPhases::RescheduleService).not_to have_received(:new)
        end

        it "doesn't journal" do
          subject

          expect(project).not_to have_received(:touch_and_save_journals)
        end
      end
    end
  end
end
