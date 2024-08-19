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

RSpec.describe OpenProject::GithubIntegration::NotificationHandler::PullRequest do
  subject(:process) { handler_instance.process(payload) }

  let(:handler_instance) { described_class.new }
  let(:github_system_user) { create(:admin) }
  let(:upsert_service) { OpenProject::GithubIntegration::Services::UpsertPullRequest.new }

  let(:payload) do
    {
      "action" => action,
      "open_project_user_id" => github_system_user.id,
      "pull_request" => {
        "id" => 123,
        "number" => 1,
        "body" => pr_body,
        "title" => "A PR title",
        "html_url" => "http://pr.url",
        "updated_at" => Time.current.iso8601,
        "state" => "open",
        "draft" => pr_draft,
        "merged" => pr_merged,
        "merged_by" => nil,
        "merged_at" => nil,
        "merge_commit_sha" => nil,
        "comments" => 1,
        "review_comments" => 2,
        "additions" => 3,
        "deletions" => 4,
        "changed_files" => 5,
        "labels" => [],
        "user" => {
          "id" => 345,
          "login" => "test_user",
          "html_url" => "https://github.com/test_user",
          "avatar_url" => "https://github.com/test_user.jpg"
        },
        "base" => {
          "repo" => {
            "full_name" => "test_user/repo",
            "html_url" => "github.com/test_user/repo"
          }
        }
      },
      "sender" => {
        "login" => "test_user",
        "html_url" => "github.com/test_user"
      }
    }
  end
  let(:work_package) { create(:work_package) }
  let(:pr_body) { "Mentioning OP##{work_package.id}" }
  let(:pr_merged) { false }
  let(:pr_draft) { false }
  let(:github_pull_request) { GithubPullRequest.find_by_github_identifiers id: 123 }

  before do
    allow(handler_instance).to receive(:comment_on_referenced_work_packages).and_return(nil)
    allow(OpenProject::GithubIntegration::Services::UpsertPullRequest).to receive(:new).and_return(upsert_service)
    allow(upsert_service).to receive(:call).and_call_original
  end

  shared_examples_for "not adding a comment" do
    it "does not add comments to work packages" do
      process
      expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
        [],
        github_system_user,
        anything
      )
    end
  end

  shared_examples_for "adding a comment" do
    it "adds a comment to the work packages" do
      process
      expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
        [work_package],
        github_system_user,
        comment
      )
    end
  end

  shared_examples_for "calls the pull request upsert service" do
    it "calls the pull request upsert service" do
      process
      expect(upsert_service).to have_received(:call).with(payload["pull_request"], work_packages: [work_package])
    end

    context "when no work_package was mentioned" do
      let(:pr_body) { "some text that does not mention any work package" }

      it "does not call the pull request upsert service" do
        process
        expect(upsert_service).not_to have_received(:call)
      end
    end
  end

  context "with a closed action" do
    let(:action) { "closed" }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;closed&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with a closed action when the PR was merged" do
    let(:action) { "closed" }
    let(:pr_merged) { true }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;merged&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"

    context "when the work package is already known to the GithubPullRequest" do
      let!(:github_pull_request) { create(:github_pull_request, github_id: 123, work_packages: [work_package]) }

      it_behaves_like "adding a comment"

      it "calls the pull request upsert service" do
        process
        expect(upsert_service).to have_received(:call).with(payload["pull_request"], work_packages: [work_package])
      end
    end
  end

  context "with a converted_to_draft action" do
    let(:action) { "converted_to_draft" }

    it_behaves_like "not adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with an edited action" do
    let(:action) { "edited" }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;referenced&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"

    context "when a GithubPullRequest exists that is not linked to the mentioned work package yet" do
      let!(:github_pull_request) { create(:github_pull_request, github_id: 123) }

      it_behaves_like "adding a comment"

      it "calls the pull request upsert service" do
        process
        expect(upsert_service).to have_received(:call).with(payload["pull_request"], work_packages: [work_package])
      end
    end

    context "when the work package is already known to the GithubPullRequest" do
      let!(:github_pull_request) { create(:github_pull_request, github_id: 123, work_packages: [work_package]) }

      it_behaves_like "not adding a comment"

      it "calls the pull request upsert service" do
        process
        expect(upsert_service).to have_received(:call).with(payload["pull_request"], work_packages: [work_package])
      end
    end

    context "when the a work package is already known to the GithubPullRequest but another work package is new" do
      let!(:github_pull_request) { create(:github_pull_request, github_id: 123, work_packages: [work_package]) }
      let!(:other_work_package) { create(:work_package) }
      let(:pr_body) { "Mentioning OP##{work_package.id} and OP##{other_work_package.id}" }

      it "adds a comment only for the other_work_package" do
        process
        expect(handler_instance).to have_received(:comment_on_referenced_work_packages).with(
          [other_work_package],
          github_system_user,
          comment
        )
      end

      it "calls the pull request upsert service with all work_packages" do
        process
        expect(upsert_service).to have_received(:call).with(payload["pull_request"],
                                                            work_packages: [work_package, other_work_package])
      end
    end
  end

  context "with a labeled action" do
    let(:action) { "labeled" }

    it_behaves_like "not adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with an opened action" do
    let(:action) { "opened" }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;opened&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with an opened action when the PR is a draft" do
    let(:action) { "opened" }
    let(:pr_draft) { true }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;opened&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with a ready_for_review action" do
    let(:action) { "ready_for_review" }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;ready_for_review&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with a reopened action" do
    let(:action) { "reopened" }
    let(:comment) do
      %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
        data-pull-request-state="&quot;opened&quot;"></macro>).squish
    end

    it_behaves_like "adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end

  context "with a synchronize action" do
    let(:action) { "synchronize" }

    it_behaves_like "not adding a comment"
    it_behaves_like "calls the pull request upsert service"
  end
end
