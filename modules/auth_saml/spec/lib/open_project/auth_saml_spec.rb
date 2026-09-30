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

require_relative "../../spec_helper"
require "open_project/auth_saml"

RSpec.describe OpenProject::AuthSaml do
  describe ".configuration" do
    let!(:provider) { create(:saml_provider, display_name: "My SSO", slug: "my-saml") }

    subject { described_class.configuration[:"my-saml"] }

    it "contains the configuration from OpenProject::Configuration (or settings.yml) by default",
       :aggregate_failures do
      expect(subject[:name]).to eq "my-saml"
      expect(subject[:display_name]).to eq "My SSO"
      expect(subject[:idp_cert].strip).to eq provider.idp_cert.strip
      expect(subject[:assertion_consumer_service_url]).to eq "http://#{Setting.host_name}/auth/my-saml/callback"
      expect(subject[:idp_sso_service_url]).to eq "https://example.com/sso"
      expect(subject[:idp_slo_service_url]).to eq "https://example.com/slo"
      expect(subject[:limit_self_registration]).to be true

      attributes = subject[:attribute_statements]
      expect(attributes[:email]).to eq Saml::Defaults::MAIL_MAPPING.split("\n")
      expect(attributes[:login]).to eq Saml::Defaults::MAIL_MAPPING.split("\n")
      expect(attributes[:first_name]).to eq Saml::Defaults::FIRSTNAME_MAPPING.split("\n")
      expect(attributes[:last_name]).to eq Saml::Defaults::LASTNAME_MAPPING.split("\n")

      security = subject[:security]
      expect(security[:check_idp_cert_expiration]).to be false
      expect(security[:check_sp_cert_expiration]).to be false
      expect(security[:metadata_signed]).to be false
      expect(security[:authn_requests_signed]).to be false
      expect(security[:want_assertions_signed]).to be false
      expect(security[:want_assertions_encrypted]).to be false
    end

    context "with limit_self_registration: false" do
      let!(:provider) do
        create(:saml_provider, slug: "my-saml", limit_self_registration: false)
      end

      it "includes the false value in the auth hash" do
        expect(subject[:limit_self_registration]).to be false
      end
    end
  end
end
