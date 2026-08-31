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

RSpec.describe Type do
  let(:type) { create(:type) }
  let(:type2) { create(:type) }
  let(:project) { build(:project, no_types: true) }

  describe ".enabled_in(project)" do
    before do
      project.save
      ProjectType.create!(project:, type:, variant: type.default_variant)
    end

    it "returns the types enabled in the provided project" do
      expect(described_class.enabled_in(project)).to contain_exactly(type)
    end

    context "with variants", with_flag: { type_variants: true } do
      shared_let(:enabled_root) { create(:type, name: "Enabled root") }
      shared_let(:enabled_variant) { create(:type_variant, type: enabled_root, variant_name: "Enabled variant") }
      shared_let(:on_variant) { create(:project, types: [enabled_variant]) }
      shared_let(:also_on_root) { create(:project, types: [enabled_root]) }

      it "returns the root a project uses even when it resolves a variant" do
        expect(described_class.enabled_in(on_variant)).to contain_exactly(enabled_root)
      end

      it "never returns a variant" do
        expect(described_class.enabled_in(on_variant)).not_to include(enabled_variant)
      end

      it "names a root shared by several projects once, including when plucking ids" do
        projects = Project.where(id: [on_variant.id, also_on_root.id])

        expect(described_class.enabled_in(projects).pluck(:id)).to contain_exactly(enabled_root.id)
      end
    end
  end

  describe "#projects" do
    shared_let(:root) { create(:type, name: "Bug") }
    shared_let(:variant) { create(:type_variant, type: root, variant_name: "Mobile Bug") }

    shared_let(:project_using_root) { create(:project, types: [root]) }
    shared_let(:project_using_variant) { create(:project, types: [variant]) }

    it "includes every project using the family" do
      expect(root.projects).to contain_exactly(project_using_root, project_using_variant)
    end

    it "includes a project applying one of its variants" do
      expect(root.projects).to include(project_using_variant)
    end
  end

  describe "TypeVariant#projects" do
    shared_let(:root) { create(:type, name: "Bug") }
    shared_let(:variant) { create(:type_variant, type: root, variant_name: "Mobile Bug") }
    shared_let(:sibling) { create(:type_variant, type: root, variant_name: "Tablet Bug") }

    shared_let(:project_using_root) { create(:project, types: [root]) }
    shared_let(:project_using_variant) { create(:project, types: [variant]) }

    it "names the projects the variant configures" do
      expect(variant.projects).to contain_exactly(project_using_variant)
    end

    it "excludes projects applying another variant of the same type" do
      expect(root.default_variant.projects).to contain_exactly(project_using_root)
      expect(sibling.projects).to be_empty
    end
  end

  describe "TypeVariant#activate_custom_fields_in_effective_projects!" do
    shared_let(:root) { create(:type, name: "Bug") }
    shared_let(:variant) { create(:type_variant, type: root, variant_name: "Mobile Bug") }

    shared_let(:project_using_variant) { create(:project, types: [variant]) }
    shared_let(:project_using_root) { create(:project, types: [root]) }

    # A field on the variant's own form is invisible in the work package form until the project
    # activates it, and nothing else can find the projects a variant configures.
    it "activates the type's fields in the projects it configures" do
      custom_field = create(:integer_wp_custom_field, type_variants: [variant])

      expect { variant.activate_custom_fields_in_effective_projects! }
        .to change { project_using_variant.reload.work_package_custom_field_ids }
        .from([])
        .to([custom_field.id])
    end

    it "leaves projects resolving the family elsewhere alone" do
      create(:integer_wp_custom_field, type_variants: [variant])

      expect { variant.activate_custom_fields_in_effective_projects! }
        .not_to change { project_using_root.reload.work_package_custom_field_ids }
    end

    it "adds to a project's activation rather than replacing it" do
      existing = create(:integer_wp_custom_field)
      project_using_variant.work_package_custom_fields << existing
      added = create(:integer_wp_custom_field, type_variants: [variant])

      variant.activate_custom_fields_in_effective_projects!

      expect(project_using_variant.reload.work_package_custom_field_ids)
        .to contain_exactly(existing.id, added.id)
    end
  end

  describe ".visible" do
    subject { described_class.visible(user) }

    let!(:type) { create(:status) }
    let(:user) { create(:user) }
    let(:permissions) { %i[view_work_packages] }

    before do
      create(:member, user:, roles: [create(:project_role, permissions: permissions)])
    end

    it "returns the same types as all" do
      expect(subject.to_a).to match_array(described_class.all.to_a)
    end

    context "when the user has the manage_types permission in a project" do
      let(:permissions) { %i[manage_types] }

      it "returns the same types as all" do
        expect(subject.to_a).to match_array(described_class.all.to_a)
      end
    end

    context "when the user has the wrong permission" do
      let(:permissions) { %i[view_wikis] }

      it "returns no types" do
        expect(subject.to_a).to be_empty
      end
    end
  end

  describe "#statuses" do
    subject { type.default_variant.statuses }

    context "when new" do
      subject { build(:type_variant).statuses }

      it "returns an empty relation" do
        expect(subject).to be_empty
      end
    end

    context "when existing but no statuses" do
      let(:type) { create(:type) }

      it "returns an empty relation" do
        expect(subject).to be_empty
      end
    end

    context "when existing with workflow" do
      let(:role) { create(:project_role) }
      let(:statuses) { (1..2).map { |_i| create(:status) } }

      let!(:type) { create(:type) }
      let!(:workflow_a) do
        create(:workflow, role_id: role.id,
                          type_variant: type.default_variant,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      it "returns the statuses relation" do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end

      context "with default status" do
        let!(:default_status) { create(:default_status) }

        subject { type.default_variant.statuses(include_default: true) }

        it "returns the workflow and the default status" do
          expect(subject.pluck(:id)).to contain_exactly(default_status.id, statuses[0].id, statuses[1].id)
        end
      end

      context "with role filter" do
        let(:other_role) { create(:project_role) }
        let(:other_statuses) { (1..2).map { create(:status) } }
        let!(:other_workflow) do
          create(:workflow, role_id: other_role.id,
                            type_variant: type.default_variant,
                            old_status_id: other_statuses[0].id,
                            new_status_id: other_statuses[1].id)
        end

        subject { type.default_variant.statuses(role:) }

        it "returns only statuses for the given role" do
          expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end
      end

      context "with tab filter" do
        let(:author_statuses) { (1..2).map { create(:status) } }
        let(:assignee_statuses) { (1..2).map { create(:status) } }
        let!(:author_workflow) do
          create(:workflow, role_id: role.id,
                            type_variant: type.default_variant,
                            old_status_id: author_statuses[0].id,
                            new_status_id: author_statuses[1].id,
                            author: true,
                            assignee: false)
        end
        let!(:assignee_workflow) do
          create(:workflow, role_id: role.id,
                            type_variant: type.default_variant,
                            old_status_id: assignee_statuses[0].id,
                            new_status_id: assignee_statuses[1].id,
                            author: false,
                            assignee: true)
        end

        it "returns only always statuses for the always tab" do
          expect(type.default_variant.statuses(tab: "always").pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end

        it "returns only author statuses for the author tab" do
          expect(type.default_variant.statuses(tab: "author").pluck(:id)).to contain_exactly(author_statuses[0].id,
                                                                                             author_statuses[1].id)
        end

        it "returns only assignee statuses for the assignee tab" do
          expect(type.default_variant.statuses(tab: "assignee").pluck(:id)).to contain_exactly(assignee_statuses[0].id,
                                                                                               assignee_statuses[1].id)
        end
      end
    end

    context "when linked to a source type" do
      let(:role) { create(:project_role) }
      let(:statuses) { create_list(:status, 2) }
      let!(:source) { create(:type) }
      let!(:type) { create(:type) }
      let!(:workflow) do
        create(:workflow, role_id: role.id,
                          type_variant: source.default_variant,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      before { link_configuration(type.default_variant, source: source.default_variant, aspect: TypeVariant::WORKFLOWS) }

      it "resolves the source's statuses" do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end

      it "resolves the same with the feature disabled", with_flag: { type_variants: false } do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end
    end

    context "when linked through a longer chain", with_flag: { type_variants: true } do
      let(:role) { create(:project_role) }
      let(:statuses) { create_list(:status, 2) }
      let!(:owner) { create(:type) }
      let!(:middle) { create(:type) }
      let!(:type) { create(:type) }
      let!(:workflow) do
        create(:workflow, role_id: role.id,
                          type_variant: owner.default_variant,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      before do
        link_configuration(middle.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)
        link_configuration(type.default_variant, source: middle.default_variant, aspect: TypeVariant::WORKFLOWS)
      end

      it "resolves statuses from the chain's owning type" do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end
    end
  end

  describe "#copy_from_type on own_workflows" do
    before do
      allow(Workflow)
        .to receive(:copy)
    end

    it "calls the .copy method on Workflow" do
      type.default_variant.own_workflows.copy_from_variant(type2.default_variant)

      expect(Workflow)
        .to have_received(:copy)
        .with(type2.default_variant, nil, type.default_variant, nil)
    end
  end

  describe "#workflows", with_flag: { type_variants: true } do
    let(:role) { create(:project_role) }
    let(:statuses) { create_list(:status, 2) }
    let!(:type) { create(:type) }
    let!(:owner) { create(:type) }
    let!(:owner_workflow) do
      create(:workflow, type_variant: owner.default_variant, role_id: role.id,
                        old_status_id: statuses[0].id, new_status_id: statuses[1].id)
    end

    it "returns its own workflows when unlinked" do
      own = create(:workflow, type_variant: type.default_variant, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)

      expect(type.default_variant.workflows).to contain_exactly(own)
    end

    it "resolves a child to its linked parent's workflows" do
      link_configuration(type.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)

      expect(type.default_variant.workflows).to contain_exactly(owner_workflow)
    end

    it "resolves through a longer chain to the owning type's workflows" do
      middle = create(:type)
      link_configuration(middle.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)
      link_configuration(type.default_variant, source: middle.default_variant, aspect: TypeVariant::WORKFLOWS)

      expect(type.default_variant.workflows).to contain_exactly(owner_workflow)
    end

    it "reads the source's rows and not its own while linked" do
      own = create(:workflow, type_variant: type.default_variant, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)
      link_configuration(type.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)

      expect(type.default_variant.workflows).to contain_exactly(owner_workflow)
      expect(type.default_variant.workflows).not_to include(own)
    end

    it "resolves the link the same with the feature disabled", with_flag: { type_variants: false } do
      own = create(:workflow, type_variant: type.default_variant, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)
      link_configuration(type.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)

      expect(type.default_variant.workflows).to contain_exactly(owner_workflow)
      expect(type.default_variant.workflows).not_to include(own)
    end

    it "writes through #own_workflows to its own rows while linked, leaving the source untouched" do
      link_configuration(type.default_variant, source: owner.default_variant, aspect: TypeVariant::WORKFLOWS)
      expect(type.default_variant.own_workflows).to be_empty

      type.default_variant.own_workflows.copy_from_variant(owner.default_variant)

      expect(type.default_variant.own_workflows.sole)
        .to have_attributes(old_status_id: statuses[0].id, new_status_id: statuses[1].id)
      expect(owner.default_variant.reload.own_workflows).to contain_exactly(owner_workflow)
    end
  end

  describe "#work_package_attributes" do
    subject { type.default_variant.work_package_attributes }

    context "for the duration field" do
      it "does not return the field" do
        expect(subject).not_to have_key("duration")
      end
    end

    context "for the ignore_non_working_days field" do
      it "does not return the field" do
        expect(subject).not_to have_key("ignore_non_working_days")
      end
    end
  end

  describe "#patterns" do
    it "returns an empty collection when no patterns are defined" do
      type = create(:type)

      expect(type.default_variant.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
    end

    it "returns a PatternCollection" do
      type = create(:type)
      type.default_variant.update!(patterns: {
                                     subject: { blueprint: "{{work_package:custom_field_123}} - {{project:custom_field_321}}",
                                                enabled: true }
                                   })

      expect(type.default_variant.patterns).to be_a(WorkPackageTypes::Patterns::Collection)
      expect(type.default_variant.patterns.subject)
        .to eq(WorkPackageTypes::Pattern.new("{{work_package:custom_field_123}} - {{project:custom_field_321}}", true))
    end
  end

  describe "#patterns=" do
    subject(:type) { build(:type_variant) }

    it "assigns a patterns collection as-is" do
      collection = WorkPackageTypes::Patterns::Collection.build(patterns: {
                                                                  subject: { blueprint: "some_string", enabled: false }
                                                                }).value!

      type.patterns = collection

      expect(type.patterns).to eq(collection)
      expect { type.save! }.not_to raise_error
    end

    context "when an invalid value is passed" do
      it "defaults to an empty collection" do
        type.patterns = 4

        expect(type.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
        expect { type.save! }.not_to raise_error
      end
    end

    context "when a hash is passed" do
      it "converts the incoming hash into a PatternCollection" do
        type.patterns = { subject: { blueprint: "some_string", enabled: false } }

        expect(type.patterns).to be_a(WorkPackageTypes::Patterns::Collection)
        expect(type.patterns.subject).to be_a(WorkPackageTypes::Pattern)

        expect { type.save! }.not_to raise_error
      end
    end
  end

  describe "#artefact_export_mode" do
    it "defaults to 'off'" do
      expect(build(:type_variant).artefact_export_mode).to eq(Type::ArtefactExport::OFF)
    end

    it "persists the value into the pdf_export_templates_config jsonb column" do
      persisted = create(:type).default_variant
      persisted.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)

      expect(persisted.reload.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
      expect(persisted.pdf_export_templates_config).to include("artefact_export_mode" => "attachment")
    end
  end

  describe "#artefact_export_enabled?" do
    it "is false when off" do
      expect(build(:type_variant,
                   pdf_export_templates_config: { "artefact_export_mode" => "off" })).not_to be_artefact_export_enabled
    end

    it "is true when a storing mode is set" do
      expect(build(:type_variant,
                   pdf_export_templates_config: { "artefact_export_mode" => "file_link" })).to be_artefact_export_enabled
    end
  end

  describe "#pdf_export_templates settings" do
    subject(:type) { create(:type).default_variant }

    it "defaults to an empty hash for a fresh type" do
      expect(type.pdf_export_templates.settings_for("attributes")).to eq({})
    end

    it "round-trips settings through #update_settings/#settings_for for each template" do
      %w[attributes contract artefact].each do |template_id|
        type.pdf_export_templates.update_settings(template_id, "hyphenation" => "true")
      end
      type.save!

      %w[attributes contract artefact].each do |template_id|
        expect(type.reload.pdf_export_templates.settings_for(template_id)).to eq(hyphenation: "true")
      end
    end

    it "merges rather than replaces on repeated #update_settings calls" do
      type.pdf_export_templates.update_settings("attributes", "footer_text" => "A")
      type.pdf_export_templates.update_settings("attributes", "page_orientation" => "landscape")
      type.save!

      expect(type.reload.pdf_export_templates.settings_for("attributes"))
        .to eq(footer_text: "A", page_orientation: "landscape")
    end

    it "#clear_setting removes just one field, leaving the others" do
      type.pdf_export_templates.update_settings("attributes", "footer_text" => "A", "page_orientation" => "landscape")
      type.save!

      type.pdf_export_templates.clear_setting("attributes", "footer_text")
      type.save!

      expect(type.reload.pdf_export_templates.settings_for("attributes")).to eq(page_orientation: "landscape")
    end

    it "rejects an unknown template id" do
      expect { type.pdf_export_templates.settings_for("bogus") }.to raise_error(ArgumentError)
      expect { type.pdf_export_templates.update_settings("bogus", {}) }.to raise_error(ArgumentError)
      expect { type.pdf_export_templates.clear_setting("bogus", "footer_text") }.to raise_error(ArgumentError)
    end

    it "resolves through a configuration link", with_flag: { type_variants: true } do
      source = create(:type).default_variant
      source.pdf_export_templates.update_settings("attributes", "footer_text" => "Source footer")
      source.save!
      link_configuration(type, source:, aspect: TypeVariant::PDF_EXPORT)

      expect(type.pdf_export_templates.settings_for("attributes")).to eq(footer_text: "Source footer")
    end

    describe "#readonly?" do
      it "is false for an unlinked type" do
        expect(type.pdf_export_templates).not_to be_readonly
      end

      context "when linked to a source type", with_flag: { type_variants: true } do
        before { link_configuration(type, source: create(:type), aspect: TypeVariant::PDF_EXPORT) }

        it "is true" do
          expect(type.pdf_export_templates).to be_readonly
        end
      end

      context "when linked but type_variants is disabled" do
        before { link_configuration(type, source: create(:type), aspect: TypeVariant::PDF_EXPORT) }

        it "is false, since the link has no effect with the flag off" do
          expect(type.pdf_export_templates).not_to be_readonly
        end
      end
    end

    context "when linked to a source type", with_flag: { type_variants: true } do
      let(:source) { create(:type).default_variant }

      before do
        # `type` already has its own stored `contract` settings before being linked -
        # this is the data #update_settings must not clobber while resolving through the link.
        type.pdf_export_templates.update_settings("contract", "footer_text_center" => "Type's own contract footer")
        type.save!
        source.pdf_export_templates.update_settings("attributes", "footer_text" => "Source footer")
        source.pdf_export_templates.update_settings("contract", "footer_text_center" => "Source contract footer")
        source.save!
        link_configuration(type, source:, aspect: TypeVariant::PDF_EXPORT)
      end

      it "refuses to write via #update_settings, #clear_setting, #toggle, #move, #enable_all, #disable_all" do
        pdf_export_templates = type.pdf_export_templates

        expect { pdf_export_templates.update_settings("attributes", "footer_text" => "Attempted override") }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
        expect { pdf_export_templates.clear_setting("attributes", "footer_text") }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
        expect { pdf_export_templates.toggle("attributes") }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
        expect { pdf_export_templates.move("attributes", 1) }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
        expect { pdf_export_templates.enable_all }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
        expect { pdf_export_templates.disable_all }
          .to raise_error(Type::PdfExportTemplates::ReadonlyError)
      end

      it "does not corrupt the type's own settings for a different template once unlinked" do
        # Attempting to edit "attributes" while linked used to merge onto the *source's*
        # resolved settings hash (which includes the source's "contract" entry) and write
        # the whole thing back onto `type`'s own column, clobbering `type`'s own "contract"
        # settings with a copy of the source's. Guard against a regression of that.
        begin
          type.pdf_export_templates.update_settings("attributes", "footer_text" => "Attempted override")
        rescue Type::PdfExportTemplates::ReadonlyError
          # expected - the write must not happen at all
        end

        unlink_configuration(type, aspect: TypeVariant::PDF_EXPORT)

        expect(type.reload.pdf_export_templates.settings_for("contract"))
          .to eq(footer_text_center: "Type's own contract footer")
      end
    end
  end
end
