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
  let(:type) { build(:type) }
  let(:type2) { build(:type) }
  let(:project) { build(:project, no_types: true) }

  describe ".enabled_in(project)" do
    before do
      type.projects << project
      type.save

      type2.save
    end

    it "returns the types enabled in the provided project" do
      expect(described_class.enabled_in(project)).to contain_exactly(type)
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
    subject { type.statuses }

    context "when new" do
      let(:type) { build(:type) }

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
                          type_id: type.id,
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

        subject { type.statuses(include_default: true) }

        it "returns the workflow and the default status" do
          expect(subject.pluck(:id)).to contain_exactly(default_status.id, statuses[0].id, statuses[1].id)
        end
      end

      context "with role filter" do
        let(:other_role) { create(:project_role) }
        let(:other_statuses) { (1..2).map { create(:status) } }
        let!(:other_workflow) do
          create(:workflow, role_id: other_role.id,
                            type_id: type.id,
                            old_status_id: other_statuses[0].id,
                            new_status_id: other_statuses[1].id)
        end

        subject { type.statuses(role:) }

        it "returns only statuses for the given role" do
          expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end
      end

      context "with tab filter" do
        let(:author_statuses) { (1..2).map { create(:status) } }
        let(:assignee_statuses) { (1..2).map { create(:status) } }
        let!(:author_workflow) do
          create(:workflow, role_id: role.id,
                            type_id: type.id,
                            old_status_id: author_statuses[0].id,
                            new_status_id: author_statuses[1].id,
                            author: true,
                            assignee: false)
        end
        let!(:assignee_workflow) do
          create(:workflow, role_id: role.id,
                            type_id: type.id,
                            old_status_id: assignee_statuses[0].id,
                            new_status_id: assignee_statuses[1].id,
                            author: false,
                            assignee: true)
        end

        it "returns only always statuses for the always tab" do
          expect(type.statuses(tab: "always").pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end

        it "returns only author statuses for the author tab" do
          expect(type.statuses(tab: "author").pluck(:id)).to contain_exactly(author_statuses[0].id, author_statuses[1].id)
        end

        it "returns only assignee statuses for the assignee tab" do
          expect(type.statuses(tab: "assignee").pluck(:id)).to contain_exactly(assignee_statuses[0].id, assignee_statuses[1].id)
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
                          type_id: source.id,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      before { type.link!(Type::ConfigurationLink::WORKFLOWS, source:) }

      it "resolves the source's statuses", with_flag: { type_variants: true } do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end

      it "ignores the link and resolves its own statuses with the feature disabled",
         with_flag: { type_variants: false } do
        expect(subject).to be_empty
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
                          type_id: owner.id,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      before do
        middle.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)
        type.link!(Type::ConfigurationLink::WORKFLOWS, source: middle)
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
      type.own_workflows.copy_from_type(type2)

      expect(Workflow)
        .to have_received(:copy)
        .with(type2, nil, type, nil)
    end
  end

  describe "#workflows", with_flag: { type_variants: true } do
    let(:role) { create(:project_role) }
    let(:statuses) { create_list(:status, 2) }
    let!(:type) { create(:type) }
    let!(:owner) { create(:type) }
    let!(:owner_workflow) do
      create(:workflow, type_id: owner.id, role_id: role.id,
                        old_status_id: statuses[0].id, new_status_id: statuses[1].id)
    end

    it "returns its own workflows when unlinked" do
      own = create(:workflow, type_id: type.id, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)

      expect(type.workflows).to contain_exactly(own)
    end

    it "resolves a child to its linked parent's workflows" do
      type.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)

      expect(type.workflows).to contain_exactly(owner_workflow)
    end

    it "resolves through a longer chain to the owning type's workflows" do
      middle = create(:type)
      middle.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)
      type.link!(Type::ConfigurationLink::WORKFLOWS, source: middle)

      expect(type.workflows).to contain_exactly(owner_workflow)
    end

    it "reads the source's rows and not its own while linked" do
      own = create(:workflow, type_id: type.id, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)
      type.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)

      expect(type.workflows).to contain_exactly(owner_workflow)
      expect(type.workflows).not_to include(own)
    end

    it "ignores the link and returns its own workflows with the feature disabled",
       with_flag: { type_variants: false } do
      own = create(:workflow, type_id: type.id, role_id: role.id,
                              old_status_id: statuses[1].id, new_status_id: statuses[0].id)
      type.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)

      expect(type.workflows).to contain_exactly(own)
    end

    it "writes through #own_workflows to its own rows while linked, leaving the source untouched" do
      type.link!(Type::ConfigurationLink::WORKFLOWS, source: owner)
      expect(type.own_workflows).to be_empty

      type.own_workflows.copy_from_type(owner)

      expect(type.own_workflows.sole)
        .to have_attributes(old_status_id: statuses[0].id, new_status_id: statuses[1].id)
      expect(owner.reload.own_workflows).to contain_exactly(owner_workflow)
    end
  end

  describe "#work_package_attributes" do
    subject { type.work_package_attributes }

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

      expect(type.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
    end

    it "returns a PatternCollection" do
      type = create(:type, patterns: {
                      subject: { blueprint: "{{work_package:custom_field_123}} - {{project:custom_field_321}}", enabled: true }
                    })

      expect(type.patterns).to be_a(WorkPackageTypes::Patterns::Collection)
      expect(type.patterns.subject)
        .to eq(WorkPackageTypes::Pattern.new("{{work_package:custom_field_123}} - {{project:custom_field_321}}", true))
    end
  end

  describe "#patterns=" do
    subject(:type) { build(:type) }

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

  describe "hierarchy" do
    let!(:parent) { create(:type) }
    let!(:child) { create(:type, parent:) }

    describe "associations" do
      it "exposes parent and children" do
        expect(child.parent).to eq(parent)
        expect(parent.children).to contain_exactly(child)
      end
    end

    describe "scopes" do
      it ".roots returns only top level types" do
        expect(described_class.roots).to include(parent)
        expect(described_class.roots).not_to include(child)
      end

      it ".variants returns only nested types" do
        expect(described_class.variants).to contain_exactly(child)
      end

      it ".global returns every type (all types are global until project-owned types exist)" do
        expect(described_class.global).to include(parent, child)
      end
    end

    describe "#root" do
      it "returns the parent for a child" do
        expect(child.root).to eq(parent)
      end

      it "returns itself for a root" do
        expect(parent.root).to eq(parent)
      end
    end

    # Isolated from the shared parent/child so the factory's generated names
    # cannot land between the names under test.
    describe "#sorted_variants" do
      let!(:family_root) { create(:type, name: "Family") }
      let!(:yankee) { create(:type, name: "Yankee", parent: family_root) }
      let!(:bravo) { create(:type, name: "Bravo", parent: family_root) }

      it "orders variants alphabetically by their own name" do
        expect(family_root.sorted_variants.map(&:own_name)).to eq(%w[Bravo Yankee])
      end

      it "does not fall back to position, which is append order" do
        expect(family_root.children.map(&:own_name)).to eq(%w[Yankee Bravo])
      end
    end

    describe "#family" do
      it "returns the root followed by its children" do
        expect(child.family).to eq([parent, child])
        expect(parent.family).to eq([parent, child])
      end

      it "orders the variants the same way #sorted_variants does" do
        family_root = create(:type, name: "Family")
        create(:type, name: "Yankee", parent: family_root)
        create(:type, name: "Bravo", parent: family_root)

        expect(family_root.family).to eq([family_root, *family_root.sorted_variants])
        expect(family_root.family.map(&:own_name)).to eq(%w[Family Bravo Yankee])
      end
    end

    # The types index page and the configuration source pickers both read this,
    # so the assertions bind to what that page renders rather than to a literal
    # list, and the two cannot drift apart unnoticed.
    describe ".in_family_order" do
      let!(:zeta) { create(:type, name: "Zeta") }
      let!(:yankee) { create(:type, name: "Yankee", parent: zeta) }
      let!(:bravo) { create(:type, name: "Bravo", parent: zeta) }
      # Created last, so the admin's order and an alphabetical one disagree and
      # the assertions below can tell them apart.
      let!(:alpha) { create(:type, name: "Alpha") }

      it "keeps the roots in the order the index page lists them" do
        expect(described_class.in_family_order.reject(&:variant?)).to eq([parent, zeta, alpha])
      end

      it "orders a family's variants the way the index page renders them" do
        expect(described_class.in_family_order.select { |member| member.parent == zeta })
          .to eq([bravo, yankee])
      end

      it "puts a root ahead of its own variants" do
        order = described_class.in_family_order

        expect(order.index(zeta)).to be < order.index(bravo)
      end
    end

    describe "positioning" do
      it "scopes position per parent so each group is numbered independently" do
        parent_a = create(:type)
        parent_b = create(:type)
        a1 = create(:type, parent: parent_a, position: nil, name: "A1")
        a2 = create(:type, parent: parent_a, position: nil, name: "A2")
        b1 = create(:type, parent: parent_b, position: nil, name: "B1")

        expect([a1.position, a2.position]).to eq([1, 2])
        expect(b1.position).to eq(1)
      end
    end

    describe "validations" do
      it "rejects nesting deeper than one level" do
        grandchild = build(:type, parent: child)

        expect(grandchild).not_to be_valid
      end

      it "rejects a type becoming its own parent" do
        parent.parent = parent

        expect(parent).not_to be_valid
      end

      it "rejects giving a parent to a type that already has children" do
        other_root = create(:type)
        parent.parent = other_root

        expect(parent).not_to be_valid
      end

      it "rejects the standard type having a parent" do
        standard = create(:type_standard)
        standard.parent = parent

        expect(standard).not_to be_valid
      end

      it "allows the same name under different parents" do
        other_parent = create(:type)
        create(:type, parent:, name: "Shared")
        duplicate = build(:type, parent: other_parent, name: "Shared")

        expect(duplicate).to be_valid
      end

      it "rejects a duplicate name under the same parent" do
        create(:type, parent:, name: "Shared")
        duplicate = build(:type, parent:, name: "Shared")

        expect(duplicate).not_to be_valid
      end

      it "freezes parent_id once work packages exist" do
        other_root = create(:type)
        create(:work_package, type: child)

        child.parent = other_root
        expect(child).not_to be_valid
      end

      it "allows editing a type with work packages when the parent is unchanged" do
        create(:work_package, type: child)

        child.name = "Renamed"
        expect(child).to be_valid
      end
    end

    describe "deletion" do
      it "is blocked while children exist" do
        expect(parent.destroy).to be_falsey
        expect(parent).to be_persisted
      end
    end
  end

  describe "core settings and display helpers" do
    let(:color) { create(:color) }
    let!(:parent) do
      create(:type,
             name: "Task",
             color:,
             is_milestone: true,
             is_in_roadmap: false,
             is_default: true)
    end
    let!(:child) do
      create(:type,
             name: "Bug",
             parent:,
             color: nil,
             is_milestone: false,
             is_in_roadmap: true,
             is_default: false)
    end

    describe "#variant?" do
      it "is true for a child and false for a root" do
        expect(child).to be_variant
        expect(parent).not_to be_variant
      end
    end

    describe "display helpers" do
      it "#name returns the root name" do
        expect(child.name).to eq("Task")
        expect(parent.name).to eq("Task")
      end

      it "#own_name returns the type's own stored label" do
        expect(child.own_name).to eq("Bug")
        expect(parent.own_name).to eq("Task")
      end

      it "#color returns the root color" do
        expect(child.color).to eq(color)
        expect(parent.color).to eq(color)
      end

      it "#composite_name prefixes the parent name for a variant" do
        expect(child.composite_name).to eq("Task: Bug")
        expect(parent.composite_name).to eq("Task")
      end
    end

    describe "inherited core settings" do
      it "reads color through to the parent" do
        expect(child.color).to eq(color)
        expect(child.color_id).to eq(color.id)
      end

      it "reads the boolean settings through to the parent, ignoring its own columns" do
        expect(child.is_milestone?).to be(true)
        expect(child.is_in_roadmap?).to be(false)
      end

      it "keeps is_default on the variant itself" do
        expect(child.is_default?).to be(false)
      end

      it "keeps the variant's own name as the variant label" do
        expect(child.own_name).to eq("Bug")
      end

      it "leaves a root's own settings untouched" do
        expect(parent.color).to eq(color)
        expect(parent.is_milestone?).to be(true)
        expect(parent.is_in_roadmap?).to be(false)
        expect(parent.is_default?).to be(true)
      end
    end
  end

  describe "#artefact_export_mode" do
    it "defaults to 'off'" do
      expect(build(:type).artefact_export_mode).to eq(Type::ArtefactExport::OFF)
    end

    it "persists the value into the pdf_export_templates_config jsonb column" do
      persisted = create(:type)
      persisted.update!(artefact_export_mode: Type::ArtefactExport::ATTACHMENT)

      expect(persisted.reload.artefact_export_mode).to eq(Type::ArtefactExport::ATTACHMENT)
      expect(persisted.pdf_export_templates_config).to include("artefact_export_mode" => "attachment")
    end
  end

  describe "#artefact_export_enabled?" do
    it "is false when off" do
      expect(build(:type, pdf_export_templates_config: { "artefact_export_mode" => "off" })).not_to be_artefact_export_enabled
    end

    it "is true when a storing mode is set" do
      expect(build(:type, pdf_export_templates_config: { "artefact_export_mode" => "file_link" })).to be_artefact_export_enabled
    end
  end
end
