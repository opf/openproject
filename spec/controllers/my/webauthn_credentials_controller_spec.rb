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

RSpec.describe My::WebauthnCredentialsController do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "GET #new" do
    context "when passkey authentication is disabled" do
      it "is not found" do
        get :new

        expect(response).to have_http_status :not_found
      end
    end

    context "when passkey authentication is enabled", with_settings: { passkey_authentication_enabled: true } do
      let(:relying_party) { instance_double(WebAuthn::RelyingParty) }
      # rubocop:disable RSpec/VerifiedDoubles
      let(:options) { double("options", challenge: "test-challenge", as_json: { challenge: "test-challenge" }) }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        allow(WebAuthn::RelyingParty).to receive(:new).and_return(relying_party)
        allow(relying_party).to receive(:options_for_registration).and_return(options)
      end

      it "assigns the user a webauthn_id and stashes the registration challenge" do
        get :new

        expect(response).to be_successful
        expect(user.reload.webauthn_id).to be_present
        expect(session[:webauthn_registration_challenge]).to eq("test-challenge")
      end
    end
  end

  describe "POST #create" do
    let(:relying_party) { instance_double(WebAuthn::RelyingParty) }
    let(:credential_param) { { id: "new-external-id" }.to_json }
    # rubocop:disable RSpec/VerifiedDoubles
    let(:verified) { double("verified", id: "new-external-id", public_key: "new-public-key", sign_count: 0) }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(WebAuthn::RelyingParty).to receive(:new).and_return(relying_party)
      session[:webauthn_registration_challenge] = "test-challenge"
    end

    context "when verification succeeds" do
      before do
        allow(relying_party)
          .to receive(:verify_registration)
          .with({ "id" => "new-external-id" }, "test-challenge")
          .and_return(verified)

        post :create, params: { credential: credential_param }
      end

      it "creates a webauthn credential for the current user" do
        expect(user.webauthn_credentials.reload.pluck(:external_id)).to contain_exactly("new-external-id")
        expect(response).to redirect_to my_security_path
      end
    end

    context "when verification fails" do
      before do
        allow(relying_party).to receive(:verify_registration).and_raise(WebAuthn::Error)

        post :create, params: { credential: credential_param }
      end

      it "does not create a credential" do
        expect(user.webauthn_credentials.reload).to be_empty
        expect(flash[:error]).to be_present
        expect(response).to redirect_to my_security_path
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:credential) { create(:webauthn_credential, user:) }

    context "when the credential belongs to the current user" do
      it "removes it" do
        delete :destroy, params: { id: credential.id }

        expect(WebauthnCredential.exists?(credential.id)).to be false
        expect(response).to redirect_to my_security_path
      end
    end

    context "when the credential belongs to another user" do
      let!(:credential) { create(:webauthn_credential, user: create(:user)) }

      it "is not found" do
        delete :destroy, params: { id: credential.id }

        expect(response).to have_http_status :not_found
        expect(WebauthnCredential.exists?(credential.id)).to be true
      end
    end
  end
end
