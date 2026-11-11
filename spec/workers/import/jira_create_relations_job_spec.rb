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

RSpec.describe Import::JiraCreateRelationsJob,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"

  before do
    create_project_role
    create_project
    create_work_packages
  end

  describe "#perform" do
    context "with a custom link type (Tests)" do
      let(:linked_issue_payload) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["id"] = "10019"
          payload["key"] = "KIWNEU1-1"
          payload["fields"]["summary"] = "Gather kiwi recipes"
          payload["fields"]["issuelinks"] = []
        end
      end

      let!(:jira_linked_issue) do
        create(:jira_issue,
               jira_import:,
               origin_id: "10019",
               jira_project:,
               payload: linked_issue_payload)
      end

      before do
        Import::JiraCreateProjectWorkPackagesJob.perform_now(jira_import.id, jira_project.id)
      end

      it "creates a 'relates' relation with description for unmapped link types" do
        # jira_issue (DPPP-6) has inwardIssue pointing to jira_linked_issue (KIWNEU1-1)
        # with type "Tests" and inward label "tested by"
        # This means: "KIWNEU1-1 tests DPPP-6" (or "DPPP-6 is tested by KIWNEU1-1")
        expect { create_relations }.to change(Relation, :count).by(1)

        current_wp = jira_import.find_op_leg(jira_issue)
        linked_wp = jira_import.find_op_leg(jira_linked_issue)

        relation = Relation.last
        expect(relation.relation_type).to eq(Relation::TYPE_RELATES)
        expect(relation.description).to eq("#{current_wp.formatted_id} tested by #{linked_wp.formatted_id}")
        expect(relation.from_id).to eq(linked_wp.id)
        expect(relation.to_id).to eq(current_wp.id)
      end

      it "is idempotent - running twice does not create duplicate relations" do
        create_relations

        expect { create_relations }.not_to change(Relation, :count)
      end
    end

    context "with a Blocks link type" do
      let(:blocked_issue_payload) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["id"] = "10500"
          payload["key"] = "DPPP-10"
          payload["fields"]["summary"] = "Blocked issue"
          payload["fields"]["issuelinks"] = []
        end
      end

      let!(:jira_blocked_issue) do
        create(:jira_issue,
               jira_import:,
               origin_id: "10500",
               jira_project:,
               payload: blocked_issue_payload)
      end

      let(:issue_with_blocks_link) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["fields"]["issuelinks"] = [
            {
              "id" => "10300",
              "type" => {
                "id" => "10000",
                "name" => "Blocks",
                "inward" => "is blocked by",
                "outward" => "blocks"
              },
              "outwardIssue" => {
                "id" => "10500",
                "key" => "DPPP-10",
                "fields" => {
                  "summary" => "Blocked issue"
                }
              }
            }
          ]
        end
      end

      before do
        jira_issue.update!(payload: issue_with_blocks_link)
        Import::JiraCreateProjectWorkPackagesJob.perform_now(jira_import.id, jira_project.id)
      end

      it "creates a 'blocks' relation with correct direction" do
        # jira_issue (DPPP-6) has outwardIssue pointing to jira_blocked_issue (DPPP-10)
        # with type "Blocks" and outward label "blocks"
        # This means: "DPPP-6 blocks DPPP-10"
        expect { create_relations }.to change(Relation, :count).by(1)

        blocker_wp = jira_import.find_op_leg(jira_issue)
        blocked_wp = jira_import.find_op_leg(jira_blocked_issue)

        relation = Relation.last
        expect(relation.canonical_type).to eq(Relation::TYPE_BLOCKS)
        expect(relation.description).to be_nil
        expect(relation.from_id).to eq(blocker_wp.id)
        expect(relation.to_id).to eq(blocked_wp.id)
      end
    end

    context "with a Duplicate link type" do
      let(:duplicate_issue_payload) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["id"] = "10501"
          payload["key"] = "DPPP-11"
          payload["fields"]["summary"] = "Duplicate issue"
          payload["fields"]["issuelinks"] = []
        end
      end

      let!(:jira_duplicate_issue) do
        create(:jira_issue,
               jira_import:,
               origin_id: "10501",
               jira_project:,
               payload: duplicate_issue_payload)
      end

      let(:issue_with_duplicate_link) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["fields"]["issuelinks"] = [
            {
              "id" => "10400",
              "type" => {
                "id" => "10001",
                "name" => "Duplicate",
                "inward" => "is duplicated by",
                "outward" => "duplicates"
              },
              "outwardIssue" => {
                "id" => "10501",
                "key" => "DPPP-11",
                "fields" => {
                  "summary" => "Duplicate issue"
                }
              }
            }
          ]
        end
      end

      before do
        jira_issue.update!(payload: issue_with_duplicate_link)
        Import::JiraCreateProjectWorkPackagesJob.perform_now(jira_import.id, jira_project.id)
      end

      it "creates a 'duplicates' relation with correct direction" do
        # jira_issue (DPPP-6) has outwardIssue pointing to jira_duplicate_issue (DPPP-11)
        # with type "Duplicate" and outward label "duplicates"
        # This means: "DPPP-6 duplicates DPPP-11"
        expect { create_relations }.to change(Relation, :count).by(1)

        current_wp = jira_import.find_op_leg(jira_issue)
        duplicate_wp = jira_import.find_op_leg(jira_duplicate_issue)

        relation = Relation.last
        expect(relation.canonical_type).to eq(Relation::TYPE_DUPLICATES)
        expect(relation.description).to be_nil
        expect(relation.from_id).to eq(current_wp.id)
        expect(relation.to_id).to eq(duplicate_wp.id)
      end
    end

    context "when linked issue is not in the import" do
      it "logs a warning and does not create a relation" do
        allow(Rails.logger).to receive(:warn)

        expect { create_relations }.not_to change(Relation, :count)

        expect(Rails.logger).to have_received(:warn).with(/target work package not found/)
      end
    end

    context "when issue has no links" do
      before do
        jira_issue.update!(payload: jira_issue_payload.deep_dup.tap { |p| p["fields"]["issuelinks"] = [] })
      end

      it "does not create any relations" do
        expect { create_relations }.not_to change(Relation, :count)
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
      end

      it "stops iterating and reports the abortion" do
        expect { create_relations }.to raise_error(Import::ProgressableJob::AbortionError)
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

    context "when there are issues with links" do
      let(:issue2_payload) do
        jira_issue_payload.deep_dup.tap do |payload|
          payload["id"] = "10406"
          payload["key"] = "DPPP-8"
        end
      end

      let!(:jira_issue2) do
        create(:jira_issue,
               jira_import:,
               origin_id: "10406",
               jira_project:,
               payload: issue2_payload)
      end

      it "calculates progress based on cursor position" do
        jira_import.set_job_cursor(job, jira_issue.id)

        progress = job.progress
        expect(progress[:total]).to eq(2)
        expect(progress[:current]).to eq(1)
        expect(progress[:percentage]).to eq(50.0)
      end

      it "returns 100% when all issues are processed" do
        jira_import.set_job_cursor(job, jira_issue2.id)

        progress = job.progress
        expect(progress[:total]).to eq(2)
        expect(progress[:current]).to eq(2)
        expect(progress[:percentage]).to eq(100.0)
      end
    end

    context "when there are no issues with links" do
      before do
        jira_issue.update!(payload: jira_issue_payload.deep_dup.tap { |p| p["fields"]["issuelinks"] = [] })
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
