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

RSpec.describe Saml::MetadataDocument do
  # Fixture: 3 SPs then 5 IdPs — see spec/fixtures/federation_metadata.xml
  let(:federation_xml) { Rails.root.join("modules/auth_saml/spec/fixtures/federation_metadata.xml").read }

  # Minimal single EntityDescriptor — not an aggregate, so prepare returns it unchanged
  let(:single_idp_xml) do
    <<~XML
      <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
          xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
          entityID="https://idp.example.com/idp/shibboleth">
        <md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
          <md:SingleSignOnService
              Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
              Location="https://idp.example.com/idp/profile/SAML2/Redirect/SSO"/>
        </md:IDPSSODescriptor>
      </md:EntityDescriptor>
    XML
  end

  # Entity IDs present in the fixture
  let(:first_idp_entity_id) { "https://idp.state-university.edu/idp/shibboleth" }
  let(:last_idp_entity_id)  { "https://idp.polytechnic.edu.br/idp/shibboleth" }
  let(:sp_entity_id)        { "https://sp.state-university.edu/shibboleth" }

  describe ".prepare on a single-entity document" do
    it "returns the XML unchanged" do
      result = described_class.prepare(single_idp_xml)
      expect(result).to eq(single_idp_xml)
    end
  end

  describe ".prepare on a federation aggregate" do
    it "detects the aggregate" do
      expect(described_class.new(federation_xml).aggregate?).to be(true)
    end

    context "without an entity_id" do
      it "returns the first IdP entity, skipping SP-only entries" do
        result = described_class.prepare(federation_xml)

        expect(result).to include(first_idp_entity_id)
        expect(result).to include("IDPSSODescriptor")
        expect(result).not_to include("SPSSODescriptor")
      end
    end

    context "with a matching entity_id" do
      it "extracts the requested IdP" do
        result = described_class.prepare(federation_xml, entity_id: last_idp_entity_id)

        expect(result).to include(last_idp_entity_id)
        expect(result).to include("IDPSSODescriptor")
      end

      it "can also extract an SP entity by entity_id" do
        result = described_class.prepare(federation_xml, entity_id: sp_entity_id)

        expect(result).to include(sp_entity_id)
        expect(result).to include("SPSSODescriptor")
      end
    end

    context "with an entity_id not present in the aggregate" do
      it "raises FederationMetadataError with the missing entity_id in the message" do
        expect do
          described_class.prepare(federation_xml, entity_id: "https://missing.example.com/idp/shibboleth")
        end.to raise_error(described_class::FederationMetadataError, /missing\.example\.com/)
      end
    end

    context "when the aggregate contains no IdPs and no entity_id is given" do
      let(:sp_only_aggregate) do
        <<~XML
          <md:EntitiesDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata">
            <md:EntityDescriptor entityID="https://sp.example.com/shibboleth">
              <md:SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"/>
            </md:EntityDescriptor>
          </md:EntitiesDescriptor>
        XML
      end

      it "raises FederationMetadataError" do
        expect do
          described_class.prepare(sp_only_aggregate)
        end.to raise_error(described_class::FederationMetadataError)
      end
    end
  end

  describe ".prepare on an IO source (Tempfile)" do
    it "reads a single-entity file correctly" do
      Tempfile.create("spec-metadata") do |f|
        f.write(single_idp_xml)
        f.rewind
        expect(described_class.prepare(f)).to eq(single_idp_xml)
      end
    end

    it "extracts the first IdP from a federation aggregate file" do
      Tempfile.create("spec-metadata") do |f|
        f.write(federation_xml)
        f.rewind
        result = described_class.prepare(f)
        expect(result).to include(first_idp_entity_id)
        expect(result).to include("IDPSSODescriptor")
      end
    end
  end
end
