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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Exports::Generate::ModalDialogComponent, type: :component do
  subject(:component) { described_class.new(work_package:, params: {}) }

  let(:type) { create(:type) }
  let(:work_package) { build_stubbed(:work_package, type:) }

  describe "#templates_options", with_flag: { type_variants: true } do
    it "lists the enabled templates of the type the PDF config is linked to" do
      source = create(:type)
      source.default_variant.pdf_export_templates.disable_all
      source.default_variant.save!
      link_configuration(type, source:, aspect: TypeVariant::PDF_EXPORT)

      expect(component.templates_options).to be_empty
    end
  end

  describe "#attributes_settings" do
    it "defaults the footer text, orientation and hyphenation" do
      expect(component.attributes_settings).to eq(
        footer_text: work_package.project.name,
        page_orientation: "portrait",
        hyphenation: false,
        hyphenation_language: component.hyphenation_default[:value]
      )
    end

    context "when the type has stored defaults for this template" do
      before do
        type.default_variant.pdf_export_templates.update_settings(
          "attributes",
          "footer_text" => "Stored footer", "page_orientation" => "landscape", "hyphenation" => "true"
        )
        type.default_variant.save!
      end

      it "pre-fills the fields from the Type's stored settings" do
        expect(component.attributes_settings).to eq(
          footer_text: "Stored footer",
          page_orientation: "landscape",
          hyphenation: true,
          hyphenation_language: component.hyphenation_default[:value]
        )
      end
    end

    context "when the type has a stored hyphenation_language and the current locale has no match" do
      before do
        I18n.locale = :ja
        type.default_variant.pdf_export_templates.update_settings("attributes", "hyphenation_language" => "fr")
        type.default_variant.save!
      end

      after { I18n.locale = I18n.default_locale }

      it "uses the Type's stored language" do
        expect(component.attributes_settings[:hyphenation_language]).to eq("fr")
      end
    end

    context "when the type has a stored hyphenation_language and the current locale also has a match" do
      before do
        I18n.locale = :en
        type.default_variant.pdf_export_templates.update_settings("attributes", "hyphenation_language" => "fr")
        type.default_variant.save!
      end

      after { I18n.locale = I18n.default_locale }

      it "prefers the Type's stored language over the auto-detected locale match" do
        expect(component.attributes_settings[:hyphenation_language]).to eq("fr")
      end
    end
  end

  describe "#contract_settings" do
    it "defaults the footer text and hyphenation" do
      expect(component.contract_settings).to eq(
        footer_text_center: work_package.subject,
        hyphenation: false,
        hyphenation_language: component.hyphenation_default[:value]
      )
    end

    context "when the type has a stored default for this template" do
      before do
        type.default_variant.pdf_export_templates.update_settings("contract", "footer_text_center" => "Stored center footer")
        type.default_variant.save!
      end

      it "pre-fills the field from the Type's stored settings" do
        expect(component.contract_settings[:footer_text_center]).to eq("Stored center footer")
      end
    end
  end

  describe "#artefact_settings" do
    it "defaults each section to the exporter's own default" do
      expect(component.artefact_settings).to eq(
        toc: WorkPackage::PDFExport::Artefact::DEFAULT_TOC,
        include_lifecycle: WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_LIFECYCLE,
        include_budget: WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_BUDGET,
        hyphenation: false,
        hyphenation_language: component.hyphenation_default[:value]
      )
    end

    context "when the type has a stored default explicitly disabling the table of contents" do
      before do
        type.default_variant.pdf_export_templates.update_settings("artefact", "toc" => "false")
        type.default_variant.save!
      end

      it "resolves the stored string setting to a real boolean, not a truthy string" do
        expect(component.artefact_settings[:toc]).to be(false)
      end
    end

    context "when the type has a stored default explicitly enabling the lifecycle and budget sections" do
      before do
        type.default_variant.pdf_export_templates.update_settings(
          "artefact", "include_lifecycle" => "true", "include_budget" => "true"
        )
        type.default_variant.save!
      end

      it "resolves the stored string settings to real booleans, not truthy strings" do
        expect(component.artefact_settings[:include_lifecycle]).to be(true)
        expect(component.artefact_settings[:include_budget]).to be(true)
      end
    end
  end

  describe "#template_form_id" do
    it "namespaces the form id by template" do
      expect(component.template_form_id("contract")).to eq("#{described_class::GENERATE_PDF_FORM_ID}-contract")
    end
  end
end
