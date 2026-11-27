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

RSpec.describe ProjectPhases::RescheduleService, type: :model do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }

  let(:service) { described_class.new(user:, project:) }
  let(:date) { Date.new(2025, 4, 1) }
  let(:from) { Date.new(2025, 4, 9) }

  describe "initialization" do
    it "exposes user" do
      expect(service.user).to eq(user)
    end

    it "uses ProjectPhases::RescheduleContract as the default contract" do
      expect(service.contract_class).to eq(ProjectPhases::RescheduleContract)
    end
  end

  describe "contract validation" do
    let(:phases) { create_list(:project_phase, 3, project:) }

    context "when the contract is valid" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:edit_project_phases, project:)
        end
      end

      it "calls the service successfully" do
        expect(service.call(phases:, from:)).to be_success
      end

      it "touches phases" do
        expect do
          service.call(phases:, from:)
        end.to change { phases.each(&:reload).map(&:attributes) }
      end
    end

    context "when the contract is invalid" do
      it "fails the service call" do
        expect(service.call(phases:, from:)).to be_failure
      end

      it "doesn't touch phases" do
        expect do
          service.call(phases:, from:)
        end.not_to change { phases.each(&:reload).map(&:attributes) }
      end
    end
  end

  describe "rescheduling" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    describe "affects only passed phases" do
      let(:project_phases) { create_list(:project_phase, 3, project:) }
      let(:phases) { project_phases.values_at(1) }
      let(:other_phases) { project_phases.values_at(0, 2) }

      it "changes passed phases" do
        expect do
          expect(service.call(phases:, from:)).to be_success
        end.to change { phases.each(&:reload).map(&:attributes) }
      end

      it "doesn't change other phases" do
        expect do
          expect(service.call(phases:, from:)).to be_success
        end.not_to change { other_phases.each(&:reload).map(&:attributes) }
      end
    end

    describe "using duration" do
      let(:phases) do
        [
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 5),
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 10)
        ]
      end

      it "reschedules using it" do
        expect(service.call(phases:, from:)).to be_success

        expect(phases[0]).to have_attributes(start_date: from, finish_date: from + 6, duration: 5)
        expect(phases[1]).to have_attributes(start_date: from + 7, finish_date: from + 20, duration: 10)
      end
    end

    context "for inactive phases" do
      let(:phases) do
        [
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 5, active: false),
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 10)
        ]
      end

      it "skips them" do
        expect(service.call(phases:, from:)).to be_success

        expect(phases[0]).to have_attributes(start_date: date, finish_date: date, duration: 5, active: false)
        expect(phases[1]).to have_attributes(start_date: from, finish_date: from + 13, duration: 10)
      end
    end

    context "for phases without complete date range" do
      let(:phases) do
        [
          create(:project_phase, project:, start_date: nil, finish_date: date, duration: 5),
          create(:project_phase, project:, start_date: date, finish_date: nil, duration: 5),
          create(:project_phase, project:, start_date: date + 1, finish_date: nil, duration: 5),
          create(:project_phase, project:, start_date: nil, finish_date: nil, duration: 5),
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 13),
          # Always ending later than the schedule (rescheduling extends the duration)
          create(:project_phase, project:, start_date: nil, finish_date: [from, date].max + 21, duration: 1),
          # Always ending earlier than the schedule (rescheduling shrinks the duration)
          create(:project_phase, project:, start_date: nil, finish_date: [from, date].min - 1, duration: 2)
        ]
      end

      subject { service.call(phases:, from:) }

      it "reschedules only the ones with a start_date or finish_date present" do
        expect(subject).to be_success
        expect(phases[0]).to have_attributes(start_date: from, finish_date: from, duration: 1)
        expect(phases[1]).to have_attributes(start_date: from + 1, finish_date: nil, duration: 5)
        expect(phases[2]).to have_attributes(start_date: from + 1, finish_date: nil, duration: 5)
        expect(phases[3]).to have_attributes(start_date: from + 1, finish_date: nil, duration: 5)
        expect(phases[4]).to have_attributes(start_date: from + 1, finish_date: from + 19, duration: 13)
        expect(phases[5]).to have_attributes(start_date: from + 20, finish_date: from + 21, duration: 2)
        expect(phases[6]).to have_attributes(start_date: from + 22, finish_date: from + 22, duration: 1)
      end

      context "when the from date is earlier than the phases dates" do
        let(:from) { Date.new(2025, 3, 31) }

        it "reschedules only the ones with a start_date or finish_date present" do
          expect(subject).to be_success
          expect(phases[0]).to have_attributes(start_date: from, finish_date: date, duration: 2)
          expect(phases[1]).to have_attributes(start_date: date + 1, finish_date: nil, duration: 5)
          expect(phases[2]).to have_attributes(start_date: date + 1, finish_date: nil, duration: 5)
          expect(phases[3]).to have_attributes(start_date: date + 1, finish_date: nil, duration: 5)
          expect(phases[4]).to have_attributes(start_date: date + 1, finish_date: date + 17, duration: 13)
          expect(phases[5]).to have_attributes(start_date: date + 20, finish_date: date + 21, duration: 2)
          expect(phases[6]).to have_attributes(start_date: date + 22, finish_date: date + 22, duration: 1)
        end
      end
    end

    context "for phases without duration" do
      let(:phases) do
        [
          create(:project_phase, project:, start_date: date, finish_date: date, duration: nil),
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 10)
        ]
      end

      it "skips them" do
        expect(service.call(phases:, from:)).to be_success

        expect(phases[0]).to have_attributes(start_date: date, finish_date: date, duration: nil)
        expect(phases[1]).to have_attributes(start_date: from, finish_date: from + 13, duration: 10)
      end
    end

    context "for phases with long durations" do
      let(:phases) do
        [
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 500),
          create(:project_phase, project:, start_date: date, finish_date: date, duration: 3000)
        ]
      end

      it "handles them" do
        expect(service.call(phases:, from:)).to be_success

        expect(phases[0]).to have_attributes(start_date: from, finish_date: from + 699, duration: 500)
        expect(phases[1]).to have_attributes(start_date: from + 700, finish_date: from + 4899, duration: 3000)
      end
    end
  end
end
