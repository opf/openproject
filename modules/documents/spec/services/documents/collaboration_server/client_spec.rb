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

RSpec.describe Documents::CollaborationServer::Client,
               with_settings: {
                 collaborative_editing_hocuspocus_url: "wss://hocuspocus.local/collab/",
                 collaborative_editing_hocuspocus_secret: "secret12345"
               } do
  subject(:client) { described_class.new(user:, document:) }

  let(:user) { create(:user, member_with_permissions: { document.project => %i[view_documents manage_documents] }) }
  let(:document) { create(:document, :collaborative) }
  let(:content_url) { "https://hocuspocus.local/collab/api/v1/documents/content" }
  let(:blocks) { [{ "id" => "a", "type" => "paragraph", "content" => [], "children" => [] }] }

  describe ".base_url" do
    it "derives the HTTP URL from the websocket URL" do
      expect(described_class.base_url).to eq("https://hocuspocus.local/collab")
    end

    context "with an unencrypted websocket URL",
            with_settings: { collaborative_editing_hocuspocus_url: "ws://hocuspocus:1234" } do
      it "uses plain HTTP" do
        expect(described_class.base_url).to eq("http://hocuspocus:1234")
      end
    end

    context "with an explicitly configured API URL",
            with_settings: { collaborative_editing_hocuspocus_api_url: "http://hocuspocus-internal:1234/" } do
      it "uses the API URL" do
        expect(described_class.base_url).to eq("http://hocuspocus-internal:1234")
      end
    end

    context "without any hocuspocus URL", with_settings: { collaborative_editing_hocuspocus_url: nil } do
      it "is nil" do
        expect(described_class.base_url).to be_nil
      end
    end
  end

  describe "#content" do
    let!(:content_request) do
      stub_request(:get, content_url)
        .with(headers: { "Authorization" => /\ABearer .+--.+--.+\z/ })
        .to_return(status: 200,
                   body: { revision: "abc", blocks: }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "returns the content read from the collaboration server" do
      result = client.content

      expect(result).to be_success
      expect(result.result).to eq("revision" => "abc", "blocks" => blocks)
      expect(content_request).to have_been_requested
    end

    it "authenticates with a token for the document" do
      client.content

      expect(WebMock).to(have_requested(:get, content_url).with do |request|
        encrypted = request.headers["Authorization"].delete_prefix("Bearer ")
        encryptor = ActiveSupport::MessageEncryptor.new(Digest::SHA256.digest("secret12345"),
                                                        cipher: "aes-256-gcm",
                                                        serializer: ActiveSupport::MessageEncryptor::NullSerializer)
        payload = JSON.parse(encryptor.decrypt_and_verify(encrypted))

        payload["resource_url"].end_with?("/api/v3/documents/#{document.id}") && !payload["readonly"]
      end)
    end
  end

  describe "#update_content" do
    it "sends the revision and blocks" do
      stub_request(:put, content_url)
        .with(body: { revision: "abc", blocks: }.to_json)
        .to_return(status: 200, body: { revision: "def", blocks: }.to_json)

      result = client.update_content(revision: "abc", blocks:)

      expect(result).to be_success
      expect(result.result["revision"]).to eq("def")
    end

    it "reports validation errors" do
      stub_request(:put, content_url)
        .to_return(status: 422, body: { error: "The blocks do not match the document schema.",
                                        errors: ["/0/type must be equal to one of the allowed values"] }.to_json)

      result = client.update_content(revision: "abc", blocks:)

      expect(result).to be_failure
      expect(result.message).to eq("The blocks do not match the document schema.\n" \
                                   "/0/type must be equal to one of the allowed values")
    end

    it "reports conflicting blocks" do
      stub_request(:put, content_url)
        .to_return(status: 409, body: { error: "Conflict.", reason: "content", blockIds: ["a"] }.to_json)

      expect(client.update_content(revision: "abc", blocks:).message).to eq("Conflict.\nConflicting block: a")
    end
  end

  describe "#schema" do
    subject(:client) { described_class.new(user:) }

    it "returns the schema without authenticating" do
      stub_request(:get, "https://hocuspocus.local/collab/api/v1/documents/schema")
        .with { |request| !request.headers.key?("Authorization") }
        .to_return(status: 200, body: { type: "array" }.to_json)

      expect(client.schema.result).to eq("type" => "array")
    end
  end

  context "when the collaboration server is unreachable" do
    before do
      stub_request(:get, content_url).to_raise(HTTPX::ConnectionError.new("refused"))
    end

    it "fails with a readable message" do
      result = client.content

      expect(result).to be_failure
      expect(result.message).to eq("The collaboration server could not be reached.")
    end
  end

  context "when no collaboration server is configured", with_settings: { collaborative_editing_hocuspocus_url: nil } do
    it "fails without making a request" do
      result = client.content

      expect(result).to be_failure
      expect(result.message).to eq("No collaboration server is configured.")
    end
  end
end
