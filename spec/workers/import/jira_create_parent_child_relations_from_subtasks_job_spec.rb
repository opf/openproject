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

RSpec.describe Import::JiraCreateParentChildRelationsFromSubtasksJob,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"

  let(:subtask_issue_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/subtask_issue.json").read) }

  let!(:jira_subtask_issue_type) do
    create(:jira_issue_type,
           jira_import:,
           origin_id: "10003",
           payload: { "id" => "10003", "name" => "Sub-task", "subtask" => true })
  end

  let!(:jira_subtask_status) do
    create(:jira_status,
           jira_import:,
           origin_id: "10003",
           payload: { "id" => "10003", "name" => "TO DO" })
  end

  let!(:jira_subtask_priority) do
    create(:jira_priority,
           jira_import:,
           origin_id: "3",
           payload: { "id" => "3", "name" => "Medium" })
  end

  let!(:jira_subtask_issue) do
    create(:jira_issue,
           jira_import:,
           origin_id: "11400",
           jira_project:,
           payload: subtask_issue_payload)
  end

  before do
    create_project_role
    create_project
    create_work_packages
  end

  describe "#perform" do
    it "sets the parent_id on the subtask work package" do
      parent_wp = WorkPackage.find("DPPP-6")
      child_wp = WorkPackage.find("DPPP-7")

      expect(child_wp.parent_id).to be_nil

      create_parent_child_relations

      child_wp.reload
      expect(child_wp.parent_id).to eq(parent_wp.id)
      expect(child_wp.parent).to eq(parent_wp)
    end

    it "does not modify work packages without a parent field" do
      parent_wp = WorkPackage.find("DPPP-6")

      create_parent_child_relations

      parent_wp.reload
      expect(parent_wp.parent_id).to be_nil
    end

    it "is idempotent - running twice does not break anything" do
      create_parent_child_relations
      child_wp = WorkPackage.find("DPPP-7")
      parent_id = child_wp.parent_id

      expect { create_parent_child_relations }.not_to raise_error

      child_wp.reload
      expect(child_wp.parent_id).to eq(parent_id)
    end

    context "when the parent Jira issue does not exist" do
      before do
        # Point to a non-existent parent
        modified_payload = subtask_issue_payload.deep_dup
        modified_payload["fields"]["parent"]["id"] = "99999"
        jira_subtask_issue.update!(payload: modified_payload)
      end

      it "logs a warning and continues without error" do
        allow(Rails.logger).to receive(:warn)

        expect { create_parent_child_relations }.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(/Parent Jira issue 99999 not found/)
      end

      it "does not set the parent on the child work package" do
        create_parent_child_relations

        child_wp = WorkPackage.find("DPPP-7")
        expect(child_wp.parent_id).to be_nil
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
      end

      it "stops iterating and reports the abortion" do
        expect { create_parent_child_relations }.to raise_error(Import::ProgressableJob::AbortionError)
      end
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id, jira_project.id) }

    context "when no cursor is set" do
      it "returns zeros" do
        expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
      end
    end

    context "when there are subtasks" do
      let!(:jira_subtask_issue2) do
        payload = subtask_issue_payload.deep_dup
        payload["id"] = "11401"
        payload["key"] = "DPPP-8"
        create(:jira_issue,
               jira_import:,
               origin_id: "11401",
               jira_project:,
               payload:)
      end

      it "calculates progress based on cursor position" do
        jira_import.set_job_cursor(job, jira_subtask_issue.id)

        progress = job.progress
        expect(progress[:total]).to eq(2)
        expect(progress[:current]).to eq(1)
        expect(progress[:percentage]).to eq(50.0)
      end

      it "returns 100% when all subtasks are processed" do
        jira_import.set_job_cursor(job, jira_subtask_issue2.id)

        progress = job.progress
        expect(progress[:total]).to eq(2)
        expect(progress[:current]).to eq(2)
        expect(progress[:percentage]).to eq(100.0)
      end
    end

    context "when there are no subtasks" do
      before do
        jira_subtask_issue.destroy!
      end

      it "returns zeros" do
        progress = job.progress
        expect(progress[:total]).to eq(0)
        expect(progress[:current]).to eq(0)
        expect(progress[:percentage]).to eq(0)
      end
    end
  end
end
