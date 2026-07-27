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

RSpec.describe Type::ConfigurationLinkable do
  let(:type) { create(:type) }
  let(:source) { create(:type) }
  let(:aspect) { Type::ConfigurationLink::DEFAULTS }

  describe "#linked? and #source_for" do
    it "reports Independent (no link) by default" do
      expect(type).not_to be_linked(aspect)
      expect(type.source_for(aspect)).to be_nil
    end

    it "reports Linked once a link exists" do
      type.link!(aspect, source:)

      expect(type).to be_linked(aspect)
      expect(type.source_for(aspect)).to eq(source)
    end

    it "tracks each aspect independently" do
      type.link!(Type::ConfigurationLink::DEFAULTS, source:)

      expect(type).to be_linked(Type::ConfigurationLink::DEFAULTS)
      expect(type).not_to be_linked(Type::ConfigurationLink::PDF_EXPORT)
    end
  end

  describe "#link!" do
    it "re-points an existing link rather than creating a duplicate" do
      other_source = create(:type)
      type.link!(aspect, source:)

      expect { type.link!(aspect, source: other_source) }
        .not_to change { type.configuration_links.where(aspect:).count }.from(1)
      expect(type.source_for(aspect)).to eq(other_source)
    end
  end

  describe "variant default parent links" do
    it "links the default aspects to the parent when a variant is created" do
      parent = create(:type)
      child = create(:type, parent:)

      expect(child.source_for(Type::ConfigurationLink::PDF_EXPORT)).to eq(parent)
      expect(child.source_for(Type::ConfigurationLink::DEFAULTS)).to eq(parent)
      expect(child.source_for(Type::ConfigurationLink::PROJECT_ATTRIBUTES)).to eq(parent)
    end

    it "leaves the not-yet-implemented aspects Independent" do
      child = create(:type, parent: create(:type))

      expect(child).not_to be_linked(Type::ConfigurationLink::WORKFLOWS)
      expect(child).not_to be_linked(Type::ConfigurationLink::AUTOMATIONS)
      expect(child).not_to be_linked(Type::ConfigurationLink::PROJECTS)
      expect(child).not_to be_linked(Type::ConfigurationLink::FORM_CONFIGURATION)
    end

    it "leaves a root type Independent for all aspects" do
      root = create(:type)

      Type::ConfigurationLink::ASPECTS.each do |aspect|
        expect(root).not_to be_linked(aspect)
      end
    end
  end

  describe "deletion" do
    it "destroys the type's own links when the type is destroyed" do
      type.link!(aspect, source:)

      type.destroy

      expect(Type::ConfigurationLink.where(type_id: type.id)).to be_empty
    end

    it "prevents destroying a type that is still a source for another type" do
      type.link!(aspect, source:)

      expect(source.destroy).to be_falsey
      expect(source.errors[:base]).to be_present
    end
  end

  describe "#effective_source_for", with_flag: { type_variants: true } do
    it "returns itself when Independent" do
      expect(type.effective_source_for(aspect)).to eq(type)
    end

    it "walks the link chain to the owning Independent type" do
      owner = create(:type)
      middle = create(:type)
      middle.link!(aspect, source: owner)
      type.link!(aspect, source: middle)

      expect(type.effective_source_for(aspect)).to eq(owner)
    end

    it "terminates on a cycle instead of looping forever" do
      # A cycle can no longer be created through validated writes, so bypass validation
      # to reproduce a cyclic row that predates write-time prevention (FND-133).
      other = create(:type)
      type.link!(aspect, source: other)
      build(:type_configuration_link, type: other, source: type, aspect:).save!(validate: false)

      expect { type.effective_source_for(aspect) }.not_to raise_error
    end
  end

  # Each aspect's readers are overridden so that plain `type.patterns` etc. is the
  # configuration in force. The own_* attributes below are what the type stores
  # itself, and must stay visible through read_attribute even while linked.
  describe "resolved configuration readers", with_flag: { type_variants: true } do
    let(:owner_attributes) do
      {
        patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
        description: "Owner description",
        artefact_export_mode: Type::ArtefactExport::ATTACHMENT,
        export_templates_disabled: %w[contract],
        export_templates_order: %w[artefact attributes contract]
      }
    end
    let(:own_attributes) do
      {
        patterns: { subject: { blueprint: "Own {{id}}", enabled: true } },
        description: "Own description",
        artefact_export_mode: Type::ArtefactExport::FILE_LINK,
        export_templates_disabled: %w[artefact],
        export_templates_order: %w[contract attributes artefact]
      }
    end

    let(:owner) { create(:type, **owner_attributes) }

    before { type.update!(own_attributes) }

    context "when Independent" do
      it "reads the DEFAULTS attributes it stores itself" do
        expect(type.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(type.description).to eq("Own description")
      end

      it "reads the PDF_EXPORT attributes it stores itself" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(type.export_templates_disabled).to eq(%w[artefact])
        expect(type.export_templates_order).to eq(%w[contract attributes artefact])
      end
    end

    context "when Linked for DEFAULTS only" do
      before { type.link!(Type::ConfigurationLink::DEFAULTS, source: owner) }

      it "reads the DEFAULTS attributes from the owner" do
        expect(type.patterns.subject.blueprint).to eq("Owner {{id}}")
        expect(type.description).to eq("Owner description")
      end

      it "leaves the PDF_EXPORT attributes on this type" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::FILE_LINK)
        expect(type.export_templates_disabled).to eq(%w[artefact])
      end

      it "keeps writing to its own record" do
        type.update!(description: "Rewritten")

        expect(type.read_attribute(:description)).to eq("Rewritten")
        expect(owner.reload.description).to eq("Owner description")
      end
    end

    context "when Linked for PDF_EXPORT only" do
      before { type.link!(Type::ConfigurationLink::PDF_EXPORT, source: owner) }

      it "reads the PDF_EXPORT attributes from the owner" do
        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
        expect(type.export_templates_disabled).to eq(%w[contract])
        expect(type.export_templates_order).to eq(%w[artefact attributes contract])
      end

      it "leaves the DEFAULTS attributes on this type" do
        expect(type.patterns.subject.blueprint).to eq("Own {{id}}")
        expect(type.description).to eq("Own description")
      end

      it "falls back to the artefact export default when the owner has none" do
        owner.update!(artefact_export_mode: nil)

        expect(type.artefact_export_mode).to eq(Type::ArtefactExport::DEFAULT)
      end
    end

    it "reads from the type at the end of the link chain, not the one in the middle" do
      middle = create(:type, description: "Middle description")
      middle.link!(Type::ConfigurationLink::DEFAULTS, source: owner)
      type.link!(Type::ConfigurationLink::DEFAULTS, source: middle)

      expect(type.description).to eq("Owner description")
    end
  end

  # These read through the overridden attribute readers rather than resolving a
  # source themselves, so they are what proves the indirection actually pays off.
  describe "consumers of the resolved readers", with_flag: { type_variants: true } do
    let(:owner) do
      create(:type,
             patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
             artefact_export_mode: Type::ArtefactExport::ATTACHMENT,
             export_templates_disabled: %w[contract])
    end

    it "resolves #enabled_patterns and #replacement_pattern_defined_for? through the link" do
      type.link!(Type::ConfigurationLink::DEFAULTS, source: owner)

      expect(type.enabled_patterns.keys).to include(:subject)
      expect(type).to be_replacement_pattern_defined_for(:subject)
    end

    it "reports no subject pattern when Independent and none is set" do
      expect(type).not_to be_replacement_pattern_defined_for(:subject)
    end

    it "resolves #artefact_export_enabled? through the link" do
      expect(type).not_to be_artefact_export_enabled
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source: owner)

      expect(type).to be_artefact_export_enabled
    end

    it "lists the owner's enabled templates while wrapping this type" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source: owner)

      expect(type.pdf_export_templates.list_enabled.map(&:id)).to contain_exactly("attributes", "artefact")
    end

    # The templates object mutates whatever type it wraps, so it must never be the
    # owner's — otherwise a linked variant would rewrite the source's configuration.
    it "writes template changes to this type rather than the owner" do
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source: owner)
      type.pdf_export_templates.disable_all
      type.save!

      expect(type.read_attribute(:pdf_export_templates_config)["export_templates_disabled"])
        .to contain_exactly("attributes", "contract", "artefact")
      expect(owner.reload.export_templates_disabled).to eq(%w[contract])
    end
  end

  describe "feature flag gating", with_flag: { type_variants: false } do
    let(:owner) do
      create(:type,
             patterns: { subject: { blueprint: "Owner {{id}}", enabled: true } },
             description: "Owner description",
             artefact_export_mode: Type::ArtefactExport::ATTACHMENT)
    end

    before do
      type.link!(Type::ConfigurationLink::DEFAULTS, source: owner)
      type.link!(Type::ConfigurationLink::PDF_EXPORT, source: owner)
    end

    it "ignores links and resolves to the type's own configuration" do
      expect(type.effective_source_for(Type::ConfigurationLink::DEFAULTS)).to eq(type)
      expect(type.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
      expect(type.description).to be_nil
      expect(type.artefact_export_mode).to eq(Type::ArtefactExport::DEFAULT)
      expect(type).not_to be_replacement_pattern_defined_for(:subject)
    end
  end

  describe "form configuration resolution", with_flag: { type_variants: true } do
    let(:form_aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }
    let(:source) do
      create(:type).tap do |t|
        t.attribute_groups = [["source_only_group", %w(assignee)]]
        t.save!
      end
    end

    before { type.update!(attribute_groups: [["own_group", %w(assignee)]]) }

    it "reads attribute_groups from the linked owner" do
      type.link!(form_aspect, source:)

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
      type.link!(form_aspect, source:)
      type.attribute_groups = [["pending_group", %w(assignee)]]

      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("pending_group")
      expect(keys).not_to include("source_only_group")
    end

    it "reads custom_fields from the linked owner" do
      cf = create(:integer_wp_custom_field)
      source.custom_fields << cf
      type.link!(form_aspect, source:)

      expect(type.custom_fields).to include(cf)
    end

    it "still appends custom_fields to its own record when Independent" do
      cf = create(:integer_wp_custom_field)
      type.custom_fields << cf

      expect(type.custom_fields).to include(cf)
    end
  end

  describe "form configuration with the flag off", with_flag: { type_variants: false } do
    it "ignores the link and reads its own attribute_groups" do
      source = create(:type).tap do |t|
        t.attribute_groups = [["source_only_group", %w(assignee)]]
        t.save!
      end
      type.update!(attribute_groups: [["own_group", %w(assignee)]])
      type.link!(Type::ConfigurationLink::FORM_CONFIGURATION, source:)

      keys = type.attribute_groups.map(&:key)
      expect(keys).to include("own_group")
      expect(keys).not_to include("source_only_group")
    end
  end

  describe "project attributes resolution", with_flag: { type_variants: true } do
    let(:project_attributes_aspect) { Type::ConfigurationLink::PROJECT_ATTRIBUTES }
    let(:owner_field) { create(:project_custom_field) }
    let(:own_field) { create(:project_custom_field) }
    let(:owner) { create(:type) }

    before do
      ProjectCustomFieldTypeMapping.create!(type: owner, project_custom_field: owner_field)
      ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: own_field)
    end

    it "reads its own mappings when Independent" do
      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id)
    end

    it "reads the owner's mappings when Linked" do
      type.link!(project_attributes_aspect, source: owner)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end

    it "resolves through a longer link chain to the owning type" do
      middle = create(:type)
      middle.link!(project_attributes_aspect, source: owner)
      type.link!(project_attributes_aspect, source: middle)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(owner_field.id)
    end

    it "keeps writing to its own mappings while Linked" do
      type.link!(project_attributes_aspect, source: owner)
      another_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: another_field)

      expect(type.own_project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id, another_field.id)
    end
  end

  describe "#effective_excluded_elements", with_flag: { type_variants: true } do
    let(:owner) { create(:type) }
    let(:middle) { create(:type) }

    it "excludes nothing when Independent" do
      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "excludes nothing when Linked without exclusions" do
      type.link!(aspect, source: owner)

      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "returns the exclusions of a single link" do
      create(:type_configuration_link, type:, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1 assignee])

      expect(type.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1", "assignee")
    end

    it "unions the exclusions of every link along the chain" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2])

      expect(type.effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2")
    end

    it "leaves an intermediate type unaffected by its descendants' exclusions" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2])

      expect(middle.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    it "reports an element excluded at two levels of the chain only once" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_1])

      expect(type.effective_excluded_elements(aspect)).to eq(["custom_field_1"])
    end

    it "keeps exclusions scoped to their own aspect" do
      create(:type_configuration_link, type:, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: owner,
                                       aspect: Type::ConfigurationLink::PDF_EXPORT,
                                       excluded_elements: %w[custom_field_2])

      expect(type.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    it "excludes nothing on a cyclic chain instead of raising" do
      # Same legacy-data case as #effective_source_for: a pure cycle owns nothing, so the
      # walk finds no terminal row to read exclusions from.
      other = create(:type)
      create(:type_configuration_link, type:, source: other, aspect:,
                                       excluded_elements: %w[custom_field_1])
      build(:type_configuration_link, type: other, source: type, aspect:,
                                      excluded_elements: %w[custom_field_2]).save!(validate: false)

      expect(type.effective_excluded_elements(aspect)).to eq([])
    end

    it "excludes nothing for a new record" do
      expect(Type.new.effective_excluded_elements(aspect)).to eq([])
    end

    context "with the flag off", with_flag: { type_variants: false } do
      it "ignores the link's exclusions" do
        create(:type_configuration_link, type:, source: owner, aspect:,
                                         excluded_elements: %w[custom_field_1])

        expect(type.effective_excluded_elements(aspect)).to eq([])
      end
    end
  end

  # The call sites inline this as `<key> <> ALL (<subquery>)`, so the cases that matter
  # are the ones where a mis-shaped subquery would silently invert the filter.
  describe ".effective_excluded_elements_subquery", with_flag: { type_variants: true } do
    def excluded_by_sql?(element)
      subquery = Type.effective_excluded_elements_subquery(type.id, aspect)

      Type.connection.select_value("SELECT 1 WHERE '#{element}' <> ALL (#{subquery})").nil?
    end

    it "excludes an element the chain excludes" do
      create(:type_configuration_link, type:, source: create(:type), aspect:,
                                       excluded_elements: %w[custom_field_1])

      expect(excluded_by_sql?("custom_field_1")).to be(true)
      expect(excluded_by_sql?("custom_field_2")).to be(false)
    end

    it "excludes nothing when the type owns the aspect" do
      expect(excluded_by_sql?("custom_field_1")).to be(false)
    end

    it "excludes nothing when the chain is cyclic" do
      # A pure cycle yields no rows, and `<> ALL` over no rows is TRUE. An array-scalar
      # subquery would yield NULL here and exclude every candidate instead of none.
      other = create(:type)
      create(:type_configuration_link, type:, source: other, aspect:,
                                       excluded_elements: %w[custom_field_1])
      build(:type_configuration_link, type: other, source: type, aspect:).save!(validate: false)

      expect(excluded_by_sql?("custom_field_1")).to be(false)
    end
  end

  describe "project attributes resolution with the flag off", with_flag: { type_variants: false } do
    it "ignores the link and reads its own mappings" do
      owner = create(:type)
      owner_field = create(:project_custom_field)
      own_field = create(:project_custom_field)
      ProjectCustomFieldTypeMapping.create!(type: owner, project_custom_field: owner_field)
      ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: own_field)
      type.link!(Type::ConfigurationLink::PROJECT_ATTRIBUTES, source: owner)

      expect(type.project_custom_field_type_mappings.map(&:custom_field_id))
        .to contain_exactly(own_field.id)
    end
  end
end
