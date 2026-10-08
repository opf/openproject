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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_context "with a collaboration token endpoint setup" do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:document) { create(:document, project:) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_documents) }
  let(:current_user) { create(:user, member_with_roles: { project => role }) }
  let(:hocuspocus_url) { "wss://hocuspocus.example.com" }
  let(:hocuspocus_secret) { "test_secret_for_encryption" }
  let(:collaboration_enabled) { true }

  before do
    # Settings are stubbed here (instead of via `with_settings` metadata) so that single contexts
    # can override them with a `let`.
    allow(Setting).to receive_messages(real_time_text_collaboration_enabled?: collaboration_enabled,
                                       collaborative_editing_hocuspocus_url: hocuspocus_url,
                                       collaborative_editing_hocuspocus_secret: hocuspocus_secret)
  end

  def post_collaboration_token_request
    header "Content-Type", "application/json"
    post path, request_body&.to_json
  end

  def decrypt_collaboration_token(encrypted_token)
    JSON.parse(Documents::OAuth::DecryptTokenService.new(token: encrypted_token).call.result)
  end

  def collaboration_access_token_for(user)
    Documents::OAuth::GenerateTokenService.new(user:).call.result
  end
end

# Expects the including spec to define `path` and `request_body` and to include
# the "with a collaboration token endpoint setup" context.
RSpec.shared_examples_for "a guarded collaboration token endpoint" do
  def expect_api_error(status, identifier, message = nil)
    expect(last_response).to have_http_status(status)
    expect(last_response.body)
      .to be_json_eql("urn:openproject-org:api:v3:errors:#{identifier}".to_json)
      .at_path("errorIdentifier")
    expect(last_response.body).to be_json_eql(message.to_json).at_path("message") if message
  end

  context "when logged in" do
    before do
      login_as(current_user)
    end

    context "when the document is not visible to the user" do
      let(:document) { create(:document, project: other_project) }

      it "responds with 404" do
        post_collaboration_token_request

        expect_api_error(404, "NotFound")
      end
    end

    # The visibility check already requires the view_documents permission,
    # so a user lacking it can not distinguish the document from a non-existing one.
    context "when the user lacks the view_documents permission in the document's project" do
      let(:permissions) { %i(view_project) }

      it "responds with 404" do
        post_collaboration_token_request

        expect_api_error(404, "NotFound")
      end
    end

    context "when the document is not collaborative" do
      let(:document) { create(:document, project:, kind: "classic") }

      it "responds with 422" do
        post_collaboration_token_request

        expect_api_error(422, "UnprocessableContent",
                         I18n.t("documents.collaboration_token.errors.not_collaborative"))
      end
    end

    context "when real-time collaboration is disabled" do
      let(:collaboration_enabled) { false }

      it "responds with 422" do
        post_collaboration_token_request

        expect_api_error(422, "UnprocessableContent",
                         I18n.t("documents.collaboration_token.errors.collaboration_disabled"))
      end
    end

    it "responds with 201 and forbids caching the response" do
      post_collaboration_token_request

      expect(last_response).to have_http_status(:created)
      expect(last_response.headers["Cache-Control"]).to eq("no-store")
    end

    context "when the user may manage documents" do
      let(:permissions) { %i(view_documents manage_documents) }

      it "responds with a writable token" do
        post_collaboration_token_request

        expect(last_response).to have_http_status(:created)

        payload = decrypt_collaboration_token(JSON.parse(last_response.body)["token"])
        expect(payload["readonly"]).to be(false)
      end
    end

    context "when the user may only view documents" do
      it "responds with a read-only token" do
        post_collaboration_token_request

        expect(last_response).to have_http_status(:created)

        payload = decrypt_collaboration_token(JSON.parse(last_response.body)["token"])
        expect(payload["readonly"]).to be(true)
      end
    end
  end

  context "when authenticated with a bearer token" do
    before do
      header "Authorization", "Bearer #{bearer_token}"
    end

    context "when the token was issued to the collaboration server" do
      let(:bearer_token) { collaboration_access_token_for(current_user).plaintext_token }

      it "responds with 403 insufficient scope" do
        post_collaboration_token_request

        expect_api_error(403, "InsufficientScope",
                         I18n.t("api_v3.errors.insufficient_scope",
                                granted: "'#{Documents::OAuth::EDIT_DOCUMENTS_SCOPE}'",
                                required: "api_v3"))
        expect(last_response.headers["WWW-Authenticate"]).to include('error="insufficient_scope"')
      end
    end

    context "when the token is a regular OAuth access token" do
      let(:bearer_token) { create(:oauth_access_token, resource_owner: current_user).plaintext_token }

      it "responds with 201" do
        post_collaboration_token_request

        expect(last_response).to have_http_status(:created)
      end
    end

    context "when the token is an API key" do
      let(:bearer_token) { create(:api_token, user: current_user).plain_value }

      it "responds with 201" do
        post_collaboration_token_request

        expect(last_response).to have_http_status(:created)
      end
    end
  end

  context "when authenticated with a session" do
    let(:session_data) do
      ActiveSupport::HashWithIndifferentAccess.new(user_id: current_user.id, updated_at: Time.current)
    end

    before do
      allow_any_instance_of(OpenProject::Authentication::Strategies::Warden::Session) # rubocop:disable RSpec/AnyInstance
        .to receive(:session)
        .and_return(session_data)
      header "Sec-Fetch-Site", "same-origin"
    end

    it "responds with 201" do
      post_collaboration_token_request

      expect(last_response).to have_http_status(:created)
    end
  end
end
