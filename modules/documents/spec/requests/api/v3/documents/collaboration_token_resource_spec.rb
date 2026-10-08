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

require "spec_helper"
require "rack/test"
require_relative "../../../../support/shared/collaboration_token_endpoint"

RSpec.describe "API v3 document collaboration token resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  include_context "with a collaboration token endpoint setup"

  let(:path) { api_v3_paths.document_collaboration_token(document.id) }
  let(:request_body) { nil }

  describe "POST /api/v3/documents/:id/collaboration_token" do
    it_behaves_like "a guarded collaboration token endpoint"

    context "when logged in with the view_documents permission",
            freeze_time: DateTime.parse("2025-01-04T09:00:00Z") do
      let(:response_body) { JSON.parse(last_response.body) }
      let(:expected_document_name) { "http://#{Setting.host_name}#{api_v3_paths.document(document.id)}" }

      before do
        login_as(current_user)

        post_collaboration_token_request
      end

      it "responds with 201 and a collaboration token" do
        expect(last_response).to have_http_status(:created)

        expect(response_body).to include(
          "_type" => "CollaborationToken",
          "documentName" => expected_document_name,
          "expiresAt" => "2025-01-04T09:05:00Z",
          "expiresInSeconds" => 300
        )
      end

      it "returns an encrypted token for the document and the user" do
        payload = decrypt_collaboration_token(response_body["token"])

        expect(payload["resource_url"]).to eq(expected_document_name)
        expect(payload["expires_at"]).to eq("2025-01-04T09:05:00Z")

        access_token = Doorkeeper::AccessToken.by_token(payload["oauth_token"])
        expect(access_token.resource_owner_id).to eq(current_user.id)
        expect(access_token.expires_in).to eq(5.minutes.to_i)
        expect(access_token.application.uid).to eq(Documents::OAuth::EnsureApplicationService::APPLICATION_UID)
        expect(access_token.scopes.to_a).to eq([Documents::OAuth::EDIT_DOCUMENTS_SCOPE])
      end

      it "does not expose the plain OAuth token" do
        payload = decrypt_collaboration_token(response_body["token"])

        expect(last_response.body).not_to include(payload["oauth_token"])
      end

      it "links the document, the createCollaborationToken action and the collaboration server" do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.document(document.id).to_json)
          .at_path("_links/document/href")
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.document_collaboration_token(document.id).to_json)
          .at_path("_links/createCollaborationToken/href")
        expect(last_response.body)
          .to be_json_eql("post".to_json)
          .at_path("_links/createCollaborationToken/method")
        expect(last_response.body)
          .to be_json_eql(hocuspocus_url.to_json)
          .at_path("_links/collaborationServer/href")
        expect(last_response.body).not_to have_json_path("_links/self")
      end
    end

    context "when creating the token fails" do
      before do
        login_as(current_user)

        allow(Documents::OAuth::TokenWithMetadataService)
          .to receive(:new)
          .and_return(instance_double(Documents::OAuth::TokenWithMetadataService,
                                      call: ServiceResult.failure(errors: "Something went wrong")))

        post_collaboration_token_request
      end

      it "responds with 500" do
        expect(last_response).to have_http_status(:internal_server_error)
        expect(last_response.body).not_to include("Something went wrong")
      end
    end

    shared_examples "creates a new token without revoking any" do
      before do
        login_as(current_user)
      end

      it "responds with 201" do
        expect { post_collaboration_token_request }.to change(Doorkeeper::AccessToken, :count).by(1)

        expect(last_response).to have_http_status(:created)
        expect(Doorkeeper::AccessToken.where.not(revoked_at: nil)).to be_empty
      end
    end

    context "with an empty request body" do
      let(:request_body) { {} }

      it_behaves_like "creates a new token without revoking any"
    end

    context "with a blank token" do
      let(:request_body) { { token: "" } }

      it_behaves_like "creates a new token without revoking any"
    end

    context "with a previous token" do
      let(:previous_token) { mint_previous_token(user: current_user, document:) }
      let(:request_body) { { token: previous_token } }
      let(:previous_access_token) do
        Doorkeeper::AccessToken.by_token(decrypt_collaboration_token(previous_token)["oauth_token"])
      end

      def mint_previous_token(user:, document:)
        Documents::OAuth::TokenWithMetadataService
          .new(user:, document:, project: document.project)
          .call
          .result[:encrypted_token]
      end

      it_behaves_like "a guarded collaboration token endpoint"

      context "when logged in" do
        let(:response_body) { JSON.parse(last_response.body) }

        before do
          login_as(current_user)
        end

        context "with a valid previous token", freeze_time: DateTime.parse("2025-01-04T09:00:00Z") do
          let(:previous_oauth_token) { decrypt_collaboration_token(previous_token)["oauth_token"] }

          before do
            previous_token

            post_collaboration_token_request
          end

          it "responds with 201 and a new collaboration token" do
            expect(last_response).to have_http_status(:created)
            expect(last_response.headers["Cache-Control"]).to eq("no-store")

            expect(response_body).to include("_type" => "CollaborationToken",
                                             "expiresAt" => "2025-01-04T09:05:00Z",
                                             "expiresInSeconds" => 300)
            expect(response_body["token"]).not_to eq(previous_token)

            payload = decrypt_collaboration_token(response_body["token"])
            expect(payload["oauth_token"]).not_to eq(previous_oauth_token)
            expect(payload["resource_url"]).to eq(response_body["documentName"])
          end

          it "revokes the previous OAuth token 30 seconds later" do
            expect(previous_access_token.revoked_at)
              .to eq(Time.current + Documents::OAuth::TokenWithMetadataService::PREVIOUS_TOKEN_REVOCATION_DELAY)
          end

          it "keeps the previous OAuth token usable until it is revoked" do
            header "Authorization", "Bearer #{previous_oauth_token}"

            get api_v3_paths.document(document.id)
            expect(last_response).to have_http_status(:ok)

            travel(Documents::OAuth::TokenWithMetadataService::PREVIOUS_TOKEN_REVOCATION_DELAY + 1.second)

            get api_v3_paths.document(document.id)
            expect(last_response).to have_http_status(:unauthorized)
          end
        end

        context "with an expired previous token" do
          before do
            previous_token
            travel 10.minutes

            post_collaboration_token_request
          end

          it "responds with 201" do
            expect(last_response).to have_http_status(:created)
            expect(previous_access_token.revoked_at).to be_present
          end
        end

        shared_examples "rejects the already revoked previous token" do
          before do
            previous_access_token.update_column(:revoked_at, revoked_at)
          end

          it "responds with 422 and neither creates a token nor changes the revocation" do
            expect { post_collaboration_token_request }.not_to change(Doorkeeper::AccessToken, :count)

            expect(last_response).to have_http_status(422)
            expect(last_response.body)
              .to be_json_eql(I18n.t("documents.collaboration_token.errors.invalid_previous_token").to_json)
              .at_path("message")
            expect(previous_access_token.reload.revoked_at).to eq(revoked_at)
          end
        end

        context "with an already revoked previous token" do
          let(:revoked_at) { 1.minute.ago.change(usec: 0) }

          it_behaves_like "rejects the already revoked previous token"
        end

        context "with an already revoked previous token that is still within the revocation delay" do
          let(:revoked_at) { 10.seconds.from_now.change(usec: 0) }

          it_behaves_like "rejects the already revoked previous token"
        end

        shared_examples "rejects the previous token" do
          it "responds with 422 and neither revokes nor creates a token" do
            previous_token

            expect { post_collaboration_token_request }.not_to change(Doorkeeper::AccessToken, :count)

            expect(last_response).to have_http_status(422)
            expect(last_response.body)
              .to be_json_eql("urn:openproject-org:api:v3:errors:UnprocessableContent".to_json)
              .at_path("errorIdentifier")
            expect(last_response.body)
              .to be_json_eql(I18n.t("documents.collaboration_token.errors.invalid_previous_token").to_json)
              .at_path("message")
            expect(Doorkeeper::AccessToken.where.not(revoked_at: nil)).to be_empty
          end
        end

        context "with a garbage token" do
          let(:previous_token) { "garbage" }

          it_behaves_like "rejects the previous token"
        end

        context "with a tampered token" do
          let(:previous_token) { mint_previous_token(user: current_user, document:).reverse }

          it_behaves_like "rejects the previous token"
        end

        context "with a token for another document" do
          let(:previous_token) { mint_previous_token(user: current_user, document: create(:document, project:)) }

          it_behaves_like "rejects the previous token"
        end

        context "with a token belonging to another user" do
          let(:other_user) { create(:user, member_with_roles: { project => role }) }
          let(:previous_token) { mint_previous_token(user: other_user, document:) }

          it_behaves_like "rejects the previous token"
        end

        context "with a token whose OAuth token lacks the edit documents scope" do
          let(:previous_token) do
            payload = {
              resource_url: "http://#{Setting.host_name}#{api_v3_paths.document(document.id)}",
              oauth_token: create(:oauth_access_token, resource_owner: current_user).plaintext_token,
              expires_at: 5.minutes.from_now.iso8601,
              readonly: true
            }

            Documents::OAuth::EncryptTokenService.new(token: payload.to_json).call.result
          end

          it_behaves_like "rejects the previous token"
        end
      end
    end
  end
end
