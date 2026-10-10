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

RSpec.describe "API v3 access with the edit documents scope" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  include_context "with a collaboration token endpoint setup"

  let(:permissions) { %i(view_documents manage_documents) }
  let(:access_token) { collaboration_access_token_for(current_user) }

  before do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
  end

  def request_with_json(method, path, body = nil)
    header "Content-Type", "application/json"
    public_send(method, path, body&.to_json)
  end

  describe "the endpoints opting into the scope" do
    it "allows reading the document" do
      get api_v3_paths.document(document.id)

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to be_json_eql(document.id.to_json).at_path("id")
    end

    it "allows updating the document" do
      request_with_json(:patch, api_v3_paths.document(document.id), { title: "Updated by collaboration" })

      expect(last_response).to have_http_status(:ok)
      expect(document.reload.title).to eq("Updated by collaboration")
    end
  end

  describe "all other endpoints" do
    let(:expected_message) do
      I18n.t("api_v3.errors.insufficient_scope",
             granted: "'#{Documents::OAuth::EDIT_DOCUMENTS_SCOPE}'",
             required: "api_v3")
    end
    let(:expected_www_authenticate) do
      'Bearer realm="OpenProject API", ' \
        'resource_metadata="http://test.host/.well-known/oauth-protected-resource", ' \
        'scope="api_v3", error="insufficient_scope"'
    end

    let(:request_method) { :get }
    let(:body) { nil }

    shared_examples "rejects the edit documents scope" do
      it "responds with 403 InsufficientScope" do
        request_with_json(request_method, path, body)

        expect(last_response).to have_http_status(:forbidden)
        expect(last_response.headers["WWW-Authenticate"]).to eq(expected_www_authenticate)
        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:InsufficientScope".to_json)
          .at_path("errorIdentifier")
        expect(last_response.body).to be_json_eql(expected_message.to_json).at_path("message")
      end
    end

    context "for GET /api/v3/users/me" do
      let(:path) { api_v3_paths.user("me") }

      it_behaves_like "rejects the edit documents scope"
    end

    context "for GET /api/v3/work_packages" do
      let(:path) { api_v3_paths.work_packages }

      it_behaves_like "rejects the edit documents scope"
    end

    context "for GET /api/v3/documents" do
      let(:path) { api_v3_paths.documents }

      it_behaves_like "rejects the edit documents scope"
    end

    context "for GET /api/v3/documents/:id/attachments" do
      let(:path) { api_v3_paths.attachments_by_document(document.id) }

      it_behaves_like "rejects the edit documents scope"
    end

    context "for POST /api/v3/documents/:id/collaboration_token" do
      let(:request_method) { :post }
      let(:path) { api_v3_paths.document_collaboration_token(document.id) }

      it_behaves_like "rejects the edit documents scope"
    end

    context "for POST /api/v3/documents/:id/collaboration_token with a previous token" do
      let(:request_method) { :post }
      let(:path) { api_v3_paths.document_collaboration_token(document.id) }
      let(:body) { { token: "irrelevant" } }

      it_behaves_like "rejects the edit documents scope"
    end
  end

  context "with an api_v3 access token" do
    let(:access_token) { create(:oauth_access_token, resource_owner: current_user) }

    it "allows reading the user, the documents and their attachments" do
      [api_v3_paths.user("me"),
       api_v3_paths.documents,
       api_v3_paths.document(document.id),
       api_v3_paths.attachments_by_document(document.id)].each do |path|
        get path

        expect(last_response).to have_http_status(:ok), "expected #{path} to respond with 200"
      end
    end
  end
end
