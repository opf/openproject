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

RSpec.describe ProjectPhases::ActivationService, type: :model do
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:definitions) { create_list(:project_phase_definition, 3) }

  let(:service) { described_class.new(user:, project:, definitions:) }

  before do
    allow(project).to receive(:touch_and_save_journals)
  end

  def create_phase(**) = create(:project_phase, project:, **)

  describe "initialization" do
    it "exposes user" do
      expect(service.user).to eq(user)
    end

    it "uses ProjectPhases::ActivationContract as the default contract" do
      expect(service.contract_class).to eq(ProjectPhases::ActivationContract)
    end
  end

  describe "contract validation" do
    context "when the contract is valid" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:select_project_phases, :edit_project_phases, project:)
        end
      end

      it "calls the service successfully" do
        expect(service.call(active: true)).to be_success
      end
    end

    context "when the contract is invalid" do
      it "fails the service call" do
        expect(service.call(active: true)).to be_failure
      end

      it "doesn't touch phases" do
        expect do
          service.call(active: true)
        end.not_to change { project.phases.count }
      end
    end
  end

  describe "activation/deactivation" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:select_project_phases, :edit_project_phases, project:)
      end
    end

    context "when no phases exist" do
      it "creates active phases for every definition" do
        service.call(active: true)

        expect(project.phases).to match_array(definitions.map { have_attributes(active: true, definition_id: it.id) })
      end

      it "creates inactive phases for every definition" do
        service.call(active: false)

        expect(project.phases).to match_array(definitions.map { have_attributes(active: false, definition_id: it.id) })
      end
    end

    context "when some phases exist" do
      let!(:phase1) { create_phase(definition: definitions[1], active: true) }
      let!(:phase2) { create_phase(definition: definitions[2], active: false) }

      it "creates active phases for every definition" do
        service.call(active: true)

        expect(project.phases).to match_array(definitions.map { have_attributes(active: true, definition_id: it.id) })
      end

      it "creates inactive phases for every definition" do
        service.call(active: false)

        expect(project.phases).to match_array(definitions.map { have_attributes(active: false, definition_id: it.id) })
      end
    end
  end

  describe "rescheduling" do
    let(:date) { Date.new(2025, 4, 9) }

    current_user { user }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:select_project_phases, :edit_project_phases, :view_project_phases, project:)
      end

      allow(Project).to receive(:allowed_to).and_call_original
      allow(Project).to receive(:allowed_to).with(user, :view_project_phases).and_return(Project.all)
    end

    context "when changing all" do
      let!(:phase0) { create_phase(definition: definitions[0], start_date: date - 1, finish_date: date + 1) }
      let!(:phase1) { create_phase(definition: definitions[1], start_date: date + 1, finish_date: date + 1) }
      let!(:phase2) { create_phase(definition: definitions[2], start_date: date - 9, finish_date: date - 1) }

      it "doesn't reschedule when deactivating" do
        service.call(active: false)

        expect(phase0.reload).to have_attributes(active: false, start_date: date - 1, finish_date: date + 1)
        expect(phase1.reload).to have_attributes(active: false, start_date: date + 1, finish_date: date + 1)
        expect(phase2.reload).to have_attributes(active: false, start_date: date - 9, finish_date: date - 1)
      end

      it "reschedules when activating" do
        service.call(active: true)

        expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
        expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 2)
        expect(phase2.reload).to have_attributes(active: true, start_date: date + 3, finish_date: date + 11)
      end
    end

    context "when activating one phase" do
      context "having preceding phases with date range" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: date - 1) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules that and following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date + 1)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 4)
          end
        end

        context "with a start date only" do
          context "and earlier than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date - 3, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
            end
          end

          context "and later than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
            end
          end
        end

        context "with a finish date only" do
          context "and earlier than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date - 3) }

            it "reschedules that and following phases filling the start date and creating 1 day phase" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 1, finish_date: date + 3)
            end
          end

          context "and later than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date + 3) }

            it "reschedules that and following phases filling the start date and maintaining the finish date" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date + 3)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
            end
          end
        end

        context "when already activated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules that and following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date + 1)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 4)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with date range" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end
      end

      context "having multiple preceding phases with date range" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: date - 1) }
        let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[2]]) }

        context "with date range" do
          let!(:phase2) { create_phase(definition: definitions[2], active: false, start_date: date + 7, finish_date: date + 9) }

          it "reschedules starting from last preceding phase" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end

        context "when already activated" do
          let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

          it "reschedules starting from last preceding phase" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end
      end

      context "having multiple preceding phases with date range, some inactive" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: date - 1) }
        let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[2]]) }

        context "with date range" do
          let!(:phase2) { create_phase(definition: definitions[2], active: false, start_date: date + 7, finish_date: date + 9) }

          it "reschedules starting from last preceding phase" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end

        context "when already activated" do
          let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

          it "reschedules starting from last preceding phase" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end
      end

      context "having inactive preceding phases with date range" do
        let!(:phase0) { create_phase(definition: definitions[0], active: false, start_date: date - 1, finish_date: date - 1) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: false, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end

        context "when already activated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: false, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: nil) }

          it "doesn't reschedule" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: false, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 7, finish_date: date + 9)
          end
        end
      end

      context "having preceding phases with a start_date only" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: nil) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules that and following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 1, finish_date: date + 3)
          end
        end

        context "with a start date only" do
          context "and earlier than the preceding phase start date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date - 3, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
            end
          end

          context "and later than the preceding phase start date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
            end
          end
        end

        context "with a finish date only" do
          context "and earlier than the preceding phase start date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date - 3) }

            it "reschedules that and following phases filling the start date and creating 1 day phase" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
            end
          end

          context "and later than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date + 3) }

            it "reschedules that and following phases filling the start date and maintaining the finish date" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 3)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
            end
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with start date" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end
      end

      context "having preceding phases with a finish_date only" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: nil, finish_date: date - 1) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules that and following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 1, finish_date: date + 3)
          end
        end

        context "with a start date only" do
          context "and earlier than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date - 3, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
            end
          end

          context "and later than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
            end
          end
        end

        context "with a finish date only" do
          context "and earlier than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date - 3) }

            it "reschedules that and following phases filling the start date and creating 1 day phase" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
              expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
            end
          end

          context "and later than the preceding phase finish date" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date + 3) }

            it "reschedules that and following phases filling the start date and maintaining the finish date" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 3)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
            end
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with start date" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end
      end

      context "having preceding phases without date range" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: nil, finish_date: nil) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end

        context "with a start date only" do
          context "and earlier than the following phase" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date - 3, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date - 3, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 3, finish_date: date - 1)
            end
          end

          context "and later than the following phase" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 10, finish_date: nil) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: date + 10, finish_date: nil)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 10, finish_date: date + 12)
            end
          end
        end

        context "with a finish date only" do
          context "and earlier than the following phase" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date - 3) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 3)
              expect(phase2.reload).to have_attributes(active: true, start_date: date - 3, finish_date: date - 1)
            end
          end

          context "and later than the following phase" do
            let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: date + 10) }

            it "reschedules that and following phases" do
              service.call(active: true)

              expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
              expect(phase1.reload).to have_attributes(active: true, start_date: nil, finish_date: date + 10)
              expect(phase2.reload).to have_attributes(active: true, start_date: date + 10, finish_date: date + 12)
            end
          end
        end

        context "when already activated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 4, finish_date: date + 6)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: nil, finish_date: nil) }

          it "doesn't reschedule" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 7, finish_date: date + 9)
          end
        end
      end

      context "having no preceding phases" do
        let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[0]]) }

        context "with date range" do
          let!(:phase0) { create_phase(definition: definitions[0], active: false, start_date: date - 1, finish_date: date - 1) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date + 1)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 4)
          end
        end

        context "when already activated" do
          let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: date - 1) }

          it "reschedules following phases" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: true, start_date: date, finish_date: date + 1)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 4)
          end
        end

        context "without date range" do
          let!(:phase0) { create_phase(definition: definitions[0], active: false, start_date: nil, finish_date: nil) }

          it "doesn't reschedule" do
            service.call(active: true)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: true, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date + 7, finish_date: date + 9)
          end
        end
      end
    end

    context "when deactivating one phase" do
      context "having preceding phases with date range" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: date - 1) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with date range" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end

        context "when already deactivated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with date range" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with date range" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end

        context "with a start date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date - 3, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with date range" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date - 3, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end

        context "with a finish date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: date - 3) }

          it "reschedules that and following phases filling the start date and creating 1 day phase" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: date - 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date, finish_date: date + 2)
          end
        end
      end

      context "having preceding phases with a start_date only" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: date - 1, finish_date: nil) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "when already deactivated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "with a start date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date - 3, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: false, start_date: date - 3, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "with a finish date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: date - 3) }

          it "reschedules following phases using the dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: date - 1, finish_date: nil)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: date - 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end
      end

      context "having preceding phases with a finish_date only" do
        let!(:phase0) { create_phase(definition: definitions[0], active: true, start_date: nil, finish_date: date - 1) }
        let!(:phase2) { create_phase(definition: definitions[2], active: true, start_date: date + 7, finish_date: date + 9) }

        let(:service) { described_class.new(user:, project:, definitions: [definitions[1]]) }

        context "with date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "when already deactivated" do
          let!(:phase1) { create_phase(definition: definitions[1], active: false, start_date: date + 2, finish_date: date + 3) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date + 2, finish_date: date + 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "without date range" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "with a start date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: date - 3, finish_date: nil) }

          it "reschedules following phases using dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: date - 3, finish_date: nil)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end

        context "with a finish date only" do
          let!(:phase1) { create_phase(definition: definitions[1], active: true, start_date: nil, finish_date: date - 3) }

          it "reschedules following phases using the dates of the closest preceding phase with a start date" do
            service.call(active: false)

            expect(phase0.reload).to have_attributes(active: true, start_date: nil, finish_date: date - 1)
            expect(phase1.reload).to have_attributes(active: false, start_date: nil, finish_date: date - 3)
            expect(phase2.reload).to have_attributes(active: true, start_date: date - 1, finish_date: date + 1)
          end
        end
      end
    end
  end

  describe "journaling" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:select_project_phases, :edit_project_phases, project:)
      end
    end

    it "journals the project" do
      service.call(active: true)

      expect(project).to have_received(:touch_and_save_journals)
    end
  end
end
