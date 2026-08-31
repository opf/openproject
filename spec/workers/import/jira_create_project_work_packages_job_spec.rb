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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

# The import only produces valid data with semantic identifiers enabled: Jira project keys are
# uppercase, which Projects::Identifier rejects in classic mode.
RSpec.describe Import::JiraCreateProjectWorkPackagesJob,
               :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"

  describe "#perform" do
    context "when importing a full project with issues and comments" do
      before do
        create_project_role
        create_project
      end

      it "updates the project work package sequence counter to the highest imported sequence number" do
        create_work_packages

        expect(Project.find_by!(identifier: jira_project_key).wp_sequence_counter).to eq(6)
      end

      it "creates the work package with correct attributes" do
        create_work_packages

        work_package = WorkPackage.find("DPPP-6")
        expect(work_package.type.name).to eq("Bug")
        expect(work_package.due_date.to_s).to eq("2031-05-29")
        expect(work_package.estimated_hours).to eq(120.0)
        expect(work_package.remaining_hours).to eq(11.0)
        expect(work_package.status.name).to eq("In Progress")
        expect(work_package.priority.name).to eq("Highest")
        expect(work_package.assigned_to).to eq(op_user)
        expect(work_package.identifier).to eq("DPPP-6")
        expect(work_package.sequence_number).to eq(6)
        # we have both project-based aliases (DP and DPPP)
        # and aliases that come from issue being moved from one project to another (KIWNEU1)
        expect(work_package.semantic_aliases.pluck(:identifier).sort).to eq(["DP-6", "DPPP-1", "DPPP-6", "KIWNEU1-8"])
      end

      # rubocop:disable Layout/LineLength
      # rubocop:disable RSpec/ExampleLength
      it "creates appropriate comments on the work package" do
        create_work_packages

        work_package = WorkPackage.find("DPPP-6")

        # the 18th journal is added later, when Import::JiraCreateProjectWorkPackageAttachmentsJob
        # attaches the file referenced by the "Attachment" changelog item asserted below
        expect(work_package.journals.count).to be 17
        expect(work_package.journals.where(notes: "Demo comment 1\n\n").count).to be 1
        expect(work_package.journals.where(notes: "Demo comment 2").count).to be 1
        expect(work_package.journals.where(notes: "Parampampam").count).to be 1
        cause1 = { "type" => "import",
                   "import_history" => [{
                     "items" => [{ "to" => "3", "from" => "10003", "field" => "status", "toString" => "In Progress", "fieldtype" => "jira",
                                   "fromString" => "To Do" }], "author_name" => "Pavel Balashou"
                   }] }
        expect(work_package.journals.where(cause: cause1).count).to be 1
        cause2 = { "type" => "import",
                   "import_history" => [{
                     "items" => [{ "to" => "10100", "from" => nil, "field" => "Attachment", "toString" => "airplane-wing-over-cloudy-sky.jpg",
                                   "fieldtype" => "jira", "fromString" => nil }], "author_name" => "Pavel Balashou"
                   }] }
        expect(work_package.journals.where(cause: cause2).count).to be 1
        notes1 = "## Environment\n| Field | Details |\n| --- | --- |\n| Environment | Production |\n| --- | --- |\n| Browser | Chrome 120.0 |\n| --- | --- |\n| OS | Windows 11 |\n| --- | --- |\n| App Version | v3.2.1 |\n| --- | --- |"
        expect(work_package.journals.where(notes: notes1).count).to be 1
        cause3 = { "type" => "import",
                   "import_history" => [{
                     "items" => [{ "to" => "1", "from" => "3", "field" => "priority", "toString" => "Highest", "fieldtype" => "jira",
                                   "fromString" => "Medium" }], "author_name" => "Pavel Balashou"
                   }] }
        expect(work_package.journals.where(cause: cause3).count).to be 1
        cause4 = { "type" => "import",
                   "import_history" => [{
                     "items" => [{ "to" => "10100", "from" => nil, "field" => "RemoteIssueLink",
                                   "toString" => "This issue links to \"123123123 (Web Link)\"", "fieldtype" => "jira", "fromString" => nil }], "author_name" => "Pavel Balashou"
                   }] }
        expect(work_package.journals.where(cause: cause4).count).to be 1
        cause5 = { "type" => "import",
                   "import_history" => [{
                     "items" => [{ "to" => nil, "from" => nil, "field" => "description",
                                   "toString" => "#  \n# Demo Issue\n## Summary\n\n\nThis is a demonstration issue created to showcase the structure and formatting of a typical Jira ticket using wiki markup.\n## Description\n\n\nThis issue serves as a **template** and *reference example* for how to write well-structured Jira descriptions.\n## Steps to Reproduce\n1. Navigate to the application homepage\n1. Log in with valid credentials\n1. Click on the **Settings** icon in the top-right corner\n1. Select *Account Preferences* from the dropdown menu\n1. Observe the unexpected behavior\n\n\n## Expected Behavior\n\n\nThe application should display the account preferences page with all user settings loaded correctly.\n## Actual Behavior\n\n\nThe page fails to load and displays the following error:\n```java\nError 500: Internal Server Error\nFailed to retrieve user preferences. Please try again later.\n```\n## Environment\n| Field | Details |\n| --- | --- |\n| Environment | Production |\n| --- | --- |\n| Browser | Chrome 120.0 |\n| --- | --- |\n| OS | Windows 11 |\n| --- | --- |\n| App Version | v3.2.1 |\n| --- | --- |\n## Attachments / Notes\n- Screenshot of the error has been attached\n- Issue occurs **consistently** — reproduced 5/5 times\n- Related to ticket: [DEMO-101]\n\n\n## Priority & Impact\n\n\n**High Priority** — Affects all users attempting to access account settings.", "fieldtype" => "jira", "fromString" => "# Demo Issue\n\n\n## Summary\nThis is a demonstration issue created to showcase the structure and formatting of a typical Jira ticket using wiki markup.\n\n\n## Description\nThis issue serves as a **template** and *reference example* for how to write well-structured Jira descriptions.\n\n\n## Steps to Reproduce\n1. Navigate to the application homepage\n1. Log in with valid credentials\n1. Click on the **Settings** icon in the top-right corner\n1. Select *Account Preferences* from the dropdown menu\n1. Observe the unexpected behavior\n\n\n## Expected Behavior\nThe application should display the account preferences page with all user settings loaded correctly.\n\n\n## Actual Behavior\nThe page fails to load and displays the following error:\n```\nError 500: Internal Server Error\nFailed to retrieve user preferences. Please try again later.\n```\n\n\n## Environment\n| Field | Details |\n| --- | --- |\n| Environment | Production |\n| --- | --- |\n| Browser | Chrome 120.0 |\n| --- | --- |\n| OS | Windows 11 |\n| --- | --- |\n| App Version | v3.2.1 |\n| --- | --- |\n\n\n## Attachments / Notes\n- Screenshot of the error has been attached\n- Issue occurs **consistently** — reproduced 5/5 times\n- Related to ticket: [DEMO-101]\n\n\n## Priority & Impact\n**High Priority** — Affects all users attempting to access account settings." }], "author_name" => "Dominic Bräunlein"
                   }] }
        expect(work_package.journals.where(cause: cause5).count).to be 1
      end
      # rubocop:enable RSpec/ExampleLength
      # rubocop:enable Layout/LineLength

      it "creates references for imported entities" do
        expect { create_work_packages }
          .to change(Import::JiraOpenProjectReference, :count).by_at_least(4)
      end

      context "if priority is nil or hidden in jira filed configuration" do
        let(:jira_issue_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/issue_without_priority.json").read) }

        it "creates work_packge with default priority if it exists" do
          priority = create(:default_priority)
          create_work_packages

          work_package = WorkPackage.find("DPPP-6")
          expect(work_package.priority).to eq(priority)
        end

        it "raises an error if default priority does not exist" do
          expect { create_work_packages }
            .to raise_error("Create a priority. OpenProject work package requires a priority!")
        end
      end

      context "when there is issue from a different import run with the same jira_project_id" do
        let(:other_jira_import) do
          create(:jira_import,
                 jira:,
                 author:,
                 projects: [{ "id" => jira_project_id, "key" => jira_project_key, "name" => jira_project_name }])
        end

        let(:other_issue_payload) do
          jira_issue_payload.deep_dup.tap do |payload|
            payload["id"] = "99999"
            payload["key"] = "#{jira_project_key}-1123"
            payload["fields"]["summary"] = "ISSUE 1123"
          end
        end

        let!(:other_jira_issue) do
          create(:jira_issue,
                 jira_import: other_jira_import,
                 origin_id: "99999",
                 jira_project:,
                 payload: other_issue_payload)
        end

        it "only imports issues fetched in the current import run" do
          create_work_packages

          expect(WorkPackage.find("DPPP-6")).to be_present
          expect { WorkPackage.find("DPPP-1123") }.to raise_error(ActiveRecord::RecordNotFound)
          expect(WorkPackage.count).to eq(1)
        end
      end

      context "when the import is aborting" do
        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Import::JiraImport)
            .to receive(:in_state?).with(:import_aborting).and_return(true)
          # rubocop:enable RSpec/AnyInstance
        end

        it "stops iterating and reports the abortion" do
          expect { create_work_packages }.to raise_error(Import::ProgressableJob::AbortionError)
        end
      end
    end
  end
end
