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

RSpec.describe SysController, with_settings: { sys_api_enabled: true } do
  let(:commit_role) do
    create(:project_role, permissions: %i[commit_access browse_repository])
  end
  let(:browse_role) { create(:project_role, permissions: [:browse_repository]) }
  let(:guest_role) { create(:project_role, permissions: []) }
  let(:valid_user_password) { "Top Secret Password" }
  let(:valid_user) do
    create(:user,
           login: "johndoe",
           password: valid_user_password,
           password_confirmation: valid_user_password)
  end

  let(:api_key) { "12345678" }

  let(:public) { false }
  let(:project) { create(:project, public:) }
  let!(:repository_project) do
    create(:project, public: false, members: { valid_user => [browse_role] })
  end

  before do
    create(:non_member, permissions: [:browse_repository])
    DeletedUser.first # creating it first in order to avoid problems with should_receive

    allow(Setting).to receive(:sys_api_key).and_return(api_key)

    Rails.cache.clear
    RequestStore.clear!
  end

  describe "svn" do
    let!(:repository) { create(:repository_subversion, project:) }

    describe "repo_auth" do
      context "for valid login, but no access to repo_auth" do
        before do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: api_key,
                                      repository: "without-access",
                                      method: "GET" }
        end

        it "responds 403 not allowed" do
          expect(response.code).to eq("403")
          expect(response.body).to eq("Not allowed")
        end
      end

      context "for valid login and user has read permission (role reporter) for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [browse_role],
                 project:)

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
        end

        it "responds 200 okay dokay for GET" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET" }

          expect(response.code).to eq("200")
        end

        it "responds 403 not allowed for POST" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "POST" }

          expect(response.code).to eq("403")
        end
      end

      context "for valid login and user has rw permission (role developer) for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [commit_role],
                 project:)
          valid_user.save
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
        end

        it "responds 200 okay dokay for GET" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET" }

          expect(response.code).to eq("200")
        end

        it "responds 200 okay dokay for POST" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "POST" }

          expect(response.code).to eq("200")
        end
      end

      context "for invalid login and user has role manager for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [commit_role],
                 project:)
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password + "made invalid"
            )

          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET" }
        end

        it "responds 401 auth required" do
          expect(response.code).to eq("401")
        end
      end

      context "for valid login and user is not member for project" do
        before do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET" }
        end

        it "responds 403 not allowed" do
          expect(response.code).to eq("403")
        end
      end

      context "for valid login and project is public" do
        let(:public) { true }

        before do
          random_project = create(:project, public: false)
          create(:member,
                 user: valid_user,
                 roles: [browse_role],
                 project: random_project)

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET" }
        end

        it "responds 200 OK" do
          expect(response.code).to eq("200")
        end
      end

      context "for invalid credentials" do
        before do
          post "repo_auth", params: { key: api_key,
                                      repository: "any-repo",
                                      method: "GET" }
        end

        it "responds 401 auth required" do
          expect(response.code).to eq("401")
          expect(response.body).to eq("Authorization required")
        end
      end

      context "for invalid api key" do
        it "responds 403 for valid username/password" do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
          post "repo_auth", params: { key: "not_the_api_key",
                                      repository: "any-repo",
                                      method: "GET" }

          expect(response.code).to eq("403")
          expect(response.body)
            .to eq("Access denied. Repository management WS is disabled or key is invalid.")
        end

        it "responds 403 for invalid username/password" do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              "invalid",
              "invalid"
            )

          post "repo_auth", params: { key: "not_the_api_key",
                                      repository: "any-repo",
                                      method: "GET" }

          expect(response.code).to eq("403")
          expect(response.body)
            .to eq("Access denied. Repository management WS is disabled or key is invalid.")
        end
      end
    end
  end

  describe "git" do
    let!(:repository) { create(:repository_git, project:) }

    describe "repo_auth" do
      context "for valid login, but no access to repo_auth" do
        before do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: api_key,
                                      repository: "without-access",
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }
        end

        it "responds 403 not allowed" do
          expect(response.code).to eq("403")
          expect(response.body).to eq("Not allowed")
        end
      end

      context "for valid login and user has read permission (role reporter) for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [browse_role],
                 project:)

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
        end

        it "responds 200 okay dokay for read-only access" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }

          expect(response.code).to eq("200")
        end

        it "responds 403 not allowed for write (push)" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "POST",
                                      git_smart_http: "1",
                                      uri: "/git/#{project.identifier}/git-receive-pack",
                                      location: "/git" }

          expect(response.code).to eq("403")
        end
      end

      context "for valid login and user has rw permission (role developer) for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [commit_role],
                 project:)
          valid_user.save

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
        end

        it "responds 200 okay dokay for GET" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }

          expect(response.code).to eq("200")
        end

        it "responds 200 okay dokay for POST" do
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "POST",
                                      git_smart_http: "1",
                                      uri: "/git/#{project.identifier}/git-receive-pack",
                                      location: "/git" }

          expect(response.code).to eq("200")
        end
      end

      context "for invalid login and user has role manager for project" do
        before do
          create(:member,
                 user: valid_user,
                 roles: [commit_role],
                 project:)

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password + "made invalid"
            )

          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }
        end

        it "responds 401 auth required" do
          expect(response.code).to eq("401")
        end
      end

      context "for valid login and user is not member for project" do
        before do
          project = create(:project, public: false)
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }
        end

        it "responds 403 not allowed" do
          expect(response.code).to eq("403")
        end
      end

      context "for valid login and project is public" do
        let(:public) { true }

        before do
          random_project = create(:project, public: false)
          create(:member,
                 user: valid_user,
                 roles: [browse_role],
                 project: random_project)

          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )
          post "repo_auth", params: { key: api_key,
                                      repository: project.identifier,
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }
        end

        it "responds 200 OK" do
          expect(response.code).to eq("200")
        end
      end

      context "for invalid credentials" do
        before do
          post "repo_auth", params: { key: api_key,
                                      repository: "any-repo",
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }
        end

        it "responds 401 auth required" do
          expect(response.code).to eq("401")
          expect(response.body).to eq("Authorization required")
        end
      end

      context "for invalid api key" do
        it "responds 403 for valid username/password" do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              valid_user.login,
              valid_user_password
            )

          post "repo_auth", params: { key: "not_the_api_key",
                                      repository: "any-repo",
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }

          expect(response.code).to eq("403")
          expect(response.body)
            .to eq("Access denied. Repository management WS is disabled or key is invalid.")
        end

        it "responds 403 for invalid username/password" do
          request.env["HTTP_AUTHORIZATION"] =
            ActionController::HttpAuthentication::Basic.encode_credentials(
              "invalid",
              "invalid"
            )

          post "repo_auth", params: { key: "not_the_api_key",
                                      repository: "any-repo",
                                      method: "GET",
                                      git_smart_http: "1",
                                      uri: "/git",
                                      location: "/git" }

          expect(response.code).to eq("403")
          expect(response.body)
            .to eq("Access denied. Repository management WS is disabled or key is invalid.")
        end
      end
    end
  end

  describe "#fetch_changesets" do
    let(:params) { { id: repository_project.identifier } }

    before do
      request.env["HTTP_AUTHORIZATION"] =
        ActionController::HttpAuthentication::Basic.encode_credentials(
          valid_user.login,
          valid_user_password
        )

      allow_any_instance_of(Repository::Subversion).to receive(:fetch_changesets).and_return(true)

      get "fetch_changesets", params: params.merge({ key: api_key })
    end

    context "with a project identifier" do
      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end
    end

    context "without a project identifier" do
      let(:params) { {} }

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end
    end

    context "for an unknown project" do
      let(:params) { { id: 0 } }

      it "returns 404" do
        expect(response)
          .to have_http_status(:not_found)
      end
    end

    context "when disabled", with_settings: { sys_api_enabled?: false } do
      it "is 403 forbidden" do
        expect(response)
          .to have_http_status(:forbidden)
      end
    end
  end
end
