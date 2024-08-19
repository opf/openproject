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
require_module_spec_helper

RSpec.describe "projects/:project_id/project_storages/:id/open" do
  let(:expected_redirect_path) do
    API::V3::Utilities::PathHelper::ApiV3Path.project_storage_open(project_storage.id)
  end
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:route) { "projects/#{project.identifier}/project_storages/#{project_storage.id}/open" }
  let(:expected_redirect_url) do
    "#{Setting.protocol}://#{Setting.host_name}#{expected_redirect_path}"
  end

  shared_let(:project) { create(:project) }
  shared_let(:storage) { create(:nextcloud_storage_configured) }

  context "when user is logged in" do
    current_user { create(:user, member_with_permissions: { project => permissions }) }

    context "when user has permissions" do
      let(:permissions) { %i[view_file_links] }

      context "when project_folder is automatic" do
        let(:project_storage) { create(:project_storage, :as_automatically_managed, project:, storage:) }

        context "when project_folder_id has been set by background job already" do
          before { project_storage.update_attribute(:project_folder_id, "123") }

          context "when user is able to read project_folder" do
            before do
              Storages::Peripherals::Registry.stub(
                "nextcloud.queries.file_info", ->(_) { ServiceResult.success }
              )
            end

            context "html" do
              it "redirects to api_v3_projects_storage_open_url" do
                get route, {}, { "HTTP_ACCEPT" => "text/html" }

                expect(last_response).to have_http_status(:found)
                expect(last_response.headers["Location"]).to eq(expected_redirect_url)
              end
            end

            context "turbo_stream" do
              it "renders an appropirate turbo_stream" do
                get route, {}, { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html" }

                expect(last_response).to have_http_status(:ok)
                expect(last_response.body).to eq ("<turbo-stream action=\"update\" target=\"open-project-storage-modal-body-component\">\n    <template>\n        <div data-view-component=\"true\" class=\"flex-items-center p-4 d-flex flex-column\">\n      <div data-view-component=\"true\">      <svg aria-hidden=\"true\" height=\"24\" viewBox=\"0 0 24 24\" version=\"1.1\" width=\"24\" data-view-component=\"true\" class=\"octicon octicon-check-circle color-fg-success\">\n    <path d=\"M17.28 9.28a.75.75 0 0 0-1.06-1.06l-5.97 5.97-2.47-2.47a.75.75 0 0 0-1.06 1.06l3 3a.75.75 0 0 0 1.06 0l6.5-6.5Z\"></path><path d=\"M12 1c6.075 0 11 4.925 11 11s-4.925 11-11 11S1 18.075 1 12 5.925 1 12 1ZM2.5 12a9.5 9.5 0 0 0 9.5 9.5 9.5 9.5 0 0 0 9.5-9.5A9.5 9.5 0 0 0 12 2.5 9.5 9.5 0 0 0 2.5 12Z\"></path>\n</svg>\n</div>\n      <div data-view-component=\"true\">      <h2 data-view-component=\"true\" class=\"text-center\">Integration setup completed</h2>\n</div>\n      <div data-view-component=\"true\">      <span data-view-component=\"true\" class=\"text-center color-fg-muted\">You are being redirected</span>\n</div>\n</div>\n\n\n    </template>\n</turbo-stream>\n\n")
              end
            end
          end

          context "when user is not able to read project_folder" do
            let(:code) { :forbidden }

            before do
              Storages::Peripherals::Registry.stub(
                "nextcloud.queries.file_info", ->(_) do
                  ServiceResult.failure(result: code,
                                        errors: Storages::StorageError.new(code:))
                end
              )
            end

            context "html" do
              context "when error code is unauthorized" do
                let(:code) { :unauthorized }

                it "redirects to ensure_connection url with current request url as a destination_url" do
                  get route, {}, { "HTTP_ACCEPT" => "text/html" }

                  expect(last_response).to have_http_status(:found)
                  expect(last_response.headers["Location"]).to eq (
                    "http://#{Setting.host_name}/oauth_clients/#{storage.oauth_client.client_id}/ensure_connection?destination_url=http%3A%2F%2F#{CGI.escape(Setting.host_name)}%2Fprojects%2F#{project.identifier}%2Fproject_storages%2F#{project_storage.id}%2Fopen&storage_id=#{storage.id}"
                  )
                end
              end

              context "when error code is forbidden" do
                it "redirects to project overview page with modal flash set up" do
                  get route, {}, { "HTTP_ACCEPT" => "text/html" }

                  expect(last_response).to have_http_status(:found)
                  expect(last_response.headers["Location"]).to eq ("http://#{Setting.host_name}/projects/#{project.identifier}")
                  expect(last_request.session["flash"]["flashes"])
                    .to eq({
                             "modal" => {
                               type: "Storages::OpenProjectStorageModalComponent",
                               parameters: { project_storage_open_url: "/projects/#{project.identifier}/project_storages/#{project_storage.id}/open",
                                             redirect_url: expected_redirect_path,
                                             state: :waiting }
                             }
                           })
                end
              end
            end

            context "turbo_stream" do
              it "responds with 204 no content" do
                get route, {}, { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html" }

                expect(last_response).to have_http_status(:no_content)
                expect(last_response.body).to eq ("")
              end
            end
          end
        end

        context "when project_folder_id has not been set by background job yet" do
          context "html" do
            it "redirects to project overview page with modal flash set up" do
              get route, {}, { "HTTP_ACCEPT" => "text/html" }

              expect(last_response).to have_http_status(:found)
              expect(last_response.headers["Location"]).to eq ("http://#{Setting.host_name}/projects/#{project.identifier}")
              expect(last_request.session["flash"]["flashes"])
                .to eq({
                         "modal" => {
                           type: "Storages::OpenProjectStorageModalComponent",
                           parameters: { project_storage_open_url: "/projects/#{project.identifier}/project_storages/#{project_storage.id}/open",
                                         redirect_url: expected_redirect_path,
                                         state: :waiting }
                         }
                       })
            end
          end

          context "turbo_stream" do
            it "responds with 204 no content" do
              get route, {}, { "HTTP_ACCEPT" => "text/vnd.turbo-stream.html" }

              expect(last_response).to have_http_status(:no_content)
              expect(last_response.body).to eq ("")
            end
          end
        end
      end

      context "when project_folder is not automatic" do
        it "redirects to storage_open_url" do
          get route, {}, { "HTTP_ACCEPT" => "text/html" }

          expect(last_response).to have_http_status(:found)
          expect(last_response.headers["Location"]).to eq (expected_redirect_url)
        end
      end
    end

    context "when user has no permissions" do
      let(:permissions) { %i[] }

      it "responds with 403" do
        get route, {}, { "HTTP_ACCEPT" => "text/html" }
        expect(last_response).to have_http_status(:forbidden)
      end
    end
  end

  context "when user is not logged in" do
    it "responds with 401" do
      get route
      expect(last_response).to have_http_status(:unauthorized)
    end
  end
end
