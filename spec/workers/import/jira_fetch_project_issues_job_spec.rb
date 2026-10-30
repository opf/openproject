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

  subject(:fetch_issues) { described_class.perform_now(jira_import.id, jira_project.id) }

  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:issues) do
    [
      issue("10001", worklogs: worklogs(2)),
      issue("10002", worklogs: worklogs(20), total: 22)
    ]
  end

  before do
    allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive(:issues).and_return({ "issues" => issues, "total" => 2 }, { "issues" => [], "total" => 2 })
    allow(jira_client).to receive(:issue_worklogs).and_return("total" => 22, "worklogs" => worklogs(22))
  end

  describe "#perform" do
    it "stores the worklogs Jira returned with the issue without fetching them again" do
      fetch_issues

      expect(stored_worklogs("10001").size).to eq(2)
      expect(jira_client).not_to have_received(:issue_worklogs).with("10001")
    end

    it "fetches all worklogs with an extra request when the issue has more than 20" do
      fetch_issues

      expect(jira_client).to have_received(:issue_worklogs).with("10002").once
      expect(stored_worklogs("10002").size).to eq(22)
    end
  end

  private

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
end
