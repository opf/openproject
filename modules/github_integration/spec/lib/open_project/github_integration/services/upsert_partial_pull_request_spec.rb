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

RSpec.describe OpenProject::GithubIntegration::Services::UpsertPartialPullRequest do
  subject(:upsert) do
    described_class.new.call(OpenProject::GithubIntegration::NotificationHandler::Helper::Payload.new(payload),
                             work_packages:)
  end

  let!(:upsert_user_service) do
    upsert_user_service = instance_double(OpenProject::GithubIntegration::Services::UpsertGithubUser)
    allow(OpenProject::GithubIntegration::Services::UpsertGithubUser)
      .to receive(:new)
            .and_return(upsert_user_service)

    allow(upsert_user_service)
      .to receive(:call)
            .and_return(GithubUser.new(id: 12345))
  end

  let(:payload) do
    {
      "issue" => {
        "number" => 23,
        "title" => "Some title",
        "updated_at" => "2021-04-06T15:16:03Z",
        "state" => "closed",
        "pull_request" => {
          "html_url" => "https://github.com/pulls/1"
        },
        "user" => {
          "login" => "test_user",
          "id" => 206108,
          "html_url" => "https://github.com/test_user"
        }
      },
      "repository" => {
        "full_name" => "test_user/repo"
      }
    }
  end
  let(:work_packages) { create_list(:work_package, 1) }

  it "creates a new github pull request" do
    expect { upsert }.to change(GithubPullRequest, :count).by(1)

    expect(GithubPullRequest.last).to have_attributes(
      github_id: nil,
      state: "closed",
      number: 23,
      title: "Some title",
      github_html_url: "https://github.com/pulls/1",
      github_updated_at: DateTime.parse("2021-04-06T15:16:03Z"),
      github_user_id: 12345,
      repository: "test_user/repo",
      work_packages:
    )
  end

  context "when a github pull request with that html_url already exists" do
    let(:github_pull_request) do
      create(:github_pull_request,
             github_html_url: "https://github.com/pulls/1")
    end

    it "updates the github pull request" do
      expect { upsert }.to change { github_pull_request.reload.work_packages }.from([]).to(work_packages)
    end
  end

  context "when a github pull request with that html_url and work_package exists" do
    let(:github_pull_request) do
      create(:github_pull_request,
             github_html_url: "https://github.com/pulls/1",
             work_packages:)
    end

    it "does not change the associated work packages" do
      expect { upsert }.not_to(change { github_pull_request.reload.work_packages.to_a })
    end
  end

  context "when a github pull request with that html_url and work_package exists and a new work_package is referenced" do
    let(:github_pull_request) do
      create(:github_pull_request,
             github_html_url: "https://github.com/pulls/1",
             work_packages: already_known_work_packages)
    end
    let(:work_packages) { create_list(:work_package, 2) }
    let(:already_known_work_packages) { [work_packages[0]] }

    it "adds the new work package" do
      expect { upsert }
        .to change { github_pull_request.reload.work_packages }
              .from(already_known_work_packages)
              .to(work_packages)
    end
  end

  context "when an open github pull request with that html_url and work_package exists and a new work_package is referenced" do
    let(:github_pull_request) do
      create(:github_pull_request,
             github_html_url: "https://github.com/pulls/1",
             repository: "some_user/a_repository",
             state: "open",
             github_id: 1,
             work_packages: already_known_work_packages)
    end
    let(:work_packages) { create_list(:work_package, 2) }
    let(:already_known_work_packages) { [work_packages[0]] }

    it "adds the new work package and updates attributes" do
      expect { upsert }
        .to change { github_pull_request.reload.work_packages }
              .from(already_known_work_packages)
              .to(work_packages)

      expect(github_pull_request).to have_attributes(
        github_id: 1,
        state: "closed",
        number: 23,
        title: "Some title",
        github_user_id: 12345,
        github_html_url: "https://github.com/pulls/1",
        github_updated_at: DateTime.parse("2021-04-06T15:16:03Z"),
        repository: "test_user/repo"
      )
    end
  end
end
