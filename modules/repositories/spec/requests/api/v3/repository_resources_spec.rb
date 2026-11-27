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
require "rack/test"

RSpec.describe "API v3 repository resources" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking repositories]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking repositories]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project: other_project) }
  shared_let(:permitted_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages show_repository_content],
                                             other_project => %i[view_work_packages] })
  end
  shared_let(:unpermitted_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:provider) { create(:repository_provider) }

  subject(:response) { last_response }

  shared_examples_for "a repository resource" do |type|
    describe "GET the collection of a work package" do
      let(:path) { collection_path }

      before do
        login_as(user)
        get path
      end

      context "for a user with permission to show repository content" do
        let(:user) { permitted_user }

        it_behaves_like "API V3 collection response", 1, 1, type do
          let(:elements) { [linked_resource] }
        end
      end

      context "with a page size of zero" do
        let(:user) { permitted_user }
        let(:path) { "#{collection_path}?pageSize=0" }

        it_behaves_like "API V3 collection response", 1, 0, type
      end

      context "for a user without permission to show repository content" do
        let(:user) { unpermitted_user }

        it_behaves_like "unauthorized access"
      end
    end

    describe "GET a single resource" do
      before do
        login_as(user)
        get path
      end

      context "for a resource linked to a work package with permission" do
        let(:user) { permitted_user }
        let(:path) { resource_path(linked_resource) }

        it "responds with the resource" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_json_eql(type.to_json).at_path("_type")
          expect(response.body).to be_json_eql(linked_resource.id.to_json).at_path("id")
          expect(response.body).to be_json_eql(path.to_json).at_path("_links/self/href")
        end
      end

      context "for a resource linked to a work package without permission" do
        let(:user) { permitted_user }
        let(:path) { resource_path(unrelated_resource) }

        it_behaves_like "not found"
      end

      context "for a user without permission to show repository content" do
        let(:user) { unpermitted_user }
        let(:path) { resource_path(linked_resource) }

        it_behaves_like "not found"
      end
    end
  end

  describe "links of a work package" do
    let(:link_paths) do
      %w[repositoryIssues repositoryMergeRequests repositoryBranches repositoryCommits].map { "_links/#{it}/href" }
    end

    before do
      login_as(user)
      get api_v3_paths.work_package(work_package.id)
    end

    context "for a user with permission to show repository content" do
      let(:user) { permitted_user }

      it "links to the repository resources" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.repository_issues_by_work_package(work_package.id).to_json)
          .at_path("_links/repositoryIssues/href")
        link_paths.each { expect(response.body).to have_json_path(it) }
      end
    end

    context "for a user without permission to show repository content" do
      let(:user) { unpermitted_user }

      it "does not link to the repository resources" do
        link_paths.each { expect(response.body).not_to have_json_path(it) }
      end
    end
  end

  describe "repository issues" do
    let!(:linked_resource) { create(:repository_issue, provider:, work_packages: [work_package]) }
    let!(:unrelated_resource) { create(:repository_issue, provider:, work_packages: [other_work_package]) }
    let(:collection_path) { api_v3_paths.repository_issues_by_work_package(work_package.id) }

    def resource_path(resource) = api_v3_paths.repository_issue(resource.id)

    it_behaves_like "a repository resource", "RepositoryIssue"
  end

  describe "repository merge requests" do
    let!(:linked_resource) { create(:repository_merge_request, provider:, work_packages: [work_package]) }
    let!(:unrelated_resource) { create(:repository_merge_request, provider:, work_packages: [other_work_package]) }
    let(:collection_path) { api_v3_paths.repository_merge_requests_by_work_package(work_package.id) }

    def resource_path(resource) = api_v3_paths.repository_merge_request(resource.id)

    it_behaves_like "a repository resource", "RepositoryMergeRequest"
  end

  describe "repository pipelines" do
    let!(:merge_request) { create(:repository_merge_request, provider:, work_packages: [work_package]) }
    let!(:older_pipeline) { create(:repository_pipeline, provider:, merge_request:, started_at: 1.hour.ago) }
    let!(:pending_pipeline) { create(:repository_pipeline, provider:, merge_request:, started_at: nil) }
    let!(:unrelated_merge_request) do
      create(:repository_merge_request, provider:, work_packages: [other_work_package])
    end
    let!(:unrelated_pipeline) { create(:repository_pipeline, provider:, merge_request: unrelated_merge_request) }

    before do
      login_as(user)
      get path
    end

    describe "GET the collection of a merge request" do
      context "for a user with permission to show repository content" do
        let(:user) { permitted_user }
        let(:path) { api_v3_paths.repository_pipelines_by_merge_request(merge_request.id) }

        it_behaves_like "API V3 collection response", 2, 2, "RepositoryPipeline" do
          let(:elements) { [older_pipeline, pending_pipeline] }
        end
      end

      context "for a merge request linked to a work package without permission" do
        let(:user) { permitted_user }
        let(:path) { api_v3_paths.repository_pipelines_by_merge_request(unrelated_merge_request.id) }

        it_behaves_like "not found"
      end
    end

    describe "GET a single pipeline" do
      context "for a pipeline of a visible merge request" do
        let(:user) { permitted_user }
        let(:path) { api_v3_paths.repository_pipeline(older_pipeline.id) }

        it "responds with the pipeline" do
          expect(response).to have_http_status(:ok)
          expect(response.body).to be_json_eql("RepositoryPipeline".to_json).at_path("_type")
          expect(response.body).to be_json_eql(path.to_json).at_path("_links/self/href")
        end
      end

      context "for a pipeline of a merge request linked to a work package without permission" do
        let(:user) { permitted_user }
        let(:path) { api_v3_paths.repository_pipeline(unrelated_pipeline.id) }

        it_behaves_like "not found"
      end

      context "for a user without permission to show repository content" do
        let(:user) { unpermitted_user }
        let(:path) { api_v3_paths.repository_pipeline(older_pipeline.id) }

        it_behaves_like "not found"
      end
    end

    describe "GET the merge request" do
      let(:user) { permitted_user }
      let(:path) { api_v3_paths.repository_merge_request(merge_request.id) }

      it "links to its pipelines and to the pipeline that has not started yet as the latest one" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.repository_pipelines_by_merge_request(merge_request.id).to_json)
          .at_path("_links/pipelines/href")
        expect(response.body)
          .to be_json_eql(api_v3_paths.repository_pipeline(pending_pipeline.id).to_json)
          .at_path("_links/latestPipeline/href")
      end
    end
  end

  describe "repository branches" do
    let!(:linked_resource) { create(:repository_branch, provider:, work_package:) }
    let!(:unrelated_resource) { create(:repository_branch, provider:, work_package: other_work_package) }
    let(:collection_path) { api_v3_paths.repository_branches_by_work_package(work_package.id) }

    def resource_path(resource) = api_v3_paths.repository_branch(resource.id)

    it_behaves_like "a repository resource", "RepositoryBranch"
  end

  describe "repository commits" do
    let!(:linked_resource) { create(:repository_commit, provider:, work_packages: [work_package]) }
    let!(:unrelated_resource) { create(:repository_commit, provider:, work_packages: [other_work_package]) }
    let(:collection_path) { api_v3_paths.repository_commits_by_work_package(work_package.id) }

    def resource_path(resource) = api_v3_paths.repository_commit(resource.id)

    it_behaves_like "a repository resource", "RepositoryCommit"

    context "when a commit is also linked to a work package without permission" do
      before do
        unrelated_resource.work_packages << work_package
        login_as(permitted_user)
        get api_v3_paths.repository_commit(unrelated_resource.id)
      end

      it "is visible through the permitted work package" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
