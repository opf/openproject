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

RSpec.describe OpenProject::GithubIntegration::Services::UpsertPullRequest do
  subject(:upsert) { described_class.new.call(params, work_packages:) }

  let(:params) do
    {
      "id" => 123,
      "number" => 5,
      "html_url" => "https://github.com/test_user/repo",
      "updated_at" => "20210409T12:13:14Z",
      "state" => pr_state,
      "title" => "The PR title",
      "body" => "The PR body",
      "draft" => false,
      "comments" => 12,
      "review_comments" => 13,
      "additions" => 14,
      "deletions" => 15,
      "changed_files" => 16,
      "labels" => labels_payload,
      "base" => {
        "repo" => {
          "full_name" => "test_user/repo",
          "html_url" => "https://github.com/test_user/repo"
        }
      },
      "user" => user_payload,
      **merged_payload
    }
  end
  let(:labels_payload) { [] }
  let(:pr_state) { "open" }
  let(:merged_payload) do
    {
      "merged" => false,
      "merged_by" => nil,
      "merged_at" => nil
    }
  end
  let(:user_payload) do
    {
      "id" => 456,
      "login" => "test_user",
      "html_url" => "https://github.com/test_user",
      "avatar_url" => "https://github.com/test_user/avatar.jpg"
    }
  end
  let(:work_packages) { create_list(:work_package, 1) }
  let(:github_user) { create(:github_user) }
  let(:upsert_github_user_service) { instance_double(OpenProject::GithubIntegration::Services::UpsertGithubUser) }

  before do
    allow(OpenProject::GithubIntegration::Services::UpsertGithubUser).to receive(:new).and_return(upsert_github_user_service)
    allow(upsert_github_user_service).to receive(:call).and_return(github_user)
  end

  it "creates a new github pull request and calls the upsert github user service" do
    expect { upsert }.to change(GithubPullRequest, :count).by(1)

    expect(upsert_github_user_service).to have_received(:call).with(user_payload)

    expect(GithubPullRequest.last).to have_attributes(
      github_id: 123,
      number: 5,
      github_html_url: "https://github.com/test_user/repo",
      github_updated_at: Time.zone.parse("20210409T12:13:14Z"),
      state: "open",
      title: "The PR title",
      body: "The PR body",
      draft: false,
      merged: false,
      merged_by: nil,
      merged_at: nil,
      comments_count: 12,
      review_comments_count: 13,
      additions_count: 14,
      deletions_count: 15,
      changed_files_count: 16,
      labels: [],
      repository: "test_user/repo",
      github_user:,
      work_packages:
    )
  end

  context "when a github pull request with that id already exists" do
    let(:github_pull_request) do
      create(:github_pull_request, github_id: 123, title: "old title")
    end

    it "updates the github pull request" do
      expect { upsert }.to change { github_pull_request.reload.title }.from("old title").to("The PR title")
    end
  end

  context "when a partial github pull request with that html_url already exists" do
    let(:github_pull_request) do
      create(:github_pull_request,
             github_id: nil,
             changed_files_count: nil,
             body: nil,
             comments_count: nil,
             review_comments_count: nil,
             additions_count: nil,
             deletions_count: nil,
             github_html_url: "https://github.com/test_user/repo",
             state: "closed")
    end

    it "updates the github pull request" do
      expect { upsert }.to change { github_pull_request.reload.state }.from("closed").to("open")

      expect(github_pull_request).to have_attributes(
        github_id: 123,
        state: "open",
        number: 5,
        title: "The PR title",
        body: "The PR body",
        github_html_url: "https://github.com/test_user/repo",
        github_updated_at: DateTime.parse("20210409T12:13:14Z"),
        repository: "test_user/repo"
      )
    end
  end

  context "when a github pull request with that id and work_package exists" do
    let(:github_pull_request) do
      create(:github_pull_request, github_id: 123, work_packages:)
    end

    it "does not change the associated work packages" do
      expect { upsert }.not_to(change { github_pull_request.reload.work_packages.to_a })
    end
  end

  context "when a github pull request with that id and work_package exists and a new work_package is referenced" do
    let(:github_pull_request) do
      create(:github_pull_request, github_id: 123,
                                   work_packages: already_known_work_packages)
    end
    let(:work_packages) { create_list(:work_package, 2) }
    let(:already_known_work_packages) { [work_packages[0]] }

    it "adds the new work package" do
      expect { upsert }.to change { github_pull_request.reload.work_packages }.from(already_known_work_packages).to(work_packages)
    end
  end

  context "when the pr is merged" do
    let(:pr_state) { "open" }
    let(:merged_payload) do
      {
        "merged" => true,
        "merged_by" => user_payload,
        "merged_at" => "20210410T09:45:03Z",
        "merge_commit_sha" => "955af2f83de81c39fcf912376855eb3ee5e38f26"
      }
    end

    it "sets the merge attributes" do
      expect { upsert }.to change(GithubPullRequest, :count).by(1)

      expect(upsert_github_user_service).to have_received(:call).with(user_payload).twice

      expect(GithubPullRequest.last).to have_attributes(
        github_id: 123,
        github_user:,
        merged: true,
        merged_by: github_user,
        merged_at: Time.zone.parse("20210410T09:45:03Z"),
        merge_commit_sha: "955af2f83de81c39fcf912376855eb3ee5e38f26"
      )
    end
  end

  context "when the pull request payload contains label data" do
    let(:labels_payload) do
      [
        {
          "id" => 123456789,
          "name" => "grey",
          "color" => "#666",
          "description" => "An evil'ish gray tone"
        },
        {
          "id" => 987654321,
          "name" => "white",
          "color" => "#fff",
          "description" => "A haven'ish white tone"
        }
      ]
    end

    it "stores the label attributes" do
      expect { upsert }.to change(GithubPullRequest, :count).by(1)

      expect(GithubPullRequest.last).to have_attributes(
        github_id: 123,
        labels: [
          {
            "name" => "grey",
            "color" => "#666"
          },
          {
            "name" => "white",
            "color" => "#fff"
          }
        ]
      )
    end
  end
end
