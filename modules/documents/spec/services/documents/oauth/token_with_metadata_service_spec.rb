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

RSpec.describe Documents::OAuth::TokenWithMetadataService,
               with_settings: { collaborative_editing_hocuspocus_secret: "test_secret_for_encryption" } do
  subject(:service_call) { described_class.new(user:, document:, project:).call }

  let(:project) { create(:project) }
  let(:document) { create(:document, project:) }
  let(:manage_role) { create(:project_role, permissions: %i[view_documents manage_documents]) }
  let(:view_only_role) { create(:project_role, permissions: [:view_documents]) }
  let(:user) { create(:user, member_with_roles: { project => manage_role }) }

  def decrypt_token(encrypted_token)
    key = Digest::SHA256.digest("test_secret_for_encryption")
    encryptor = ActiveSupport::MessageEncryptor.new(
      key,
      cipher: "aes-256-gcm",
      serializer: ActiveSupport::MessageEncryptor::NullSerializer
    )
    encryptor.decrypt_and_verify(encrypted_token)
  end

  describe "#call" do
    it "returns a successful service result" do
      expect(service_call).to be_success
    end

    it "returns an encrypted token containing packed params",
       freeze_time: DateTime.parse("2025-01-04T9:00:00Z") do
      result = service_call.result

      expect(result[:encrypted_token]).to be_a(String)
      expect(result[:encrypted_token]).not_to be_empty

      # Verify the encrypted token contains packed params by decrypting
      decrypted = decrypt_token(result[:encrypted_token])
      payload = JSON.parse(decrypted)

      expect(payload["resource_url"]).to include("/api/v3/documents/#{document.id}")
      expect(payload["oauth_token"]).to be_present
      expect(payload["readonly"]).to be false
      expect(payload["expires_at"]).to eq("2025-01-04T09:05:00Z")
    end

    it "returns resource_url in the result" do
      result = service_call.result

      expect(result[:resource_url]).to include("/api/v3/documents/#{document.id}")
    end

    it "returns readonly in the result" do
      result = service_call.result

      expect(result[:readonly]).to be false
    end

    it "returns expires_in_seconds matching the token expiry" do
      result = service_call.result

      expect(result[:expires_in_seconds]).to eq(5.minutes.to_i)
    end

    it "creates a new access token" do
      expect { service_call }.to change(Doorkeeper::AccessToken, :count).by(1)
    end

    context "when user only has view_documents permission (readonly)" do
      let(:user) { create(:user, member_with_roles: { project => view_only_role }) }

      it "includes readonly: true in the packed params" do
        result = service_call.result
        decrypted = decrypt_token(result[:encrypted_token])
        payload = JSON.parse(decrypted)

        expect(payload["readonly"]).to be true
      end
    end
  end

  context "when token generation fails" do
    before do
      allow_any_instance_of(Documents::OAuth::GenerateTokenService) # rubocop:disable RSpec/AnyInstance
        .to receive(:call)
        .and_return(ServiceResult.failure(errors: "Token generation failed"))

      allow(Rails.logger).to receive(:error)
    end

    it "returns a failure, logs error message" do
      expect(service_call).to be_failure

      expect(Rails.logger).to have_received(:error)
        .with("Failed to generate OAuth token for document #{document.id}: Token generation failed")
    end
  end

  context "when encryption fails" do
    before do
      allow(Setting)
        .to receive(:collaborative_editing_hocuspocus_secret)
        .and_return(nil)

      allow(Rails.logger).to receive(:error)
    end

    it "returns a failure, logs error message" do
      expect(service_call).to be_failure
      expect(Rails.logger).to have_received(:error)
        .with("Failed to encrypt OAuth token payload for document #{document.id}: " \
              "Collaborative editing secret is not set. Cannot encrypt token.")
    end
  end
end
