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

require File.expand_path("../../../../spec_helper", __dir__)

RSpec.describe OpenProject::GithubIntegration::NotificationHandler::CheckRun do
  subject(:process) { described_class.new.process(payload) }

  let(:upsert_check_run_service) do
    instance_double(OpenProject::GithubIntegration::Services::UpsertCheckRun)
  end
  let(:payload) do
    {
      "check_run" => {
        "pull_requests" => pull_requests_payload
      }
    }
  end
  let(:pull_requests_payload) { [] }

  before do
    allow(OpenProject::GithubIntegration::Services::UpsertCheckRun).to receive(:new)
                                                                              .and_return(upsert_check_run_service)
    allow(upsert_check_run_service).to receive(:call).and_return(nil)
  end

  it "does not call the UpsertCheckRun service when the check_run is not associated to a PR" do
    process
    expect(upsert_check_run_service).not_to have_received(:call)
  end

  context "when the check_run is not associated to a known GithubPullRequest" do
    let(:pull_requests_payload) do
      [
        {
          "id" => 123
        }
      ]
    end

    it "does not call the UpsertCheckRun service" do
      process
      expect(upsert_check_run_service).not_to have_received(:call)
    end
  end

  context "when the check_run is associated to a known GithubPullRequest" do
    let(:pull_requests_payload) do
      [
        {
          "id" => 123
        }
      ]
    end
    let(:github_pull_request) { create(:github_pull_request, github_id: 123) }

    before { github_pull_request }

    it "does not call the UpsertCheckRun service" do
      process
      expect(upsert_check_run_service).to have_received(:call).with(
        payload["check_run"],
        pull_request: github_pull_request
      )
    end
  end
end
