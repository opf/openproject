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
  def link(variant, source:, aspect:, excluded: [])
    variant.update!({ "#{aspect}_source": source }.merge(exclusions(aspect, excluded)))
  end

  def link_without_validation(variant, source:, aspect:, excluded: [])
    variant.update_columns({ "#{aspect}_source_id": source.id }.merge(exclusions(aspect, excluded)))
  end

  def exclusions(aspect, elements)
    return {} unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

    { "#{aspect}_excluded_elements": elements }
  end

  let(:type) { create(:type).default_variant }
  let(:source) { create(:type).default_variant }
  let(:aspect) { TypeVariant::DEFAULTS }

  describe "#linked? and #source_for" do
    it "reports Independent (no link) by default" do
      expect(type).not_to be_linked(aspect)
      expect(type.source_for(aspect)).to be_nil
    end

    it "reports Linked once a link exists" do
      link_configuration(type, source:, aspect:)

      expect(type).to be_linked(aspect)
      expect(type.source_for(aspect)).to eq(source)
    end

    it "tracks each aspect independently" do
      link_configuration(type, source:, aspect: TypeVariant::DEFAULTS)

      expect(type).to be_linked(TypeVariant::DEFAULTS)
      expect(type).not_to be_linked(TypeVariant::PDF_EXPORT)
    end
  end

  describe "#link!" do
    it "re-points an existing link" do
      other_source = create(:type).default_variant
      link_configuration(type, source:, aspect:)

      link_configuration(type, source: other_source, aspect:)

      expect(type.source_for(aspect)).to eq(other_source)
    end
  end

  describe "a freshly created variant" do
    it "is Independent for every aspect" do
      variant = create(:type_variant)

      TypeVariant::ASPECTS.each do |aspect|
        expect(variant).not_to be_linked(aspect)
      end
    end

    it "leaves a type's base variant Independent for every aspect" do
      base = create(:type).default_variant

      TypeVariant::ASPECTS.each do |aspect|
        expect(base).not_to be_linked(aspect)
      end
    end
  end

  describe "deletion" do
    it "takes the variant's own links with it" do
      link_configuration(type, source:, aspect:)

      expect { type.destroy }.to change(TypeVariant, :count).by(-1)
    end

    it "refuses to destroy a variant that is still a source for another" do
      link_configuration(type, source:, aspect:)

      expect(source.destroy).to be(false)
      expect(source).to be_persisted
      expect(source.errors.full_messages.to_sentence).to include(type.composite_name)
    end
  end

  describe "#dependents_for" do
    let(:direct) { create(:type, name: "Direct").default_variant }
    let(:indirect) { create(:type, name: "Indirect").default_variant }
    let(:deeper) { create(:type, name: "Deeper").default_variant }

    it "is empty while nothing reuses the aspect" do
      expect(source.dependents_for(aspect)).to be_empty
    end

    it "walks the whole chain, depth 1 for a direct reuse and up from there" do
      link_configuration(direct, source:, aspect:)
      link_configuration(indirect, source: direct, aspect:)
      link_configuration(deeper, source: indirect, aspect:)

      expect(source.dependents_for(aspect).map { |v| [v.type.name, v.dependent_depth] })
        .to contain_exactly(["Direct", 1], ["Indirect", 2], ["Deeper", 3])
    end

    it "counts only the part of the chain below the variant asked" do
      link_configuration(direct, source:, aspect:)
      link_configuration(indirect, source: direct, aspect:)

      expect(direct.dependents_for(aspect).map { |v| [v.type.name, v.dependent_depth] })
        .to contain_exactly(["Indirect", 1])
    end

    it "follows a branching chain down every branch" do
      link_configuration(direct, source:, aspect:)
      link_configuration(indirect, source:, aspect:)
      link_configuration(deeper, source: indirect, aspect:)

      expect(source.dependents_for(aspect).map(&:id))
        .to contain_exactly(direct.id, indirect.id, deeper.id)
    end

    it "keeps the aspects apart" do
      link_configuration(direct, source:, aspect: TypeVariant::WORKFLOWS)

      expect(source.dependents_for(aspect)).to be_empty
      expect(source.dependents_for(TypeVariant::WORKFLOWS).map(&:id)).to eq([direct.id])
    end

    it "terminates on a cycle written before cycle prevention" do
      link_configuration(direct, source:, aspect:)
      link_without_validation(source, source: direct, aspect:)

      expect(source.dependents_for(aspect).map(&:id)).to contain_exactly(direct.id)
    end
  end

  describe "#effective_source_for" do
    it "returns itself when Independent" do
      expect(type.effective_source_for(aspect)).to eq(type)
    end

    it "walks the link chain to the owning Independent type" do
      owner = create(:type).default_variant
      middle = create(:type).default_variant
      link_configuration(middle, source: owner, aspect:)
      link_configuration(type, source: middle, aspect:)

      expect(type.effective_source_for(aspect)).to eq(owner)
    end

    it "terminates on a cycle instead of looping forever" do
      # A cycle can no longer be created through validated writes, so bypass validation
      # to reproduce a cyclic row that predates write-time prevention (FND-133).
      other = create(:type).default_variant
      link_configuration(type, source: other, aspect:)
      link_without_validation(other, source: type, aspect:)

      expect { type.effective_source_for(aspect) }.not_to raise_error
    end
  end

  # Each aspect's readers are overridden so that plain `type.patterns` etc. is the
  # configuration in force. The own_* attributes below are what the type stores
  # itself, and must stay visible through read_attribute even while linked.
  describe "resolved configuration readers" do
    let(:owner_attributes) do
      {
        patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
        default_work_package_description: "Owner description",
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

    let(:owner) { create(:type).default_variant.tap { it.update!(owner_attributes) } }

    before { type.update!(own_attributes) }

    context "when Independent" do
      it "reads the DEFAULTS attributes it stores itself" do
        expect(type.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(type.default_work_package_description).to eq("Own description")
      end

      it "reads the PDF_EXPORT attributes it stores itself" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(type.export_templates_disabled).to eq(%w[artefact])
        expect(type.export_templates_order).to eq(%w[contract attributes artefact])
      end
    end

    context "when Linked for DEFAULTS only" do
      before { link_configuration(type, source: owner, aspect: TypeVariant::DEFAULTS) }

      it "reads the DEFAULTS attributes from the owner" do
        expect(type.patterns.subject.blueprint).to eq("Owner {{id}}")
        expect(type.default_work_package_description).to eq("Owner description")
      end

      it "leaves the PDF_EXPORT attributes on this type" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(type.export_templates_disabled).to eq(%w[artefact])
      end

      it "keeps writing to its own record" do
        type.update!(default_work_package_description: "Rewritten")

        expect(type.read_attribute(:default_work_package_description)).to eq("Rewritten")
        expect(owner.reload.default_work_package_description).to eq("Owner description")
      end
    end

    context "when Linked for PDF_EXPORT only" do
      before { link_configuration(type, source: owner, aspect: TypeVariant::PDF_EXPORT) }

      it "reads the PDF_EXPORT attributes from the owner" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
        expect(type.export_templates_disabled).to eq(%w[contract])
        expect(type.export_templates_order).to eq(%w[artefact attributes contract])
      end

      it "leaves the DEFAULTS attributes on this type" do
        expect(type.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(type.default_work_package_description).to eq("Own description")
      end

      it "falls back to the artefact export default when the owner has none" do
        owner.update!(artefact_export_mode: nil)

        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::DEFAULT)
      end
    end

    it "reads from the type at the end of the link chain, not the one in the middle" do
      middle = create(:type).default_variant.tap { it.update!(default_work_package_description: "Middle description") }
      link_configuration(middle, source: owner, aspect: TypeVariant::DEFAULTS)
      link_configuration(type, source: middle, aspect: TypeVariant::DEFAULTS)

      expect(type.default_work_package_description).to eq("Owner description")
    end
  end

  # These read through the overridden attribute readers rather than resolving a
  # source themselves, so they are what proves the indirection actually pays off.
  describe "consumers of the resolved readers" do
    let(:owner) do
      create(:type).default_variant.tap do |variant|
        variant.update!(patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
                        artefact_export_mode: Type::ArtefactExport::ATTACHMENT,
                        export_templates_disabled: %w[contract])
      end
    end

    it "resolves #enabled_patterns and #replacement_pattern_defined_for? through the link" do
      link_configuration(type, source: owner, aspect: TypeVariant::DEFAULTS)

      expect(type.enabled_patterns.keys).to include(:subject)
      expect(type).to be_replacement_pattern_defined_for(:subject)
    end

    it "reports no subject pattern when Independent and none is set" do
      expect(type).not_to be_replacement_pattern_defined_for(:subject)
    end

    it "resolves #artefact_export_enabled? through the link" do
      expect(type).not_to be_artefact_export_enabled
      link_configuration(type, source: owner, aspect: TypeVariant::PDF_EXPORT)

      expect(type).to be_artefact_export_enabled
    end

    it "lists the owner's enabled templates while wrapping this type" do
      link_configuration(type, source: owner, aspect: TypeVariant::PDF_EXPORT)

      expect(type.pdf_export_templates.list_enabled.map(&:id)).to contain_exactly("attributes", "artefact")
    end

    # Mutating methods refuse to run while linked (Type::PdfExportTemplates#readonly?):
    # merging onto a read that resolves through the link would otherwise silently
    # corrupt this type's own stored configuration for other templates once unlinked.
    it "refuses to mutate while linked, rather than writing onto the owner's or its own resolved data",
       with_flag: { type_variants: true } do
      link_configuration(type, source: owner, aspect: TypeVariant::PDF_EXPORT)

      expect { type.pdf_export_templates.disable_all }.to raise_error(Type::PdfExportTemplates::ReadonlyError)
    end
  end

  describe "with the variants flag off", with_flag: { type_variants: false } do
    let(:owner) do
      create(:type).default_variant.tap do |variant|
        variant.update!(patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
                        default_work_package_description: "Owner description",
                        artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
      end
    end

    before do
      link_configuration(type, source: owner, aspect: TypeVariant::DEFAULTS)
      link_configuration(type, source: owner, aspect: TypeVariant::PDF_EXPORT)
    end

    it "resolves links exactly as it does with the flag on" do
      expect(type.effective_source_for(TypeVariant::DEFAULTS)).to eq(owner)
      expect(type.default_work_package_description).to eq("Owner description")
      expect(type.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
      expect(type).to be_replacement_pattern_defined_for(:subject)
    end
  end

  describe "form configuration resolution" do
    let(:form_aspect) { TypeVariant::FORM_CONFIGURATION }
    let(:source) do
      create(:type).default_variant.tap do |t|
        t.attribute_groups = [["source_only_group", %w(assignee)]]
        t.save!
      end
    end

    before { type.update!(attribute_groups: [["own_group", %w(assignee)]]) }

    it "reads attribute_groups from the linked owner" do
      link_configuration(type, source:, aspect: form_aspect)

      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("source_only_group")
      expect(keys).not_to include("own_group")
    end

    it "reads its own attribute_groups when Independent" do
      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("own_group")
      expect(keys).not_to include("source_only_group")
    end

    it "reads its own attribute_groups while an assignment is pending, even when linked" do
      link_configuration(type, source:, aspect: form_aspect)
      type.attribute_groups = [["pending_group", %w(assignee)]]

      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("pending_group")
      expect(keys).not_to include("source_only_group")
    end

    it "reads custom_fields from the linked owner" do
      cf = create(:integer_wp_custom_field)
      source.custom_fields << cf
      link_configuration(type, source:, aspect: form_aspect)

      expect(type.custom_fields).to include(cf)
    end

    it "still appends custom_fields to its own record when Independent" do
      cf = create(:integer_wp_custom_field)
      type.custom_fields << cf

      expect(type.custom_fields).to include(cf)
    end
  end

  describe "form configuration with the flag off", with_flag: { type_variants: false } do
    it "reads the linked owner's attribute_groups just the same" do
      source = create(:type).default_variant.tap do |t|
        t.attribute_groups = [["source_only_group", %w(assignee)]]
        t.save!
      end
      type.update!(attribute_groups: [["own_group", %w(assignee)]])
      link_configuration(type, source:, aspect: TypeVariant::FORM_CONFIGURATION)

      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("source_only_group")
      expect(keys).not_to include("own_group")
    end
  end

  describe "project attributes resolution" do
    let(:project_attributes_aspect) { TypeVariant::PROJECT_ATTRIBUTES }
    let(:owner_field) { create(:project_custom_field) }
    let(:own_field) { create(:project_custom_field) }
    let(:owner) { create(:type).default_variant }

    before do
      ProjectCustomFieldTypeMapping.create!(type_variant: owner, project_custom_field: owner_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: type, project_custom_field: own_field)
    end

    it "reads its own mappings when Independent" do
      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id)
    end

    it "reads the owner's mappings when Linked" do
      link_configuration(type, source: owner, aspect: project_attributes_aspect)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end

    it "resolves through a longer link chain to the owning type" do
      middle = create(:type).default_variant
      link_configuration(middle, source: owner, aspect: project_attributes_aspect)
      link_configuration(type, source: middle, aspect: project_attributes_aspect)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end

    it "drops an excluded attribute from the inherited mappings" do
      link(type, source: owner, aspect: project_attributes_aspect, excluded: [owner_field.attribute_name])

      expect(type.project_custom_field_type_mappings).to be_empty
    end

    it "keeps the attributes the chain does not exclude" do
      kept_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: owner, project_custom_field: kept_field)
      link(type, source: owner, aspect: project_attributes_aspect, excluded: [owner_field.attribute_name])

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(kept_field.id)
    end

    it "accumulates exclusions over a chain" do
      second_field = create(:project_custom_field)
      third_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: owner, project_custom_field: second_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: owner, project_custom_field: third_field)

      middle = create(:type).default_variant
      link(middle, source: owner, aspect: project_attributes_aspect, excluded: [owner_field.attribute_name])
      link(type, source: middle, aspect: project_attributes_aspect, excluded: [second_field.attribute_name])

      expect(middle.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(second_field.id, third_field.id)
      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(third_field.id)
    end

    it "leaves the owning type's own mappings untouched" do
      link(type, source: owner, aspect: project_attributes_aspect, excluded: [owner_field.attribute_name])

      expect(owner.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end

    it "keeps writing to its own mappings while Linked" do
      link_configuration(type, source: owner, aspect: project_attributes_aspect)
      another_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: type, project_custom_field: another_field)

      expect(type.own_project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id, another_field.id)
    end
  end

  describe "#effective_excluded_elements" do
    let(:aspect) { TypeVariant::FORM_CONFIGURATION }
    let(:owner) { create(:type).default_variant }
    let(:middle) { create(:type).default_variant }

    it "excludes nothing when Independent" do
      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "excludes nothing when Linked without exclusions" do
      link_configuration(type, source: owner, aspect:)

      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "returns the exclusions of a single link" do
      link(type, source: owner, aspect:, excluded: %w[custom_field_1 assignee])

      expect(type.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1", "assignee")
    end

    it "unions the exclusions of every link along the chain" do
      link(middle, source: owner, aspect:, excluded: %w[custom_field_1])
      link(type, source: middle, aspect:, excluded: %w[custom_field_2])

      expect(type.effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2")
    end

    it "leaves an intermediate type unaffected by its descendants' exclusions" do
      link(middle, source: owner, aspect:, excluded: %w[custom_field_1])
      link(type, source: middle, aspect:, excluded: %w[custom_field_2])

      expect(middle.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    it "reports an element excluded at two levels of the chain only once" do
      link(middle, source: owner, aspect:, excluded: %w[custom_field_1])
      link(type, source: middle, aspect:, excluded: %w[custom_field_1])

      expect(type.effective_excluded_elements(aspect)).to eq(["custom_field_1"])
    end

    it "keeps exclusions scoped to their own aspect" do
      link(type, source: owner, aspect:, excluded: %w[custom_field_1])
      link(type, source: owner, aspect: TypeVariant::PROJECT_ATTRIBUTES, excluded: %w[custom_field_2])

      expect(type.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    it "excludes nothing on a cyclic chain instead of raising" do
      # Same legacy-data case as #effective_source_for: a pure cycle owns nothing, so the
      # walk finds no terminal row to read exclusions from.
      other = create(:type).default_variant
      link(type, source: other, aspect:, excluded: %w[custom_field_1])
      link_without_validation(other, source: type, aspect:, excluded: %w[custom_field_2])

      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "excludes nothing for a new record" do
      expect(TypeVariant.new.effective_excluded_elements(aspect)).to eq([])
    end

    context "with the flag off", with_flag: { type_variants: false } do
      it "resolves the chain's exclusions the same" do
        link(type, source: owner, aspect:, excluded: %w[custom_field_1])

        expect(type.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
      end
    end
  end

  # The call sites inline this as `<key> <> ALL (<subquery>)`, so the cases that matter
  # are the ones where a mis-shaped subquery would silently invert the filter.
  describe ".effective_excluded_elements_subquery" do
    let(:aspect) { TypeVariant::FORM_CONFIGURATION }

    def excluded_by_sql?(element)
      subquery = TypeVariant.effective_excluded_elements_subquery(type.id, aspect)

      TypeVariant.connection.select_value("SELECT 1 WHERE '#{element}' <> ALL (#{subquery})").nil?
    end

    it "excludes an element the chain excludes" do
      link(type, source: create(:type).default_variant, aspect:, excluded: %w[custom_field_1])

      expect(excluded_by_sql?("custom_field_1")).to be(true)
      expect(excluded_by_sql?("custom_field_2")).to be(false)
    end

    it "excludes nothing when the type owns the aspect" do
      expect(excluded_by_sql?("custom_field_1")).to be(false)
    end

    it "excludes nothing when the chain is cyclic" do
      # A pure cycle yields no rows, and `<> ALL` over no rows is TRUE. An array-scalar
      # subquery would yield NULL here and exclude every candidate instead of none.
      other = create(:type).default_variant
      link(type, source: other, aspect:, excluded: %w[custom_field_1])
      link_without_validation(other, source: type, aspect:)

      expect(excluded_by_sql?("custom_field_1")).to be(false)
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

    it "accepts a subquery yielding one element per row" do
      link_configuration(type, source: source, aspect: TypeVariant::PROJECT_ATTRIBUTES)
      subquery = TypeVariant.effective_excluded_elements_subquery(type.id, TypeVariant::PROJECT_ATTRIBUTES)
      condition = TypeVariant.excluded_custom_field_condition("7", subquery)

      expect(TypeVariant.connection.select_value("SELECT 1 WHERE #{condition}")).to eq(1)
    end
  end

  describe "project attributes resolution with the flag off", with_flag: { type_variants: false } do
    it "reads the linked owner's mappings just the same" do
      owner = create(:type).default_variant
      owner_field = create(:project_custom_field)
      own_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: owner, project_custom_field: owner_field)
      ProjectCustomFieldTypeMapping.create!(type_variant: type, project_custom_field: own_field)
      link_configuration(type, source: owner, aspect: TypeVariant::PROJECT_ATTRIBUTES)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end
  end
end
