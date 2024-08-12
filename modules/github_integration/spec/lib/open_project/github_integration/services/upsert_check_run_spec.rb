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

RSpec.describe OpenProject::GithubIntegration::Services::UpsertCheckRun do
  subject(:upsert) { described_class.new.call(params, pull_request: github_pull_request) }

  let(:github_pull_request) { create(:github_pull_request) }
  let(:params) do
    {
      "id" => 123,
      "html_url" => "https://github.com/check_runs/123",
      "name" => "test",
      "status" => "completed",
      "conclusion" => "success",
      "details_url" => "https://github.com/details",
      "started_at" => 1.hour.ago.iso8601,
      "completed_at" => 1.minute.ago.iso8601,
      "output" => {
        "title" => "a title",
        "summary" => "a summary"
      },
      "app" => {
        "id" => 456,
        "owner" => {
          "avatar_url" => "https:://github.com/apps/456/avatar.png"
        }
      }
    }
  end

  it "creates a new check run for the given pull request" do
    expect { upsert }.to change(GithubCheckRun, :count).by(1)

    expect(GithubCheckRun.last).to have_attributes(
      github_id: 123,
      github_html_url: "https://github.com/check_runs/123",
      app_id: 456,
      github_app_owner_avatar_url: "https:://github.com/apps/456/avatar.png",
      name: "test",
      status: "completed",
      conclusion: "success",
      output_title: "a title",
      output_summary: "a summary",
      details_url: "https://github.com/details",
      github_pull_request:
    )
  end

  context "when a check run with that id already exists" do
    let(:check_run) { create(:github_check_run, github_id: 123, status: "queued") }

    it "updates the check run" do
      expect { upsert }.to change { check_run.reload.status }.from("queued").to("completed")
    end
  end
end
