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

RSpec.describe Import::JiraInstanceMetaDataJob do
  subject(:perform_job) { described_class.new.perform(jira_import.id) }

  shared_let(:author) { create(:admin) }

  let(:jira) { create(:jira) }
  let(:jira_import) { create(:jira_import, jira:, author:) }
  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:server_info) { { "serverTitle" => "Jira", "version" => "10.3.0" } }

  before do
    allow(Import::JiraImportStateMachine).to receive(:enqueued_job_id).and_return("stubbed-job-id")
    allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive_messages(
      administrator?: administrator,
      issue_types_count: 3,
      statuses_count: 4,
      resolutions_count: 6,
      issues_count: 5,
      applicationrole: [{ "userCount" => 2 }],
      projects: [],
      server_info:
    )

    jira_import.transition_to!(:instance_meta_fetching)
  end

  context "when the credentials belong to a Jira administrator" do
    let(:administrator) { true }

    it "stores the instance meta data" do
      perform_job

      expect(jira_import.reload.current_state).to eq("instance_meta_done")
      expect(jira_import.available).to include("total_issues" => 5, "total_users" => 2, "server_info" => server_info)
    end

    it "stores the passed connection check and records it on the run" do
      perform_job

      report = jira.latest_health_report
      expect(report).to be_healthy
      expect(jira_import.reload.last_transition.metadata).to include("health_report_id" => report.id)
    end
  end

  context "when the Jira version is not supported" do
    let(:administrator) { true }
    let(:server_info) { { "serverTitle" => "Jira", "version" => "12.0.0" } }

    it "fetches the instance meta data anyway and records the warning on the run" do
      perform_job

      report = jira.latest_health_report
      expect(report.group("server")["version_supported"]).to be_warning
      expect(jira_import.reload.current_state).to eq("instance_meta_done")
      expect(jira_import.connection_check_report).to eq(report)
    end
  end

  context "when the Jira user is not an administrator" do
    let(:administrator) { false }

    it "fails the run without fetching any instance meta data" do
      perform_job

      expect(jira_import.reload.current_state).to eq("instance_meta_error")
      expect(jira_import.last_transition.metadata["error"]).to eq(I18n.t(:"admin.jira.run.connection_check_error"))
      expect(jira_client).not_to have_received(:projects)
      expect(jira_import.available).to be_empty
    end

    it "records the failed connection check on the run, without a backtrace" do
      perform_job

      report = jira.latest_health_report
      expect(report.group("authorization")["administrator"]).to be_failure
      expect(jira_import.reload.last_transition.metadata).to include("health_report_id" => report.id)
      expect(jira_import.last_transition.metadata).not_to have_key("error_backtrace")
    end
  end
end
