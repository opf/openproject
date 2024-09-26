require "#{File.dirname(__FILE__)}/../../spec_helper"
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
  end
end
