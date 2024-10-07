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

RSpec.describe "SAML metadata endpoint", with_ee: %i[sso_auth_providers] do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject do
    temp = Nokogiri::XML(last_response.body)

    # The ds prefix is not defined on root,
    # which Nokogiri complains about
    temp.root["xmlns:ds"] = "http://www.w3.org/2000/09/xmldsig#"

    Nokogiri::XML(temp.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML))
  end

  before do
    provider
    get "/auth/saml/metadata"
  end

  context "with basic provider" do
    let(:provider) do
      create(:saml_provider, slug: "saml")
    end

    it "returns the metadata" do
      expect(last_response).to be_successful
      expect(subject.at_xpath("//md:EntityDescriptor")["entityID"]).to eq "http://test.host"

      sso = subject.at_xpath("//md:SPSSODescriptor")
      expect(sso["AuthnRequestsSigned"]).to eq "false"
      expect(sso["WantAssertionsSigned"]).to eq "false"

      consumer = sso.at_xpath("//md:AssertionConsumerService")
      expect(consumer["Binding"]).to eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      expect(consumer["Location"]).to eq "http://test.host/auth/saml/callback"
    end
  end

  context "with elaborate provider" do
    let(:provider) do
      create(:saml_provider,
             :with_encryption,
             :with_requested_attributes,
             slug: "saml")
    end

    it "returns the metadata", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      expect(last_response).to be_successful
      expect(subject.at_xpath("//md:EntityDescriptor")["entityID"]).to eq "http://test.host"

      sso = subject.at_xpath("//md:SPSSODescriptor")
      expect(sso["AuthnRequestsSigned"]).to eq "true"
      expect(sso["WantAssertionsSigned"]).to eq "true"

      # Expect signature present
      signature = subject.at_xpath("//ds:Signature")
      expect(signature.at_xpath("//ds:SignatureMethod")["Algorithm"]).to eq "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      expect(signature.at_xpath("//ds:DigestMethod")["Algorithm"]).to eq "http://www.w3.org/2001/04/xmlenc#sha256"

      expect(signature.at_xpath("//ds:DigestValue")).to be_present

      signing = signature.at_xpath("//md:KeyDescriptor[@use='signing']/ds:KeyInfo/ds:X509Data/ds:X509Certificate").text
      expect(signing).to eq CertificateHelper.non_padded_string(:valid_certificate)

      encryption = signature.at_xpath("//md:KeyDescriptor[@use='encryption']/ds:KeyInfo/ds:X509Data/ds:X509Certificate").text
      expect(encryption).to eq CertificateHelper.non_padded_string(:valid_certificate)

      consumer = sso.at_xpath("//md:AssertionConsumerService")
      expect(consumer["Binding"]).to eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      expect(consumer["Location"]).to eq "http://test.host/auth/saml/callback"

      consuming = consumer.at_xpath("//md:AttributeConsumingService")
      requested = consuming.xpath("md:RequestedAttribute")
      attributes = requested.map { |x| [x["FriendlyName"], x["Name"]] }
      expect(attributes).to contain_exactly ["Login", "mail"],
                                            ["First Name", "givenName"],
                                            ["Last Name", "sn"],
                                            ["Email", "mail"]

      requested.each do |attr|
        expect(attr["NameFormat"]).to eq "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
      end
    end
  end
end
