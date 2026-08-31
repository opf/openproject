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

  before do
    login_as(author)

    allow(Import::JiraInstanceMetaDataJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraInstanceMetaDataJob, job_id: "instance-meta-job-id"))
    allow(Import::JiraProjectsMetaDataJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraProjectsMetaDataJob, job_id: "projects-meta-job-id"))
    allow(Import::JiraRevertImportJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraRevertImportJob, job_id: "revert-job-id"))
    allow(Import::JiraFinalizeImportJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraFinalizeImportJob, job_id: "finalize-job-id"))
  end

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
        import_aborting
        imported
        reverting
        revert_error
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
        "importing" => %w[imported import_error import_aborting],
        "import_aborting" => %w[import_error],
        "import_error" => %w[importing reverting],
        "imported" => %w[finalizing reverting],
        "finalizing" => %w[finalizing_error finalizing_done],
        "finalizing_error" => %w[finalizing],
        "reverting" => %w[reverted revert_error],
        "revert_error" => %w[reverting]
      }.each do |from_state, to_states|
        to_states.each do |to_state|
          it "allows transition from #{from_state} to #{to_state}" do
            transition_to_state(from_state)

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
        transition_to_state("imported")

        expect(state_machine.can_transition_to?("initial")).to be false
      end

      it "does not allow transition from import_aborting to imported" do
        transition_to_state("import_aborting")

        expect(state_machine.can_transition_to?("imported")).to be false
      end

      it "does not allow transition from finalizing_done to any state" do
        transition_to_state("finalizing_done")

        described_class.states.each do |target_state|
          expect(state_machine.can_transition_to?(target_state)).to be false
        end
      end

      it "does not allow transition from reverted to any state" do
        transition_to_state("reverted")

        described_class.states.each do |target_state|
          expect(state_machine.can_transition_to?(target_state)).to be false
        end
      end
    end
  end

  describe "after_transition callbacks" do
    it "enqueues JiraInstanceMetaDataJob when transitioning to instance_meta_fetching" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(Import::JiraInstanceMetaDataJob).to have_received(:perform_later).with(jira_import.id)
      expect(jira_import.last_transition.metadata["job_id"]).to eq("instance-meta-job-id")
    end

    context "when the enqueue limit rejects the job because an equivalent one is still queued" do
      before do
        allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later).and_return(false)
      end

      it "records the already queued job so the UI still has a job to follow" do
        queued_job = GoodJob::Job.create!(
          active_job_id: SecureRandom.uuid,
          job_class: "Import::JiraInstanceMetaDataJob",
          concurrency_key: "Import::JiraInstanceMetaDataJob-#{jira_import.id}"
        )

        state_machine.transition_to!("instance_meta_fetching")

        expect(jira_import.last_transition.metadata["job_id"]).to eq(queued_job.id)
      end

      it "leaves the job id blank rather than raising when no queued job is left" do
        expect { state_machine.transition_to!("instance_meta_fetching") }.not_to raise_error

        expect(jira_import.last_transition.metadata["job_id"]).to be_nil
      end
    end

    it "enqueues JiraProjectsMetaDataJob when transitioning to projects_meta_fetching" do
      transition_to_state("configuring")

      state_machine.transition_to!("projects_meta_fetching")

      expect(Import::JiraProjectsMetaDataJob).to have_received(:perform_later).with(jira_import.id)
      expect(jira_import.last_transition.metadata).to include("job_id" => "projects-meta-job-id",
                                                              "user_id" => author.id)
    end

    it "enqueues a GoodJob batch when transitioning to importing" do
      transition_to_state("projects_meta_done")

      expect { state_machine.transition_to!("importing") }.to change(GoodJob::BatchRecord, :count).by(1)

      expect(jira_import.last_transition.metadata).to include("batch_id" => GoodJob::BatchRecord.last.id,
                                                              "user_id" => author.id)
    end

    it "retries the existing batch when transitioning to importing again" do
      transition_to_state("import_error")
      batch_id = GoodJob::BatchRecord.last.id

      expect { state_machine.transition_to!("importing") }.not_to change(GoodJob::BatchRecord, :count)

      expect(jira_import.last_transition.metadata["batch_id"]).to eq(batch_id)
    end

    it "discards the pending batch jobs when transitioning to import_aborting" do
      transition_to_state("importing")
      pending_job = instance_double(GoodJob::Job, status: :queued, discard_job: nil)
      running_job = instance_double(GoodJob::Job, status: :running, discard_job: nil)
      stub_batch_jobs([pending_job, running_job])

      state_machine.transition_to!("import_aborting")

      expect(pending_job).to have_received(:discard_job).with("Discarded because user clicked abort.")
      expect(running_job).not_to have_received(:discard_job)
    end

    it "keeps aborting when a batch job is already locked" do
      transition_to_state("importing")
      locked_job = instance_double(GoodJob::Job, status: :queued)
      pending_job = instance_double(GoodJob::Job, status: :queued, discard_job: nil)
      allow(locked_job)
        .to receive(:discard_job)
        .and_raise(GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError)
      stub_batch_jobs([locked_job, pending_job])

      state_machine.transition_to!("import_aborting")

      expect(state_machine.current_state).to eq("import_aborting")
      expect(pending_job).to have_received(:discard_job)
    end

    it "enqueues JiraRevertImportJob when transitioning to reverting" do
      transition_to_state("imported")

      state_machine.transition_to!("reverting")

      expect(Import::JiraRevertImportJob).to have_received(:perform_later).with(jira_import.id)
      expect(jira_import.last_transition.metadata).to include("job_id" => "revert-job-id", "user_id" => author.id)
    end

    it "enqueues JiraFinalizeImportJob when transitioning to finalizing" do
      transition_to_state("imported")

      state_machine.transition_to!("finalizing")

      expect(Import::JiraFinalizeImportJob).to have_received(:perform_later).with(jira_import.id)
      expect(jira_import.last_transition.metadata).to include("job_id" => "finalize-job-id", "user_id" => author.id)
    end
  end

  describe "#running?" do
    %w[instance_meta_fetching projects_meta_fetching importing import_aborting reverting finalizing]
      .each do |running_state|
      it "returns true when in #{running_state} state" do
        transition_to_state(running_state)

        expect(state_machine.running?).to be true
      end
    end

    %w[initial instance_meta_done instance_meta_error configuring projects_meta_done
       projects_meta_error imported import_error reverted revert_error
       finalizing_done finalizing_error].each do |non_running_state|
      it "returns false when in #{non_running_state} state" do
        transition_to_state(non_running_state)

        expect(state_machine.running?).to be false
      end
    end
  end

  describe "#error?" do
    %w[instance_meta_error projects_meta_error import_error revert_error finalizing_error].each do |error_state|
      it "returns true when in #{error_state} state" do
        transition_to_state(error_state)

        expect(state_machine.error?).to be true
      end
    end

    %w[initial instance_meta_fetching instance_meta_done configuring projects_meta_fetching projects_meta_done
       importing import_aborting imported reverting reverted finalizing finalizing_done].each do |non_error_state|
      it "returns false when in #{non_error_state} state" do
        transition_to_state(non_error_state)

        expect(state_machine.error?).to be false
      end
    end
  end

  describe "#state_equal_or_after?" do
    it "returns true when current state is equal to the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.state_equal_or_after?("instance_meta_fetching")).to be true
    end

    it "returns true when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.state_equal_or_after?("initial")).to be true
    end

    it "returns false when current state is before the check state" do
      expect(state_machine.state_equal_or_after?("instance_meta_fetching")).to be false
    end
  end

  describe "#state_equal_or_before?" do
    it "returns true when current state is equal to the check state" do
      expect(state_machine.state_equal_or_before?("initial")).to be true
    end

    it "returns true when current state is before the check state" do
      expect(state_machine.state_equal_or_before?("instance_meta_fetching")).to be true
    end

    it "returns false when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.state_equal_or_before?("initial")).to be false
    end
  end

  describe "#state_before?" do
    it "returns true when current state is before the check state" do
      expect(state_machine.state_before?("instance_meta_fetching")).to be true
    end

    it "returns false when current state is equal to the check state" do
      expect(state_machine.state_before?("initial")).to be false
    end

    it "returns false when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.state_before?("initial")).to be false
    end
  end

  describe "#state_after?" do
    it "returns true when current state is after the check state" do
      state_machine.transition_to!("instance_meta_fetching")

      expect(state_machine.state_after?("initial")).to be true
    end

    it "returns false when current state is equal to the check state" do
      expect(state_machine.state_after?("initial")).to be false
    end

    it "returns false when current state is before the check state" do
      expect(state_machine.state_after?("instance_meta_fetching")).to be false
    end
  end

  describe "#deletable?" do
    context "when in running states" do
      %w[instance_meta_fetching projects_meta_fetching importing import_aborting reverting finalizing]
        .each do |running_state|
        it "returns false when in #{running_state} state" do
          transition_to_state(running_state)

          expect(state_machine.deletable?).to be false
        end
      end
    end

    context "when in non-deletable states" do
      %w[imported import_error revert_error].each do |non_deletable_state|
        it "returns false when in #{non_deletable_state} state" do
          transition_to_state(non_deletable_state)

          expect(state_machine.deletable?).to be false
        end
      end
    end

    context "when in deletable states" do
      %w[initial instance_meta_done instance_meta_error configuring projects_meta_done
         projects_meta_error reverted finalizing_done finalizing_error].each do |deletable_state|
        it "returns true when in #{deletable_state} state" do
          transition_to_state(deletable_state)

          expect(state_machine.deletable?).to be true
        end
      end
    end
  end

  private

  # Happy path through the machine; every other state branches off one of these.
  def main_path
    %w[instance_meta_fetching instance_meta_done configuring
       projects_meta_fetching projects_meta_done importing imported]
  end

  def branch_parents
    {
      "instance_meta_error" => "instance_meta_fetching",
      "projects_meta_error" => "projects_meta_fetching",
      "import_error" => "importing",
      "import_aborting" => "importing",
      "finalizing" => "imported",
      "finalizing_error" => "finalizing",
      "finalizing_done" => "finalizing",
      "reverting" => "imported",
      "revert_error" => "reverting",
      "reverted" => "reverting"
    }
  end

  def path_to(target_state)
    return [] if target_state == "initial"

    index = main_path.index(target_state)
    return main_path[0..index] if index

    parent = branch_parents.fetch(target_state) { raise "No path defined for state: #{target_state}" }
    path_to(parent) + [target_state]
  end

  def transition_to_state(target_state)
    path_to(target_state).each do |state|
      jira_import.transition_to!(state) unless jira_import.current_state == state
    end
  end

  def stub_batch_jobs(jobs)
    batch_record = instance_double(GoodJob::BatchRecord, jobs:)
    allow(GoodJob::Batch).to receive(:find).and_return(instance_double(GoodJob::Batch, _record: batch_record))
  end
end
