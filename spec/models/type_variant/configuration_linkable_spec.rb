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

RSpec.describe TypeVariant::ConfigurationLinkable do
  let(:type_record) { create(:type) }
  let(:base) { type_record.default_variant }
  let(:variant) { create(:type_variant, type: type_record) }
  let(:aspect) { TypeVariant::DEFAULTS }

  describe "#linked? and #source_for" do
    it "reports independent (no link) by default" do
      expect(variant).not_to be_linked(aspect)
      expect(variant.source_for(aspect)).to be_nil
    end

    it "reports linked, with the base as its source, once linked" do
      variant.link!(aspect)

      expect(variant).to be_linked(aspect)
      expect(variant.source_for(aspect)).to eq(base)
    end

    it "tracks each aspect independently" do
      variant.link!(TypeVariant::DEFAULTS)

      expect(variant).to be_linked(TypeVariant::DEFAULTS)
      expect(variant).not_to be_linked(TypeVariant::PDF_EXPORT)
    end
  end

  describe "#link! and #unlink!" do
    it "links an aspect to the base and unlinks it again" do
      variant.link!(aspect)
      expect(variant.reload).to be_linked(aspect)

      variant.unlink!(aspect)
      expect(variant.reload).not_to be_linked(aspect)
    end

    it "clears the aspect's exclusions when unlinking" do
      variant.link!(TypeVariant::FORM_CONFIGURATION)
      variant.update!(form_configuration_excluded_elements: %w[assignee])

      variant.unlink!(TypeVariant::FORM_CONFIGURATION)

      expect(variant.reload.form_configuration_excluded_elements).to eq([])
    end

    it "cannot link an aspect on a base variant" do
      expect { base.link!(aspect) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "a freshly created variant" do
    it "is independent for every aspect" do
      TypeVariant::ASPECTS.each { |a| expect(variant).not_to be_linked(a) }
    end

    it "leaves a type's base variant independent for every aspect" do
      TypeVariant::ASPECTS.each { |a| expect(base).not_to be_linked(a) }
    end
  end

  describe "#owner_of" do
    it "returns itself when independent" do
      expect(variant.owner_of(aspect)).to eq(variant)
    end

    it "returns the base when linked" do
      variant.link!(aspect)

      expect(variant.owner_of(aspect)).to eq(base)
    end
  end

  # Each aspect's readers are overridden so that plain `variant.patterns` etc. is the configuration
  # in force. The own_* attributes below are what the variant stores itself, and must stay visible
  # through read_attribute even while linked.
  describe "resolved configuration readers" do
    let(:base_attributes) do
      {
        patterns: { subject: { blueprint: "Base {{id}}", enabled: true } },
        default_work_package_description: "Base description",
        artefact_export_mode: Type::ArtefactExport::ATTACHMENT,
        export_templates_disabled: %w[contract],
        export_templates_order: %w[artefact attributes contract]
      }
    end
    let(:own_attributes) do
      {
        patterns: { subject: { blueprint: "Own {{id}}", enabled: true } },
        default_work_package_description: "Own description",
        artefact_export_mode: Type::ArtefactExport::FILE_LINK,
        export_templates_disabled: %w[artefact],
        export_templates_order: %w[contract attributes artefact]
      }
    end

    before do
      base.update!(base_attributes)
      variant.update!(own_attributes)
    end

    context "when independent" do
      it "reads the DEFAULTS attributes it stores itself" do
        expect(variant.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(variant.default_work_package_description).to eq("Own description")
      end

      it "reads the PDF_EXPORT attributes it stores itself" do
        expect(variant.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(variant.export_templates_disabled).to eq(%w[artefact])
        expect(variant.export_templates_order).to eq(%w[contract attributes artefact])
      end
    end

    context "when linked for DEFAULTS only" do
      before { variant.link!(TypeVariant::DEFAULTS) }

      it "reads the DEFAULTS attributes from the base" do
        expect(variant.patterns.subject.blueprint).to eq("Base {{id}}")
        expect(variant.default_work_package_description).to eq("Base description")
      end

      it "leaves the PDF_EXPORT attributes on this variant" do
        expect(variant.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(variant.export_templates_disabled).to eq(%w[artefact])
      end

      it "keeps writing to its own record" do
        variant.update!(default_work_package_description: "Rewritten")

        expect(variant.read_attribute(:default_work_package_description)).to eq("Rewritten")
        expect(base.reload.default_work_package_description).to eq("Base description")
      end
    end

    context "when linked for PDF_EXPORT only" do
      before { variant.link!(TypeVariant::PDF_EXPORT) }

      it "reads the PDF_EXPORT attributes from the base" do
        expect(variant.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
        expect(variant.export_templates_disabled).to eq(%w[contract])
        expect(variant.export_templates_order).to eq(%w[artefact attributes contract])
      end

      it "leaves the DEFAULTS attributes on this variant" do
        expect(variant.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(variant.default_work_package_description).to eq("Own description")
      end

      it "falls back to the artefact export default when the base has none" do
        base.update!(artefact_export_mode: nil)

        expect(variant.artefact_export_mode).to eq(Type::ArtefactExport::DEFAULT)
      end
    end
  end

  # These read through the overridden attribute readers rather than resolving a source themselves,
  # so they are what proves the indirection actually pays off.
  describe "consumers of the resolved readers" do
    before do
      base.update!(patterns: { subject: { blueprint: "Base {{id}}", enabled: true } },
                   artefact_export_mode: Type::ArtefactExport::ATTACHMENT,
                   export_templates_disabled: %w[contract])
    end

    it "resolves #enabled_patterns and #replacement_pattern_defined_for? through the link" do
      variant.link!(TypeVariant::DEFAULTS)

      expect(variant.enabled_patterns.keys).to include(:subject)
      expect(variant).to be_replacement_pattern_defined_for(:subject)
    end

    it "reports no subject pattern when independent and none is set" do
      expect(variant).not_to be_replacement_pattern_defined_for(:subject)
    end

    it "resolves #artefact_export_enabled? through the link" do
      expect(variant).not_to be_artefact_export_enabled
      variant.link!(TypeVariant::PDF_EXPORT)

      expect(variant).to be_artefact_export_enabled
    end

    it "lists the base's enabled templates while wrapping this variant" do
      variant.link!(TypeVariant::PDF_EXPORT)

      expect(variant.pdf_export_templates.list_enabled.map(&:id)).to contain_exactly("attributes", "artefact")
    end

    # Mutating methods refuse to run while linked (Type::PdfExportTemplates#readonly?): merging onto
    # a read that resolves through the link would otherwise silently corrupt this variant's own
    # stored configuration for other templates once unlinked.
    it "refuses to mutate while linked, rather than writing onto the base's or its own resolved data" do
      variant.link!(TypeVariant::PDF_EXPORT)

      expect { variant.pdf_export_templates.disable_all }.to raise_error(Type::PdfExportTemplates::ReadonlyError)
    end
  end

  describe "form configuration resolution" do
    let(:form_aspect) { TypeVariant::FORM_CONFIGURATION }

    before do
      base.update!(attribute_groups: [["base_only_group", %w(assignee)]])
      variant.update!(attribute_groups: [["own_group", %w(assignee)]])
    end

    it "reads attribute_groups from the base when linked" do
      variant.link!(form_aspect)

      keys = variant.attribute_groups.map(&:key)
      expect(keys).to include("base_only_group")
      expect(keys).not_to include("own_group")
    end

    it "reads its own attribute_groups when independent" do
      keys = variant.attribute_groups.map(&:key)
      expect(keys).to include("own_group")
      expect(keys).not_to include("base_only_group")
    end

    it "reads its own attribute_groups while an assignment is pending, even when linked" do
      variant.link!(form_aspect)
      variant.attribute_groups = [["pending_group", %w(assignee)]]

      keys = variant.attribute_groups.map(&:key)
      expect(keys).to include("pending_group")
      expect(keys).not_to include("base_only_group")
    end

    it "reads custom_fields from the base when linked" do
      cf = create(:integer_wp_custom_field)
      base.custom_fields << cf
      variant.link!(form_aspect)

      expect(variant.custom_fields).to include(cf)
    end

    it "still appends custom_fields to its own record when independent" do
      cf = create(:integer_wp_custom_field)
      variant.custom_fields << cf

      expect(variant.custom_fields).to include(cf)
    end
  end

  describe "project attributes resolution" do
    let(:project_attributes_aspect) { TypeVariant::PROJECT_ATTRIBUTES }
    let(:base_field) { create(:project_custom_field) }
    let(:own_field) { create(:project_custom_field) }

    before do
      ProjectCustomFieldTypeMapping.create!(type_variant: base, project_custom_field: base_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: variant, project_custom_field: own_field)
    end

    it "reads its own mappings when independent" do
      expect(variant.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id)
    end

    it "reads the base's mappings when linked" do
      variant.link!(project_attributes_aspect)

      expect(variant.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(base_field.id)
    end

    it "drops an excluded attribute from the inherited mappings" do
      variant.link!(project_attributes_aspect)
      variant.update!(project_attributes_excluded_elements: [base_field.attribute_name])

      expect(variant.project_custom_field_type_mappings).to be_empty
    end

    it "keeps the attributes it does not exclude" do
      kept_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: base, project_custom_field: kept_field)
      variant.link!(project_attributes_aspect)
      variant.update!(project_attributes_excluded_elements: [base_field.attribute_name])

      expect(variant.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(kept_field.id)
    end

    it "leaves the base's own mappings untouched" do
      variant.link!(project_attributes_aspect)
      variant.update!(project_attributes_excluded_elements: [base_field.attribute_name])

      expect(base.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(base_field.id)
    end

    it "keeps writing to its own mappings while linked" do
      variant.link!(project_attributes_aspect)
      another_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: variant, project_custom_field: another_field)

      expect(variant.own_project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id, another_field.id)
    end
  end

  describe "#excluded_elements" do
    let(:aspect) { TypeVariant::FORM_CONFIGURATION }

    it "excludes nothing when independent" do
      expect(variant.excluded_elements(aspect)).to eq([])
    end

    it "excludes nothing when linked without exclusions" do
      variant.link!(aspect)

      expect(variant.excluded_elements(aspect)).to eq([])
    end

    it "returns the variant's own exclusions when linked" do
      variant.link!(aspect)
      variant.update!(form_configuration_excluded_elements: %w[custom_field_1 assignee])

      expect(variant.excluded_elements(aspect)).to contain_exactly("custom_field_1", "assignee")
    end

    it "keeps exclusions scoped to their own aspect" do
      variant.link!(aspect)
      variant.link!(TypeVariant::PROJECT_ATTRIBUTES)
      variant.update!(form_configuration_excluded_elements: %w[custom_field_1],
                      project_attributes_excluded_elements: %w[custom_field_2])

      expect(variant.excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    it "excludes nothing for a new record" do
      expect(TypeVariant.new.excluded_elements(aspect)).to eq([])
    end
  end

  describe ".excluded_custom_field_condition" do
    def excluded?(custom_field_id, elements)
      literal = elements.empty? ? "'{}'::text[]" : "ARRAY[#{elements.map { |e| "'#{e}'" }.join(', ')}]::text[]"
      condition = TypeVariant.excluded_custom_field_condition(custom_field_id.to_s, literal)

      TypeVariant.connection.select_value("SELECT 1 WHERE #{condition}").nil?
    end

    it "excludes a custom field listed under its attribute name" do
      expect(excluded?(7, %w[custom_field_7])).to be(true)
    end

    it "keeps a custom field that is not listed" do
      expect(excluded?(7, %w[custom_field_8 assignee])).to be(false)
    end

    it "keeps every custom field when nothing is excluded" do
      expect(excluded?(7, [])).to be(false)
    end

    it "does not confuse a prefix of another id" do
      expect(excluded?(7, %w[custom_field_77])).to be(false)
    end
  end
end
