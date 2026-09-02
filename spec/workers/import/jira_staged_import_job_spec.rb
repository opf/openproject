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

RSpec.describe Import::JiraStagedImportJob, with_good_job_batches: [Import::JiraStagedImportJob] do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:, projects: selected_projects) }
  let(:selected_projects) { [{ "id" => "10012", "key" => "DPPP", "name" => "Demo project" }] }

  let(:stage) { nil }
  let(:discarded) { false }

  let(:batch) do
    batch_record = GoodJob::BatchRecord.create!(
      serialized_properties: { jira_import_id: jira_import.id, stage: },
      on_finish: "Import::JiraStagedImportJob",
      finished_at: Time.current,
      discarded_at: discarded ? Time.current : nil
    )
    GoodJob::Batch.new(_record: batch_record)
  end

  subject(:run_callback) { described_class.perform_now(batch, {}) }

  def transition_to_importing
    allow(Import::JiraInstanceMetaDataJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraInstanceMetaDataJob, job_id: "instance-meta-job-id"))
    allow(Import::JiraProjectsMetaDataJob)
      .to receive(:perform_later)
      .and_return(instance_double(Import::JiraProjectsMetaDataJob, job_id: "projects-meta-job-id"))

    jira_import.transition_to!(:instance_meta_fetching)
    jira_import.transition_to!(:instance_meta_done)
    jira_import.transition_to!(:configuring)
    jira_import.transition_to!(:projects_meta_fetching)
    jira_import.transition_to!(:projects_meta_done)
    jira_import.transition_to!(:importing)
  end

  before { transition_to_importing }

  context "when batch succeeded" do
    let(:discarded) { false }

    describe "stage nil (initial stage)" do
      let(:stage) { nil }

      it "enqueues fetch jobs for issue types, priorities, statuses, and projects" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchIssueTypesJob").count).to eq(1)
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchPrioritiesJob").count).to eq(1)
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchStatusesJob").count).to eq(1)
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectsJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_1" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchIssueTypesJob").last.labels).to include("stage_1")
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchPrioritiesJob").last.labels).to include("stage_1")
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchStatusesJob").last.labels).to include("stage_1")
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectsJob").last.labels).to include("stage_1")
      end
    end

    describe "stage 1" do
      let(:stage) { 1 }
      let!(:jira_project) do
        create(:jira_project, jira_import:, origin_id: "10012",
                              payload: { "id" => "10012", "key" => "DPPP", "name" => "Demo project" })
      end

      it "enqueues one fetch issues job per selected project" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectIssuesJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_2" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectIssuesJob").last.labels).to include("stage_2")
      end

      context "with multiple selected projects" do
        let(:selected_projects) do
          [
            { "id" => "10012", "key" => "DPPP", "name" => "Demo project" },
            { "id" => "10013", "key" => "TEST", "name" => "Test project" }
          ]
        end
        let!(:jira_project2) do
          create(:jira_project, jira_import:, origin_id: "10013",
                                payload: { "id" => "10013", "key" => "TEST", "name" => "Test project" })
        end

        it "enqueues a fetch job for each selected project" do
          run_callback

          expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectIssuesJob").count).to eq(2)
        end
      end

      context "when a project exists but is not selected for import" do
        let!(:unselected_project) do
          create(:jira_project, jira_import:, origin_id: "99999",
                                payload: { "id" => "99999", "key" => "SKIP", "name" => "Skipped project" })
        end

        it "does not enqueue a fetch job for the unselected project" do
          run_callback

          expect(GoodJob::Job.where(job_class: "Import::JiraFetchProjectIssuesJob").count).to eq(1)
        end
      end
    end

    describe "stage 2" do
      let(:stage) { 2 }

      it "enqueues fetch users and custom fields jobs" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchUsersJob").count).to eq(1)
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchCustomFieldJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_3" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraFetchUsersJob").last.labels).to include("stage_3")
        expect(GoodJob::Job.where(job_class: "Import::JiraFetchCustomFieldJob").last.labels).to include("stage_3")
      end
    end

    describe "stage 3" do
      let(:stage) { 3 }

      it "enqueues the create users job" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateUsersJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_4" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateUsersJob").last.labels).to include("stage_4")
      end
    end

    describe "stage 4" do
      let(:stage) { 4 }

      it "enqueues the project role and custom fields creation jobs" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectRoleJob").count).to eq(1)
        expect(GoodJob::Job.where(job_class: "Import::JiraCreateCustomFieldsJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_5" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectRoleJob").last.labels).to include("stage_5")
        expect(GoodJob::Job.where(job_class: "Import::JiraCreateCustomFieldsJob").last.labels).to include("stage_5")
      end
    end

    describe "stage 5" do
      let(:stage) { 5 }
      let!(:jira_project) do
        create(:jira_project, jira_import:, origin_id: "10012",
                              payload: { "id" => "10012", "key" => "DPPP", "name" => "Demo project" })
      end

      it "enqueues one create project job per selected project" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_6" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectJob").last.labels).to include("stage_6")
      end
    end

    describe "stage 6" do
      let(:stage) { 6 }
      let!(:jira_project) do
        create(:jira_project, jira_import:, origin_id: "10012",
                              payload: { "id" => "10012", "key" => "DPPP", "name" => "Demo project" })
      end

      it "enqueues one create work packages job per selected project" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectWorkPackagesJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_7" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectWorkPackagesJob").last.labels).to include("stage_7")
      end
    end

    describe "stage 7" do
      let(:stage) { 7 }
      let!(:jira_project) do
        create(:jira_project, jira_import:, origin_id: "10012",
                              payload: { "id" => "10012", "key" => "DPPP", "name" => "Demo project" })
      end

      it "enqueues one create attachments job per selected project" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectWorkPackageAttachmentsJob").count).to eq(1)
      end

      it "labels enqueued jobs with stage_8" do
        run_callback

        expect(GoodJob::Job.where(job_class: "Import::JiraCreateProjectWorkPackageAttachmentsJob").last.labels)
          .to include("stage_8")
      end
    end

    describe "stage 8 (final stage)" do
      let(:stage) { 8 }

      it "does not enqueue any more jobs" do
        expect { run_callback }.not_to change(GoodJob::Job, :count)
      end

      it "transitions the import to the imported state" do
        run_callback

        expect(jira_import.reload.current_state).to eq("imported")
      end
    end
  end

  context "when batch has been discarded" do
    let(:stage) { 3 }
    let(:discarded) { true }

    it "does not enqueue any jobs" do
      expect { run_callback }.not_to change(GoodJob::Job, :count)
    end

    it "transitions the import to import_error state" do
      run_callback

      expect(jira_import.reload.current_state).to eq("import_error")
    end
  end
end
