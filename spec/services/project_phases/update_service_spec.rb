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
require "services/base_services/behaves_like_update_service"

RSpec.describe ProjectPhases::UpdateService, type: :model do
  before do
    allow(project).to receive(:touch_and_save_journals)
  end

  it_behaves_like "BaseServices update service" do
    let(:factory) { :project_phase }
    let(:contract_class) { ProjectPhases::UpdateContract }
    let(:project) { model_instance.project }
  end

  describe "journalizing" do
    shared_let(:phase) { create(:project_phase) }

    let(:user) { build_stubbed(:user) }
    let(:project) { phase.project }
    let(:service) { described_class.new(user:, model: phase) }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    it "calls touch_and_save_journals on project" do
      expect(service.call).to be_success

      expect(project).to have_received(:touch_and_save_journals)
    end
  end

  describe "updating duration through SetAttributesService" do
    shared_let(:phase) { create(:project_phase, duration: nil) }

    let(:user) { build_stubbed(:user) }
    let(:project) { phase.project }
    let(:service) { described_class.new(user:, model: phase) }
    let(:date) { Date.current }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    it "sets duration for valid model" do
      expect(service.call(start_date: date - 1, finish_date: date + 1)).to be_success
      expect(phase.saved_change_to_duration).to eq([nil, 3]) # Changes are saved
    end

    it "sets duration for invalid model" do
      expect(service.call(start_date: date + 1, finish_date: date - 1)).to be_failure
      expect(phase.duration_change).to eq([nil, 0]) # Changes are not saved
    end
  end

  describe "#reschedule_following_phases" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

    let(:date) { Date.new(2025, 4, 9) }
    let(:user) { create(:user) }
    let(:service) { described_class.new(user:, model: phase) }
    let(:project) { create(:project) }

    current_user { user }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end

      allow(Project).to receive(:allowed_to).with(user, :view_project_attributes).and_return(Project.all)
      allow(Project).to receive(:allowed_to).with(user, :view_project_phases).and_return(Project.all)
    end

    context "for no dates range" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date - 10, finish_date: date - 10, duration: 3) }

      it "doesn't get rescheduled" do
        expect do
          expect(service.call(start_date: nil, finish_date: nil)).to be_success
        end.not_to change(following, :attributes)
      end
    end

    context "for invalid date range" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date - 10, finish_date: date - 10, duration: 3) }

      it "doesn't get rescheduled" do
        expect do
          expect(service.call(start_date: date, finish_date: date - 1)).not_to be_success
        end.not_to change(following, :attributes)
      end
    end

    context "for preceding phase" do
      let!(:preceding) { create(:project_phase, project:, start_date: date - 7, finish_date: date - 7, duration: 1) }
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }

      it "doesn't get rescheduled" do
        expect do
          expect(service.call(start_date: date, finish_date: date + 1)).to be_success
        end.not_to change(preceding, :attributes)
      end
    end

    context "for following phases" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following1) { create(:project_phase, project:, start_date: date + 6, finish_date: date + 8, duration: 3) }
      let!(:following2) { create(:project_phase, project:, start_date: date + 6, finish_date: date + 8, duration: 2) }
      let!(:following3) { create(:project_phase, project:, start_date: date + 6, finish_date: date + 8, duration: 1) }

      it "reschedules all of them relying on duration" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success

        expect(following1).to have_attributes(start_date: date + 2, finish_date: date + 6, duration: 3)
        expect(following2).to have_attributes(start_date: date + 7, finish_date: date + 8, duration: 2)
        expect(following3).to have_attributes(start_date: date + 9, finish_date: date + 9, duration: 1)
      end

      context "when providing a start date only" do
        it "reschedules all of them relying on duration" do
          expect(service.call(start_date: date, finish_date: nil)).to be_success

          expect(following1).to have_attributes(start_date: date, finish_date: date + 2, duration: 3)
          expect(following2).to have_attributes(start_date: date + 5, finish_date: date + 6, duration: 2)
          expect(following3).to have_attributes(start_date: date + 7, finish_date: date + 7, duration: 1)
        end
      end

      context "for a finish date only" do
        it "reschedules all of them relying on duration" do
          expect(service.call(start_date: nil, finish_date: date + 1)).to be_success

          expect(following1).to have_attributes(start_date: date + 1, finish_date: date + 5, duration: 3)
          expect(following2).to have_attributes(start_date: date + 6, finish_date: date + 7, duration: 2)
          expect(following3).to have_attributes(start_date: date + 8, finish_date: date + 8, duration: 1)
        end
      end
    end

    context "for following phase without duration" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date + 6, finish_date: date + 8, duration: nil) }

      it "doesn't get rescheduled" do
        expect do
          expect(service.call(start_date: date, finish_date: date + 1)).to be_success
        end.not_to change(following, :attributes)
      end
    end

    context "for following phase without date range" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: nil, finish_date: nil, duration: 3) }

      it "reschedules setting the start date to follow the previous phase" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success
        expect(following).to have_attributes(start_date: date + 2, finish_date: nil, duration: 3)
      end
    end

    context "for following phase with a start date only" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date + 1, finish_date: nil, duration: 3) }

      it "reschedules by moving the start date only" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success

        expect(following).to have_attributes(start_date: date + 2, finish_date: nil, duration: 3)
      end
    end

    context "for following phase with date range in the past" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date - 10, finish_date: date - 10, duration: 3) }

      it "reschedules it" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success

        expect(following).to have_attributes(start_date: date + 2, finish_date: date + 6, duration: 3)
      end
    end

    context "for following phase with duration over a year" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date, finish_date: date, duration: 500) }

      it "reschedules it" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success

        expect(following).to have_attributes(start_date: date + 2, finish_date: date + 701, duration: 500)
      end
    end

    context "for following phase with duration over 10 years" do
      let!(:phase) { create(:project_phase, project:, start_date: date, finish_date: date) }
      let!(:following) { create(:project_phase, project:, start_date: date, finish_date: date, duration: 3000) }

      it "reschedules it" do
        expect(service.call(start_date: date, finish_date: date + 1)).to be_success

        expect(following).to have_attributes(start_date: date + 2, finish_date: date + 4201, duration: 3000)
      end
    end
  end
end
