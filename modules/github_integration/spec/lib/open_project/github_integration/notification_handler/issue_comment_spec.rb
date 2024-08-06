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

RSpec.describe OpenProject::GithubIntegration::NotificationHandler::IssueComment do
  subject(:process) { handler_instance.process(payload) }

  let(:handler_instance) { described_class.new }
  let(:upsert_partial_pull_request_service) do
    OpenProject::GithubIntegration::Services::UpsertPartialPullRequest.new
  end
  let(:payload) do
    {
      "action" => action,
      "comment" => {
        "body" => comment_body,
        "html_url" => "https://comment.url",
        "user" => {
          "login" => "test_user",
          "html_url" => "https://github.com/test_user"
        }
      },
      "issue" => {
        "state" => "open",
        "number" => pr_number,
        "title" => "PR or issue title",
        "updated_at" => Time.current.iso8601,
        "pull_request" => pr_payload,
        "user" => {
          "id" => 345,
          "login" => "test_user",
          "html_url" => "https://github.com/test_user",
          "avatar_url" => "https://github.com/test_user.jpg"
        }
      },
      "repository" => {
        "full_name" => repo_full_name,
        "html_url" => "https://github.com/test_user/repo"
      },
      "open_project_user_id" => github_system_user.id
    }
  end
  let(:comment_body) { "a comment about OP##{work_package.id}" }
  let(:pr_payload) { { "html_url" => pr_html_url } }
  let(:pr_html_url) { "https://github.com/test_user/repo/pull/123" }
  let(:pr_number) { 123 }
  let(:repo_full_name) { "test_user/repo" }
  let(:github_system_user) { create(:admin) }
  let(:work_package) { create(:work_package) }
  let(:github_pull_request) { GithubPullRequest.find_by(github_html_url: pr_html_url) }

  before do
    allow(handler_instance)
      .to receive(:comment_on_referenced_work_packages)
            .and_return(nil)
    allow(OpenProject::GithubIntegration::Services::UpsertPartialPullRequest)
      .to receive(:new)
            .and_return(upsert_partial_pull_request_service)
    allow(upsert_partial_pull_request_service)
      .to receive(:call)
            .and_call_original
  end

  shared_examples_for "upserting a GithubPullRequest" do
    it "calls the UpsertPartialPullRequest service" do
      process
      expect(upsert_partial_pull_request_service)
        .to have_received(:call) do |received_payload, work_packages:|
        expect(received_payload.to_h)
          .to eql payload
        expect(work_packages)
          .to contain_exactly(work_package)
      end
    end
  end

  shared_examples_for "not upserting a GithubPullRequest" do
    it "does not call the UpsertPartialPullRequest service" do
      process
      expect(upsert_partial_pull_request_service).not_to have_received(:call)
    end
  end

  shared_examples_for "creating a comment on the work package" do
    it "adds a comment to work packages" do
      process
      expect(handler_instance)
        .to have_received(:comment_on_referenced_work_packages)
        .with([work_package], github_system_user, comment)
    end
  end

  shared_examples_for "not creating comments on work packages" do
    it "does not add comments to work packages" do
      process
      expect(handler_instance).not_to have_received(:comment_on_referenced_work_packages)
    end
  end

  context "when a comment was created" do
    let(:action) { "created" }

    context "when commented on an issue" do
      let(:pr_payload) { nil }

      it_behaves_like "not creating comments on work packages"
      it_behaves_like "not upserting a GithubPullRequest"
    end

    context "when commented on a PR" do
      let(:comment) do
        %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
          data-pull-request-state="&quot;referenced&quot;"></macro>).squish
      end

      it_behaves_like "creating a comment on the work package"
      it_behaves_like "upserting a GithubPullRequest"
    end

    context "when we already have a GithubPullRequest for the commented PR" do
      let!(:github_pull_request) { create(:github_pull_request, github_html_url: pr_html_url) }
      let(:comment) do
        %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
          data-pull-request-state="&quot;referenced&quot;"></macro>).squish
      end

      it_behaves_like "creating a comment on the work package"
      it_behaves_like "upserting a GithubPullRequest"
    end

    context "when we already have a GithubPullRequest with that work_package" do
      let!(:github_pull_request) do
        create(:github_pull_request, github_html_url: pr_html_url, work_packages: [work_package])
      end

      it_behaves_like "not creating comments on work packages"

      it "calls the UpsertPartialPullRequest service without adding already known work_packages" do
        process
        expect(upsert_partial_pull_request_service).not_to have_received(:call)
      end
    end
  end

  context "when a comment was edited" do
    let(:action) { "edited" }

    context "when editing an issue comment" do
      let(:pr_payload) { nil }

      it_behaves_like "not creating comments on work packages"
      it_behaves_like "not upserting a GithubPullRequest"
    end

    context "when editing a PR comment with a new work package reference" do
      let(:comment) do
        %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
          data-pull-request-state="&quot;referenced&quot;"></macro>).squish
      end

      it_behaves_like "creating a comment on the work package"
      it_behaves_like "upserting a GithubPullRequest"
    end

    context "when we already have a GithubPullRequest for the commented PR" do
      let!(:github_pull_request) { create(:github_pull_request, github_html_url: pr_html_url) }
      let(:comment) do
        %(<macro class="github_pull_request" data-pull-request-id="#{github_pull_request.id}"
          data-pull-request-state="&quot;referenced&quot;"></macro>).squish
      end

      it_behaves_like "creating a comment on the work package"
      it_behaves_like "upserting a GithubPullRequest"
    end

    context "when we already have a GithubPullRequest with that work_package" do
      let!(:github_pull_request) do
        create(:github_pull_request, github_html_url: pr_html_url, work_packages: [work_package])
      end

      it_behaves_like "not creating comments on work packages"

      it "calls the UpsertPartialPullRequest service without adding already known work_packages" do
        process
        expect(upsert_partial_pull_request_service)
          .not_to have_received(:call)
      end
    end
  end
end
