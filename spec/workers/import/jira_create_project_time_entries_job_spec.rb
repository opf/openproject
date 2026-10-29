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

# The import only produces valid data with semantic identifiers enabled: Jira project keys are
# uppercase, which Projects::Identifier rejects in classic mode.
RSpec.describe Import::JiraCreateProjectTimeEntriesJob,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with a jira demo issue"

  describe "#perform" do
    let(:worklog) do
      {
        "id" => "10000",
        "author" => { "key" => "JIRAUSER10000" },
        "comment" => "Reproduced the *bug*",
        "created" => "2026-03-19T08:00:00.000+0000",
        "updated" => "2026-03-19T08:15:00.000+0000",
        "started" => "2026-03-18T23:30:00.000+0000",
        "timeSpentSeconds" => 5400
      }
    end
    let(:worklogs) { [worklog] }
    let(:jira_issue_payload) do
      super().tap { |payload| payload["fields"]["worklog"]["worklogs"] = worklogs }
    end

    let(:op_user) { super().tap { |user| user.pref.update!(time_zone: "Europe/Berlin") } }
    let(:work_package) { WorkPackage.find("DPPP-6") }

    before do
      create_project_role
      create_project
      create_work_packages
    end

    it "creates a time entry on the work package for every worklog, with Jira's timestamps" do
      create_time_entries

      time_entry = work_package.time_entries.sole
      expect(time_entry).to have_attributes(
        project: work_package.project,
        user: op_user,
        logged_by: op_user,
        hours: 1.5,
        comments: "Reproduced the *bug*",
        activity: nil,
        created_at: Time.zone.parse(worklog["created"]),
        updated_at: Time.zone.parse(worklog["updated"])
      )
      expect(time_entry.journals.sole).to have_attributes(
        user: op_user,
        created_at: Time.zone.parse(worklog["updated"])
      )
    end

    it "books the time on the date and at the time the author started it in their own time zone" do
      create_time_entries

      expect(work_package.time_entries.sole).to have_attributes(
        spent_on: Date.new(2026, 3, 19),
        start_time: 30,
        time_zone: "Europe/Berlin"
      )
    end

    it "adds the worklog author as a project member who can see the spent time" do
      create_time_entries

      expect(work_package.project.users).to include(op_user)
      expect(work_package.spent_hours(op_user)).to eq(1.5)
    end

    it "leaves the work package and its activity untouched" do
      expect { create_time_entries }
        .not_to change { [work_package.reload.updated_at, work_package.journals.count] }
    end

    context "when the author was not imported" do
      let(:worklog) { super().merge("author" => { "key" => "JIRAUSER99999" }) }

      it "logs the time as the deleted user" do
        create_time_entries

        expect(work_package.time_entries.sole).to have_attributes(user: DeletedUser.first, logged_by: DeletedUser.first)
      end
    end

    context "when the comment exceeds what a time entry can hold" do
      let(:worklog) { super().merge("comment" => "a" * (TimeEntry::COMMENTS_MAX_LENGTH + 1)) }

      it "truncates the comment" do
        create_time_entries

        expect(work_package.time_entries.sole.comments.length).to eq(TimeEntry::COMMENTS_MAX_LENGTH)
      end

      it "logs that the comment was shortened" do
        allow(Rails.logger).to receive(:warn)

        create_time_entries

        expect(Rails.logger).to have_received(:warn)
          .with("Shortening the worklog comment from #{TimeEntry::COMMENTS_MAX_LENGTH + 1} to " \
                "#{TimeEntry::COMMENTS_MAX_LENGTH} characters")
      end
    end

    context "when the issue has no worklogs" do
      let(:worklogs) { [] }

      it "creates no time entries" do
        expect { create_time_entries }.not_to change(TimeEntry, :count)
      end
    end

    context "when resumed after the issue was already processed" do
      it "does not create the time entries again" do
        create_time_entries

        expect { create_time_entries }.not_to change(TimeEntry, :count)
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
      end

      it "stops iterating and reports the abortion" do
        expect { create_time_entries }.to raise_error(Import::ProgressableJob::AbortionError)
      end
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id, jira_project.id) }

    let(:jira_issue_payload) do
      super().tap { |payload| payload["fields"]["worklog"]["worklogs"] = [{ "id" => "10000" }] }
    end

    it "returns zeros when no cursor is set" do
      expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
    end

    it "calculates progress over the issues with worklogs" do
      create(:jira_issue, jira_import:, jira_project:,
                          payload: { "key" => "DPPP-7", "fields" => { "worklog" => { "worklogs" => [] } } })
      jira_import.set_job_cursor(job, jira_issue.id)

      expect(job.progress).to eq({ current: 1, total: 1, percentage: 100.0 })
    end
  end
end
