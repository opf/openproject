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

RSpec.describe "SAML provider callback", with_ee: %i[openid_providers] do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:saml_response) do
    xml = File.read("#{File.dirname(__FILE__)}/../fixtures/saml_response.xml")
    Base64.encode64(xml)
  end

  let(:body) do
    { SAMLResponse: saml_response }
  end

  let(:issuer) { "https://foobar.org" }
  let(:fingerprint) { "b711a422a0579da630063cbfac448f90be5ae23f" }

  let(:config) do
    {
      "name" => "saml",
      "display_name" => "SAML",
      "assertion_consumer_service_url" => "http://localhost:3000/auth/saml/callback",
      "issuer" => issuer,
      "idp_cert_fingerprint" => fingerprint,
      "idp_sso_target_url" => "https://foobar.org/login",
      "idp_slo_target_url" => "https://foobar.org/logout",
      "security" => {
        "digest_method" => "http://www.w3.org/2001/04/xmlenc#sha256",
        "check_idp_cert_expiration" => false
      },
      "attribute_statements" => {
        "email" => ["email", "urn:oid:0.9.2342.19200300.100.1.3"],
        "login" => ["uid", "email", "urn:oid:0.9.2342.19200300.100.1.3"],
        "first_name" => ["givenName", "urn:oid:2.5.4.42"],
        "last_name" => ["sn", "urn:oid:2.5.4.4"]
      }
    }
  end

  let(:request) { post "/auth/saml/callback", body }

  subject do
    Timecop.freeze("2023-04-19T09:37:00Z".to_datetime) { request }
  end

  before do
    Setting.plugin_openproject_auth_saml = {
      "providers" => { "saml" => config }
    }
  end

  shared_examples "request fails" do
    it "redirects to the failure page" do
      expect(subject.status).to eq(302)
      expect(subject.headers["Location"]).to eq("/auth/failure?message=invalid_ticket&strategy=saml")
    end
  end

  it "redirects user when no errors occured" do
    expect(subject.status).to eq(302)
    expect(subject.headers["Location"]).to eq("http://#{Setting.host_name}/two_factor_authentication/request")
  end

  context "with an invalid timestamp" do
    subject do
      Timecop.freeze("2023-04-15T09:37:00Z".to_datetime) do
        request
      end
    end

    it_behaves_like "request fails"
  end

  context "with an invalid fingerprint" do
    let(:fingerprint) { "invalid" }

    it_behaves_like "request fails"
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
