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
    allow(Setting).to receive(:repository_authentication_caching_enabled?).and_return(true)

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

  describe "#cached_user_login" do
    let(:cache_key) do
      OpenProject::RepositoryAuthentication::CACHE_PREFIX +
        Digest::SHA1.hexdigest("#{valid_user.login}#{valid_user_password}")
    end
    let(:cache_expiry) { OpenProject::RepositoryAuthentication::CACHE_EXPIRES_AFTER }

    it "calls user_login only once when called twice" do
      expect(controller).to receive(:user_login).once.and_return(valid_user)
      2.times { controller.send(:cached_user_login, valid_user.login, valid_user_password) }
    end

    it "returns the same as user_login for valid creds" do
      expect(controller.send(:cached_user_login, valid_user.login, valid_user_password))
        .to eq(controller.send(:user_login, valid_user.login, valid_user_password))
    end

    it "returns the same as user_login for invalid creds" do
      expect(controller.send(:cached_user_login, "invalid", "invalid"))
        .to eq(controller.send(:user_login, "invalid", "invalid"))
    end

    it "uses cache" do
      allow(Rails.cache).to receive(:fetch).and_call_original
      expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: cache_expiry)
        .and_return(Marshal.dump(valid_user.id.to_s))
      controller.send(:cached_user_login, valid_user.login, valid_user_password)
    end

    describe "with caching disabled" do
      before do
        allow(Setting).to receive(:repository_authentication_caching_enabled?).and_return(false)
      end

      it "does not use a cache" do
        allow(Rails.cache).to receive(:fetch).and_wrap_original do |m, *args, &block|
          expect(args.first).not_to eq(cache_key)
          m.call(*args, &block)
        end

        controller.send(:cached_user_login, valid_user.login, valid_user_password)
      end
    end

    describe "update_required_storage" do
      let(:force) { nil }
      let(:apikey) { Setting.sys_api_key }
      let(:last_updated) { nil }

      def request_storage
        get "update_required_storage", params: { key: apikey,
                                                 id:,
                                                 force: }
      end

      context "missing project" do
        let(:id) { 1234 }

        it "returns 404" do
          request_storage
          expect(response.code).to eq("404")
          expect(response.body).to include("Could not find project #1234")
        end
      end

      context "available project, but missing repository" do
        let(:project) { build_stubbed(:project) }
        let(:id) { project.id }

        before do
          allow(Project).to receive(:find).and_return(project)
          request_storage
        end

        it "returns 404" do
          expect(response.code).to eq("404")
          expect(response.body).to include("Project ##{project.id} does not have a repository.")
        end
      end

      context "stubbed repository" do
        let(:project) { build_stubbed(:project) }
        let(:id) { project.id }
        let(:repository) do
          build_stubbed(:repository_subversion, url:, root_url: url)
        end

        before do
          allow(Project).to receive(:find).and_return(project)
          allow(project).to receive(:repository).and_return(repository)

          allow(repository).to receive(:storage_updated_at).and_return(last_updated)
          request_storage
        end

        context "local non-existing repository" do
          let(:root_url) { "/tmp/does/not/exist/svn/foo.svn" }
          let(:url) { "file://#{root_url}" }

          it "does not have storage available" do
            expect(repository.scm.storage_available?).to be false
            expect(response.code).to eq("400")
          end
        end

        context "remote stubbed repository" do
          let(:root_url) { "" }
          let(:url) { "https://foo.example.org/svn/bar" }

          it "has no storage available" do
            request_storage
            expect(repository.scm.storage_available?).to be false
            expect(response.code).to eq("400")
          end
        end
      end

      context "local existing repository" do
        with_subversion_repository do |repo_dir|
          let(:root_url) { repo_dir }
          let(:url) { "file://#{root_url}" }

          let(:project) { create(:project) }
          let(:id) { project.id }
          let(:repository) do
            create(:repository_subversion, project:, url:, root_url: url)
          end

          before do
            allow(Project).to receive(:find).and_return(project)
            allow(project).to receive(:repository).and_return(repository)
            allow(repository).to receive(:storage_updated_at).and_return(last_updated)
          end

          it "has storage available" do
            expect(repository.scm.storage_available?).to be true
          end

          context "storage never updated before" do
            it "updates the storage" do
              expect(repository.required_storage_bytes).to eq 0
              request_storage

              expect(response.code).to eq("200")
              expect(response.body).to include("Updated: true")

              perform_enqueued_jobs

              repository.reload
              expect(repository.required_storage_bytes).to be > 0
            end
          end

          context "outdated storage" do
            let(:last_updated) { 2.days.ago }

            it "updates the storage" do
              expect(SCM::StorageUpdaterJob).to receive(:perform_later)
              request_storage
            end
          end

          context "valid storage time" do
            let(:last_updated) { 10.minutes.ago }

            it "does not update to storage" do
              expect(SCM::StorageUpdaterJob).not_to receive(:perform_later)
              request_storage
            end
          end

          context "valid storage time and force" do
            let(:force) { "1" }
            let(:last_updated) { 10.minutes.ago }

            it "does update to storage" do
              expect(SCM::StorageUpdaterJob).to receive(:perform_later)
              request_storage
            end
          end
        end
      end
    end
  end

  describe "#projects" do
    before do
      request.env["HTTP_AUTHORIZATION"] =
        ActionController::HttpAuthentication::Basic.encode_credentials(
          valid_user.login,
          valid_user_password
        )

      get "projects", params: { key: api_key }
    end

    it "is successful" do
      expect(response)
        .to have_http_status(:ok)
    end

    it "returns an xml with the projects having a repository" do
      expect(response.content_type)
        .to eql "application/xml; charset=utf-8"

      expect(Nokogiri::XML::Document.parse(response.body).xpath("//projects[1]//id").text)
        .to eql repository_project.id.to_s
    end

    context "when disabled", with_settings: { sys_api_enabled?: false } do
      it "is 403 forbidden" do
        expect(response)
          .to have_http_status(:forbidden)
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
