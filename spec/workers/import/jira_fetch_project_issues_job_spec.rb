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

RSpec.describe Import::JiraFetchProjectIssuesJob do
  include_context "with jira project import data"

  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:jira_issue_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/issue.json").read) }
  let(:api_error) { Import::JiraClient::ApiError.new("boom", status: 404, response_body: "", response_headers: {}) }

  def worklogs(count)
    Array.new(count) { |index| { "id" => index.to_s } }
  end

  def issue(id, worklogs:, total: worklogs.size)
    {
      "id" => id,
      "key" => "DPPP-#{id}",
      "fields" => {
        "worklog" => {
          "total" => total,
          "worklogs" => worklogs
        }
      }
    }
  end

  def stored_worklogs(origin_id)
    Import::JiraIssue.find_by!(jira_import:, origin_id:).payload.dig("fields", "worklog", "worklogs")
  end

  describe "#perform" do
    subject(:perform) { described_class.perform_now(jira_import.id, jira_project.id) }

    before { allow(Import::JiraClient).to receive(:new).and_return(jira_client) }

    context "with worklogs" do
      let(:issues) do
        [
          issue("10001", worklogs: worklogs(2)),
          issue("10002", worklogs: worklogs(20), total: 22)
        ]
      end

      before do
        allow(jira_client).to receive(:issues).and_return({ "issues" => issues, "total" => 2 }, { "issues" => [], "total" => 2 })
        allow(jira_client).to receive(:issue_worklogs).and_return("total" => 22, "worklogs" => worklogs(22))
      end

      it "stores the worklogs Jira returned with the issue without fetching them again" do
        perform

        expect(stored_worklogs("10001").size).to eq(2)
        expect(jira_client).not_to have_received(:issue_worklogs).with("10001")
      end

      it "fetches all worklogs with an extra request when the issue has more than 20" do
        perform

        expect(jira_client).to have_received(:issue_worklogs).with("10002").once
        expect(stored_worklogs("10002").size).to eq(22)
      end
    end

    context "when an issue has watchers" do
      let(:watched_issue_payload) { jira_issue_payload.deep_merge("fields" => { "watches" => { "watchCount" => 2 } }) }
      let(:unwatched_issue_payload) do
        jira_issue_payload.deep_merge(
          "id" => "10406", "key" => "DPPP-7",
          "fields" => { "watches" => { "watchCount" => 0 } }
        )
      end
      let(:watchers_payload) { { "watchers" => watchers, "watchCount" => 2 } }
      let(:watchers) { [{ "key" => "JIRAUSER666" }, { "key" => "JIRAUSER13" }] }

      before do
        allow(jira_client).to receive(:issues)
          .with(hash_including(start_at: 0))
          .and_return({ "issues" => [watched_issue_payload, unwatched_issue_payload], "total" => 2 })
        allow(jira_client).to receive(:issues)
          .with(hash_including(start_at: 2))
          .and_return({ "issues" => [] })
      end

      it "retrieves all issues paginated and stores them including information about watchers" do
        allow(jira_client).to receive(:issue_watchers).with("10405").and_return(watchers_payload)

        expect { perform }.to change(Import::JiraIssue, :count).by(2)
        expect(jira_client).to have_received(:issues).twice

        watched, unwatched = Import::JiraIssue.order(:origin_id)
        expect(watched.payload.fetch("watchers")).to eq(watchers)
        expect(unwatched.payload).not_to have_key("watchers")
      end

      it "leaves the watchers empty if they cannot be found" do
        allow(jira_client).to receive(:issue_watchers).with("10405").and_raise(api_error)

        expect { perform }.to change(Import::JiraIssue, :count).by(2)

        watched, unwatched = Import::JiraIssue.order(:origin_id)
        expect(watched.payload.fetch("watchers")).to be_empty
        expect(unwatched.payload).not_to have_key("watchers")
      end

      it "raises for any unexpected response when retrieving watchers" do
        error = Import::JiraClient::ApiError.new("boom", status: 401, response_body: {}, response_headers: {})
        allow(jira_client).to receive(:issue_watchers).and_raise(error)

        expect { perform }.to raise_error(error).and not_change(Import::JiraIssue, :count)
      end
    end

    context "when there are no issues" do
      before { allow(jira_client).to receive(:issues).and_return({ "issues" => [] }) }

      it "does not create any jira issues" do
        expect { perform }.to not_change(Import::JiraIssue, :count)
        expect(jira_client).to have_received(:issues)
          .with(jql: "project = 'DPPP' ORDER BY id ASC", max_results: 50, start_at: 0)
      end
    end
  end
end
