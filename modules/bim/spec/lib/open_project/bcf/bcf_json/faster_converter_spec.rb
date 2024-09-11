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

RSpec.describe OpenProject::Bim::BcfJson::FasterConverter do
  def pps(hash)
    PP.pp(hash, +"")
  end

  describe ".xml_to_hash" do
    it "deals with single tag without params" do
      xml = <<~XML
        <Component />
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq("Component" => nil)
    end

    it "deals with single tag with params" do
      xml = <<~XML
        <Component IfcGuid="3_LMnKT5PDNvFeWnu3ys5Q" />
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq("Component" => { "IfcGuid" => "3_LMnKT5PDNvFeWnu3ys5Q" })
    end

    it "deals with single tag with inner tags" do
      xml = <<~XML
        <Component IfcGuid="3_LMnKT5PDNvFeWnu3ys5Q">
          <OriginatingSystem>Revit</OriginatingSystem>
          <AuthoringToolId>1110420</AuthoringToolId>
        </Component>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq(
          "Component" => {
            "IfcGuid" => "3_LMnKT5PDNvFeWnu3ys5Q",
            "OriginatingSystem" => "Revit",
            "AuthoringToolId" => "1110420"
          }
        )
    end

    it "deals with multiple similar tags with inner tags" do
      xml = <<~XML
        <root>
          <Component IfcGuid="3_LMnKT5PDNvFeWnu3ys5Q">
            <OriginatingSystem>Revit</OriginatingSystem>
            <AuthoringToolId>1110420</AuthoringToolId>
          </Component>
          <Component IfcGuid="3_LMnKT5PDNvFeWnu3ysAc">
            <OriginatingSystem>Revit</OriginatingSystem>
            <AuthoringToolId>1110632</AuthoringToolId>
          </Component>
        </root>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq(
          "root" => {
            "Component" => [
              { "IfcGuid" => "3_LMnKT5PDNvFeWnu3ys5Q", "OriginatingSystem" => "Revit", "AuthoringToolId" => "1110420" },
              { "IfcGuid" => "3_LMnKT5PDNvFeWnu3ysAc", "OriginatingSystem" => "Revit", "AuthoringToolId" => "1110632" }
            ]
          }
        )
    end

    it "deals with outer tag + multiple similar inner tags" do
      xml = <<~XML
        <Color>
          <Component />
          <Component />
        </Color>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq("Color" => { "Component" => [nil, nil] })
    end

    it "deals with outer tag with params + multiple similar inner tags" do
      xml = <<~XML
        <Color Color="3498db">
          <Component />
          <Component />
        </Color>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq("Color" => { "Color" => "3498db", "Component" => [nil, nil] })
    end

    it "deals with outer tag with params + multiple similar inner tags with params" do
      xml = <<~XML
        <Color Color="3498db">
          <Component IfcGuid="3_LMnKT5PDNvFeWnu3ys5Q"/>
          <Component IfcGuid="3_LMnKT5PDNvFeWnu3ysAc"/>
        </Color>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq(
          "Color" => {
            "Color" => "3498db",
            "Component" => [
              { "IfcGuid" => "3_LMnKT5PDNvFeWnu3ys5Q" },
              { "IfcGuid" => "3_LMnKT5PDNvFeWnu3ysAc" }
            ]
          }
        )
    end

    it "deals with outer tag + multiple similar inner tags with inner tags" do
      xml = <<~XML
        <Color>
          <Component>
            <AuthoringToolId>id:1</AuthoringToolId>
          </Component>
          <Component>
            <AuthoringToolId>id:2</AuthoringToolId>
          </Component>
        </Color>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq(
          "Color" => {
            "Component" => [
              { "AuthoringToolId" => "id:1" },
              { "AuthoringToolId" => "id:2" }
            ]
          }
        )
    end

    it "deals with outer tag + mixed similar inner tags" do
      xml = <<~XML
        <Color>
          <Component IfcGuid="guid:1"/>
          <Component>
            <AuthoringToolId>id:2</AuthoringToolId>
          </Component>
          <Component IfcGuid="guid:3"/>
        </Color>
      XML
      expect(described_class.xml_to_hash(xml)).to eq(Hash.from_xml(xml)), "should be identical to reference implementation"
      expect(described_class.xml_to_hash(xml))
        .to eq(
          "Color" => {
            "Component" => [
              { "IfcGuid" => "guid:1" },
              { "AuthoringToolId" => "id:2" },
              { "IfcGuid" => "guid:3" }
            ]
          }
        )
    end

    # real data tests
    Rails.root.glob("modules/bim/spec/fixtures/viewpoints/*.xml").each do |xml_file|
      it "converts #{xml_file.basename} like Hash.from_xml() would" do
        xml = xml_file.read
        fast_hash = pps(described_class.xml_to_hash(xml))
        slow_hash = pps(Hash.from_xml(xml))
        expect(fast_hash).to eq(slow_hash)
      end
    end
  end
end
