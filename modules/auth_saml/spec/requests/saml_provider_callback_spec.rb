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

RSpec.describe "SAML provider callback",
               type: :rails_request,
               with_ee: %i[sso_auth_providers] do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let!(:provider) do
    create(:saml_provider,
           display_name: "SAML",
           slug: "saml",
           digest_method: "http://www.w3.org/2001/04/xmlenc#sha256",
           sp_entity_id: "https://foobar.org",
           idp_cert:,
           idp_cert_fingerprint:)
  end

  let(:idp_cert) { nil }
  let(:idp_cert_fingerprint) { "B7:11:A4:22:A0:57:9D:A6:30:06:3C:BF:AC:44:8F:90:BE:5A:E2:3F" }

  let(:saml_response) do
    xml = File.read("#{File.dirname(__FILE__)}/../fixtures/saml_response.xml")
    Base64.encode64(xml)
  end

  let(:body) do
    { SAMLResponse: saml_response }
  end

  let(:request) do
    post "/auth/saml/callback", body
  end

  subject do
    Timecop.freeze("2024-08-22T09:22:00Z".to_datetime) { request }
  end

  shared_examples "request fails" do |message|
    it "redirects to the failure page" do
      expect(subject.status).to eq(302)
      follow_redirect!
      expect(last_response.body).to have_text message
    end
  end

  shared_examples "request succeeds" do
    it "redirects user when no errors occured" do
      expect(subject.status).to eq(302)
      expect(subject.headers["Location"]).to eq("http://#{Setting.host_name}/two_factor_authentication/request")
    end
  end

  context "with valid basic configuration" do
    it_behaves_like "request succeeds"
  end

  context "with an invalid timestamp" do
    subject do
      Timecop.freeze("2023-04-15T09:37:00Z".to_datetime) do
        request
      end
    end

    it_behaves_like "request fails", "Current time is earlier than NotBefore condition"
  end

  context "with an invalid fingerprint" do
    let(:idp_cert_fingerprint) { "invalid" }

    it_behaves_like "request fails"
  end

  context "when providing the valid certificate" do
    let(:idp_cert) { File.read(Rails.root.join("modules/auth_saml/spec/fixtures/idp_cert_plain.txt").to_s) }
    let(:idp_cert_fingerprint) { nil }

    it_behaves_like "request succeeds"
  end

  context "when providing an invalid certificate" do
    let(:idp_cert) { CertificateHelper.expired_certificate.to_pem }
    let(:idp_cert_fingerprint) { nil }

    it_behaves_like "request fails", "Fingerprint mismatch"
  end

  context "with a RelayState present" do
    let(:body) do
      { SAMLResponse: saml_response, RelayState: "/projects?some_param=true" }
    end

    it "redirects the user to 2FA, but with back_url present in session" do
      expect(subject.status).to eq(302)
      expect(subject.headers["Location"]).to eq("http://test.host/two_factor_authentication/request")

      session = Sessions::SqlBypass.lookup_data(subject.cookies["_open_project_session"].first)
      expect(session["back_url"]).to eq "/projects?some_param=true"
    end

    context "when 2FA is disabled", :skip_2fa_stage do
      it "redirects directly" do
        expect(subject.status).to eq(302)
        expect(subject.headers["Location"]).to eq("http://test.host/projects?some_param=true")
      end
    end
  end
end
