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

RSpec.describe "Document token refresh",
               type: :rails_request,
               with_settings: { real_time_text_collaboration_enabled: true } do
  let(:password) { "adminADMIN!" }
  let(:project) { create(:project, public: false) }
  let(:document) { create(:document, project:) }
  let(:role) { create(:project_role, permissions: %i[view_project view_documents]) }
  let!(:user) do
    create(:user, password:, password_confirmation: password, member_with_roles: { project => role })
  end
  let(:path) { "/projects/#{project.id}/documents/#{document.id}/refresh_token" }

  before do
    # The login flow would otherwise stop at a second-factor prompt.
    allow(OpenProject::TwoFactorAuthentication::TokenStrategyManager).to receive(:enabled?).and_return(false)
    allow(Setting)
      .to receive(:collaborative_editing_hocuspocus_secret)
      .and_return("test_secret_for_encryption")
  end

  def page_csrf_token
    response.parsed_body.at_css("meta[name=csrf-token]")["content"]
  end

  def sign_in_through_login_form
    get "/login"
    form_token = response.parsed_body.at_css("input[name=authenticity_token]")["value"]
    post "/login", params: { username: user.login, password:, authenticity_token: form_token }
    get "/projects/#{project.id}"
    page_csrf_token
  end

  def request_token(csrf_token:)
    headers = { "ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json" }
    headers["X-CSRF-Token"] = csrf_token if csrf_token
    post path, headers:
  end

  def end_session_on_server
    Sessions::UserSession.for_user(user).delete_all
  end

  context "with a valid session and access" do
    it "responds with 200 and an encrypted token with its lifetime" do
      request_token(csrf_token: sign_in_through_login_form)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("encrypted_token", "expires_in_seconds")
    end
  end

  context "when the user is no longer a member of the private project" do
    it "responds with 404" do
      csrf_token = sign_in_through_login_form
      Member.where(user_id: user.id).destroy_all

      request_token(csrf_token:)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the member's role lacks view_documents" do
    let(:role) { create(:project_role, permissions: %i[view_project]) }

    it "responds with 403" do
      request_token(csrf_token: sign_in_through_login_form)

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the document does not exist" do
    let(:path) { "/projects/#{project.id}/documents/999999/refresh_token" }

    it "responds with 404" do
      request_token(csrf_token: sign_in_through_login_form)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the session was ended on the server and login is required", with_settings: { login_required: true } do
    it "fails authentication with 401 rather than failing validation with 422" do
      csrf_token = sign_in_through_login_form
      end_session_on_server

      request_token(csrf_token:)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when the session was ended on the server, login is not required and the project is private",
          with_settings: { login_required: false } do
    it "responds with 404 rather than failing validation with 422" do
      csrf_token = sign_in_through_login_form
      end_session_on_server

      request_token(csrf_token:)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the request carries no valid CSRF token" do
    it "fails authentication with 401 rather than failing validation with 422" do
      sign_in_through_login_form

      request_token(csrf_token: nil)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
