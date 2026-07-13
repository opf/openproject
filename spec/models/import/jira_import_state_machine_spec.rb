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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraImportStateMachine do
  subject(:state_machine) { jira_import.state_machine }

  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  describe "states" do
    it "defines all expected states" do
      expected_states = %w[
        initial
        instance_meta_fetching
        instance_meta_error
        instance_meta_done
        import_scope
        configuring
        projects_meta_fetching
        projects_meta_error
        projects_meta_done
        importing
        import_error
        imported
        reverting
        revert_error
        revert_cancelling
        revert_cancelled
        reverted
        finalizing
        finalizing_error
        finalizing_done
      ]

      expect(described_class.states).to eq(expected_states)
    end

    it "has initial as the initial state" do
      expect(state_machine.current_state).to eq("initial")
    end
  end

  describe "transitions" do
    before do
      # Stub all job classes to prevent actual job execution
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
      allow(Import::JiraProjectsMetaDataJob).to receive(:perform_later)
      allow(Import::JiraFetchAndImportProjectsJob).to receive(:perform_later)
      allow(Import::JiraRevertImportJob).to receive(:perform_later).and_return(double(job_id: "test-job-id"))
      allow(Import::JiraFinalizeImportJob).to receive(:perform_later)
    end

    describe "valid transitions" do
      {
        "initial" => %w[instance_meta_fetching],
        "instance_meta_fetching" => %w[instance_meta_done instance_meta_error],
        "instance_meta_error" => %w[instance_meta_fetching],
        "instance_meta_done" => %w[configuring instance_meta_fetching],
        "configuring" => %w[projects_meta_fetching],
        "projects_meta_fetching" => %w[projects_meta_done projects_meta_error],
        "projects_meta_error" => %w[projects_meta_fetching],
        "projects_meta_done" => %w[importing],
        "importing" => %w[imported import_error],
        "import_error" => %w[importing reverting],
        "imported" => %w[finalizing reverting],
        "finalizing" => %w[finalizing_error finalizing_done],
        "finalizing_error" => %w[finalizing],
        "reverting" => %w[reverted revert_cancelling revert_error],
        "revert_cancelling" => %w[revert_cancelled],
        "revert_cancelled" => %w[reverting],
        "revert_error" => %w[reverting]
      }.each do |from_state, to_states|
        to_states.each do |to_state|
          it "allows transition from #{from_state} to #{to_state}" do
            transition_to_state(jira_import, from_state)

            expect(state_machine.can_transition_to?(to_state)).to be true
            expect { state_machine.transition_to!(to_state) }.not_to raise_error
            expect(state_machine.current_state).to eq(to_state)
          end
        end
      end
    end

    describe "invalid transitions" do
      it "does not allow transition from initial to imported" do
        expect(state_machine.can_transition_to?("imported")).to be false
      end

      it "does not allow transition from initial to reverting" do
        expect(state_machine.can_transition_to?("reverting")).to be false
      end

      it "does not allow transition from imported to initial" do
        transition_to_state(jira_import, "imported")

        expect(state_machine.can_transition_to?("initial")).to be false
      end

      it "does not allow transition from finalizing_done to any state" do
        transition_to_state(jira_import, "finalizing_done")

        described_class.states.each do |target_state|
          expect(state_machine.can_transition_to?(target_state)).to be false
        end
      end

      it "does not allow transition from reverted to any state" do
        transition_to_state(jira_import, "reverted")

        described_class.states.each do |target_state|
          expect(state_machine.can_transition_to?(target_state)).to be false
        end
      end
    end
  end

  describe "after_transition callbacks" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
      allow(Import::JiraProjectsMetaDataJob).to receive(:perform_later)
      allow(Import::JiraFetchAndImportProjectsJob).to receive(:perform_later)
      allow(Import::JiraRevertImportJob).to receive(:perform_later).and_return(double(job_id: "test-job-id"))
      allow(Import::JiraFinalizeImportJob).to receive(:perform_later)
    end

    it "enqueues JiraInstanceMetaDataJob when transitioning to instance_meta_fetching" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(Import::JiraInstanceMetaDataJob).to have_received(:perform_later).with(jira_import.id)
    end

    it "enqueues JiraProjectsMetaDataJob when transitioning to projects_meta_fetching" do
      transition_to_state(jira_import, "configuring")

      state_machine.transition_to!("projects_meta_fetching")

      expect(Import::JiraProjectsMetaDataJob).to have_received(:perform_later).with(jira_import.id)
    end

    it "enqueues JiraFetchAndImportProjectsJob when transitioning to importing" do
      transition_to_state(jira_import, "projects_meta_done")

      state_machine.transition_to!("importing")

      expect(Import::JiraFetchAndImportProjectsJob).to have_received(:perform_later).with(jira_import.id)
    end

    it "enqueues JiraRevertImportJob and stores job_id when transitioning to reverting" do
      transition_to_state(jira_import, "imported")

      state_machine.transition_to!("reverting")

      expect(Import::JiraRevertImportJob).to have_received(:perform_later).with(jira_import.id)
      expect(jira_import.last_transition.metadata["job_id"]).to eq("test-job-id")
    end

    it "enqueues JiraFinalizeImportJob when transitioning to finalizing" do
      transition_to_state(jira_import, "imported")

      state_machine.transition_to!("finalizing")

      expect(Import::JiraFinalizeImportJob).to have_received(:perform_later).with(jira_import.id)
    end

    it "clears cursor when transitioning to reverted" do
      jira_import.update_column(:cursor, { "page" => 5 })
      transition_to_state(jira_import, "reverting")

      state_machine.transition_to!("reverted")

      expect(jira_import.reload.cursor).to be_nil
    end
  end

  describe "#status_running?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
      allow(Import::JiraProjectsMetaDataJob).to receive(:perform_later)
      allow(Import::JiraFetchAndImportProjectsJob).to receive(:perform_later)
      allow(Import::JiraRevertImportJob).to receive(:perform_later).and_return(double(job_id: "test-job-id"))
      allow(Import::JiraFinalizeImportJob).to receive(:perform_later)
    end

    %w[instance_meta_fetching projects_meta_fetching importing reverting finalizing].each do |running_state|
      it "returns true when in #{running_state} state" do
        transition_to_state(jira_import, running_state)

        expect(state_machine.status_running?).to be true
      end
    end

    %w[initial instance_meta_done instance_meta_error configuring projects_meta_done
       projects_meta_error imported import_error reverted revert_error
       finalizing_done finalizing_error].each do |non_running_state|
      it "returns false when in #{non_running_state} state" do
        transition_to_state(jira_import, non_running_state)

        expect(state_machine.status_running?).to be false
      end
    end
  end

  describe "#status_equal_or_after?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
    end

    it "returns true when current state is equal to the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.status_equal_or_after?("instance_meta_fetching")).to be true
    end

    it "returns true when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.status_equal_or_after?("initial")).to be true
    end

    it "returns false when current state is before the check state" do
      expect(state_machine.status_equal_or_after?("instance_meta_fetching")).to be false
    end
  end

  describe "#status_equal_or_before?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
    end

    it "returns true when current state is equal to the check state" do
      expect(state_machine.status_equal_or_before?("initial")).to be true
    end

    it "returns true when current state is before the check state" do
      expect(state_machine.status_equal_or_before?("instance_meta_fetching")).to be true
    end

    it "returns false when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.status_equal_or_before?("initial")).to be false
    end
  end

  describe "#status_before?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
    end

    it "returns true when current state is before the check state" do
      expect(state_machine.status_before?("instance_meta_fetching")).to be true
    end

    it "returns false when current state is equal to the check state" do
      expect(state_machine.status_before?("initial")).to be false
    end

    it "returns false when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.status_before?("initial")).to be false
    end
  end

  describe "#status_after?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
    end

    it "returns true when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.status_after?("initial")).to be true
    end

    it "returns false when current state is equal to the check state" do
      expect(state_machine.status_after?("initial")).to be false
    end

    it "returns false when current state is before the check state" do
      expect(state_machine.status_after?("instance_meta_fetching")).to be false
    end
  end

  describe "#deletable?" do
    before do
      allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
      allow(Import::JiraProjectsMetaDataJob).to receive(:perform_later)
      allow(Import::JiraFetchAndImportProjectsJob).to receive(:perform_later)
      allow(Import::JiraRevertImportJob).to receive(:perform_later).and_return(double(job_id: "test-job-id"))
      allow(Import::JiraFinalizeImportJob).to receive(:perform_later)
    end

    context "when in running states" do
      %w[instance_meta_fetching projects_meta_fetching importing reverting finalizing].each do |running_state|
        it "returns false when in #{running_state} state" do
          transition_to_state(jira_import, running_state)

          expect(state_machine.deletable?).to be false
        end
      end
    end

    context "when in non-deletable states" do
      %w[imported import_error revert_error].each do |non_deletable_state|
        it "returns false when in #{non_deletable_state} state" do
          transition_to_state(jira_import, non_deletable_state)

          expect(state_machine.deletable?).to be false
        end
      end
    end

    context "when in deletable states" do
      %w[initial instance_meta_done instance_meta_error configuring projects_meta_done
         projects_meta_error reverted finalizing_done finalizing_error].each do |deletable_state|
        it "returns true when in #{deletable_state} state" do
          transition_to_state(jira_import, deletable_state)

          expect(state_machine.deletable?).to be true
        end
      end
    end
  end

  private

  # Helper method to transition through states to reach a target state
  def transition_to_state(jira_import, target_state)
    return if jira_import.current_state == target_state

    paths = {
      "instance_meta_fetching" => %w[instance_meta_fetching],
      "instance_meta_error" => %w[instance_meta_fetching instance_meta_error],
      "instance_meta_done" => %w[instance_meta_fetching instance_meta_done],
      "configuring" => %w[instance_meta_fetching instance_meta_done configuring],
      "projects_meta_fetching" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching],
      "projects_meta_error" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                                  projects_meta_error],
      "projects_meta_done" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                                 projects_meta_done],
      "importing" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
                        importing],
      "import_error" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                           projects_meta_done importing import_error],
      "imported" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
                       importing imported],
      "finalizing" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
                         importing imported finalizing],
      "finalizing_error" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                               projects_meta_done importing imported finalizing finalizing_error],
      "finalizing_done" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                              projects_meta_done importing imported finalizing finalizing_done],
      "reverting" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
                        importing imported reverting],
      "revert_error" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                           projects_meta_done importing imported reverting revert_error],
      "revert_cancelling" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                                projects_meta_done importing imported reverting revert_cancelling],
      "revert_cancelled" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching
                               projects_meta_done importing imported reverting revert_cancelling revert_cancelled],
      "reverted" => %w[instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
                       importing imported reverting reverted]
    }

    path = paths[target_state]
    raise "No path defined for state: #{target_state}" unless path

    path.each do |state|
      jira_import.transition_to!(state) unless jira_import.current_state == state
    end
  end
end
