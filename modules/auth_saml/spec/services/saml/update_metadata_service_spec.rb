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

RSpec.describe Saml::UpdateMetadataService do
  subject(:parse_metadata) { described_class.new(user:, provider:).call }

  let(:user) { create(:user) }
  let(:provider) { Saml::Provider.new(metadata_xml:) }

  describe "#idp_cert" do
    let(:certificate) do
      "MIIC/TCCAeWgAwIBAgIICu+WfBLOqBAwDQYJKoZIhvcNAQELBQAwLTErMCkGA1UE\n" \
        "AxMiYWNjb3VudHMuYWNjZXNzY29udHJvbC53aW5kb3dzLm5ldDAeFw0yNTAzMTYy\n" \
        "MDE3MjNaFw0zMDAzMTYyMDE3MjNaMC0xKzApBgNVBAMTImFjY291bnRzLmFjY2Vz\n" \
        "c2NvbnRyb2wud2luZG93cy5uZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK\n" \
        "AoIBAQCHPp9RIJIC6LJDPovWdCPjNryQi168nPGFVt5wyKBMiX2ldlIdlreDMyC1\n" \
        "qmdvWr3oIbmq9Hvx0fpm9MovwzM3hV8aBmG8sS/kskp6jS0aAEhLrnDEiIliP0TE\n" \
        "QOoWTD1F2FbWc3wg3147vo9sL590Q+0N6QDYFohNjYMBEhIo3gp7REsERY2sp4SO\n" \
        "M7OvKBLZ7dD01XMTnVkYZAAYdq7tq0fLwz+oDWed3Z0xSBQycRggzMMFNIrPXsbq\n" \
        "K0k51qca8bfBe92md0p9+cOmlo+TJZufJt0wjgg/urpawKqe3ca2D5toboYOplBA\n" \
        "QGn0L2AsAW/g5FNGWkPfDSAIyHvHAgMBAAGjITAfMB0GA1UdDgQWBBSsQvFDUwCT\n" \
        "JXK+ltZFLaHUGzIS6jANBgkqhkiG9w0BAQsFAAOCAQEAUsfNQA+O7eXGI4IL/Fma\n" \
        "fEmmFjoXC+Ym9UIzG/vXcXzQEK9S9nV35Q0Fn9PsL1w8Sud3itm/V6t9UtB9yaRv\n" \
        "WREPOdEYsHEkZahoSFi2fgOLP+AsTtQq0ePeBbqAQvnfrTvFuv+j1we3uxxov77p\n" \
        "t7U+pB+6Sq8+yww85qeTCWmV4av2WWXB+6pW9oUd/D9htlxKL5WzNsaVojP56eg3\n" \
        "mwhBmOpqxkYnL7RAPGOYRjaeHic9ONrctC8HImjf21UC5wK8G/lcVQATcvPZm/AY\n" \
        "Jg10fNsxZ/8ApFLblf9Q8l0QcKZfjs/si3VKcWvilDrfO9Dg83Ou6tvsLnPU5lV3\n" \
        "aA=="
    end
    let(:formatted_certificate) { "-----BEGIN CERTIFICATE-----\n#{certificate}\n-----END CERTIFICATE-----" }

    context "when the SAML contains a single signing certificate" do
      let(:metadata_xml) do
        <<~SAML
          <md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
            xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://keycloak.local/realms/master">
            <md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <md:KeyDescriptor use="signing">
                <ds:KeyInfo>
                  <ds:X509Data>
                    <ds:X509Certificate>
                      #{saml_certificate}
                    </ds:X509Certificate>
                  </ds:X509Data>
                </ds:KeyInfo>
              </md:KeyDescriptor>
            </md:IDPSSODescriptor>
          </md:EntityDescriptor>
        SAML
      end
      let(:saml_certificate) { certificate }

      it "populates a single IDP certificate" do
        parse_metadata

        expect(provider.idp_cert).to eq(formatted_certificate)
      end

      context "when the certificate inside the SAML is not pretty-printed" do
        let(:saml_certificate) { certificate.tr("\n", "") }

        it "populates the IDP certificate with a pretty-printed representation" do
          parse_metadata

          expect(provider.idp_cert).to eq(formatted_certificate)
        end
      end
    end

    context "when the SAML contains a single encryption certificate" do
      let(:metadata_xml) do
        <<~SAML
          <md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
            xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://keycloak.local/realms/master">
            <md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <md:KeyDescriptor use="encryption">
                <ds:KeyInfo>
                  <ds:X509Data>
                    <ds:X509Certificate>
                      #{saml_certificate}
                    </ds:X509Certificate>
                  </ds:X509Data>
                </ds:KeyInfo>
              </md:KeyDescriptor>
            </md:IDPSSODescriptor>
          </md:EntityDescriptor>
        SAML
      end
      let(:saml_certificate) { certificate }

      it "populates a single IDP certificate" do
        parse_metadata

        expect(provider.idp_cert).to eq(formatted_certificate)
      end
    end

    context "when the SAML contains a certificate for both encryption and signing" do
      let(:metadata_xml) do
        <<~SAML
          <md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
            xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://keycloak.local/realms/master">
            <md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <md:KeyDescriptor use="signing">
                <ds:KeyInfo>
                  <ds:X509Data>
                    <ds:X509Certificate>
                      #{saml_certificate}
                    </ds:X509Certificate>
                  </ds:X509Data>
                </ds:KeyInfo>
              </md:KeyDescriptor>
              <md:KeyDescriptor use="encryption">
                <ds:KeyInfo>
                  <ds:X509Data>
                    <ds:X509Certificate>
                      #{saml_certificate}
                    </ds:X509Certificate>
                  </ds:X509Data>
                </ds:KeyInfo>
              </md:KeyDescriptor>
            </md:IDPSSODescriptor>
          </md:EntityDescriptor>
        SAML
      end
      let(:saml_certificate) { certificate }

      it "populates a single IDP certificate" do
        parse_metadata

        expect(provider.idp_cert).to eq(formatted_certificate)
      end
    end

    context "when the SAML contains multiple certificates" do
      let(:metadata_xml) do
        descriptors = certificates.map do |certificate|
          <<~SAML
            <md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data><ds:X509Certificate>
              #{certificate}
            </ds:X509Certificate></ds:X509Data></ds:KeyInfo></md:KeyDescriptor>
          SAML
        end

        <<~SAML
          <md:EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
            xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://keycloak.local/realms/master">
            <md:IDPSSODescriptor WantAuthnRequestsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              #{descriptors.join("\n")}
            </md:IDPSSODescriptor>
          </md:EntityDescriptor>
        SAML
      end

      let(:certificates) do
        [
          "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"
        ]
      end

      it "populates multiple IDP certificates" do
        parse_metadata

        certificates.each do |cert|
          expect(provider.idp_cert.tr("\n", "")).to include(cert)
        end
      end
    end
  end

  describe "metadata URL fetching" do
    let(:metadata_url) { "https://example.com/metadata" }
    let(:provider) { Saml::Provider.new(metadata_url:) }
    let(:parser_instance) { instance_double(OneLogin::RubySaml::IdpMetadataParser) }
    let(:http_response) { instance_double(Net::HTTPSuccess) }

    before do
      allow(OneLogin::RubySaml::IdpMetadataParser).to receive(:new).and_return(parser_instance)
      allow(parser_instance).to receive(:parse_to_hash).and_return({})
      allow(Saml::MetadataDocument).to receive(:prepare).and_return("<xml/>")
      allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(http_response).to receive(:read_body).and_yield("<metadata/>")
      allow(OpenProject::SsrfProtection).to receive(:get)
    end

    context "when the URL host resolves to a safe IP" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(IPAddr.new("93.184.216.34"))
        allow(OpenProject::SsrfProtection).to receive(:get).and_yield(http_response)
      end

      it "checks the host, fetches metadata via MetadataFetcher, and cleans up the tempfile" do
        fetched_file = nil
        allow(Saml::MetadataDocument).to receive(:prepare) do |file, **|
          fetched_file = file
          "<xml/>"
        end

        parse_metadata

        expect(OpenProject::SsrfProtection).to have_received(:safe_ip?).with("example.com")
        expect(OpenProject::SsrfProtection).to have_received(:get).with(metadata_url)
        expect(Saml::MetadataDocument).to have_received(:prepare).with(instance_of(File), entity_id: nil)
        expect(parser_instance).to have_received(:parse_to_hash).with("<xml/>")
        expect(fetched_file).to be_closed
      end
    end

    context "when the URL host resolves to an unsafe IP" do
      before do
        allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(nil)
      end

      it "fails before attempting a remote metadata fetch" do
        result = parse_metadata

        expect(result).not_to be_success
        expect(result.message).to include("MetadataHostNotAllowedError")
        expect(OpenProject::SsrfProtection).to have_received(:safe_ip?).with("example.com")
        expect(OpenProject::SsrfProtection).not_to have_received(:get)
      end
    end
  end
end
