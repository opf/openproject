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

RSpec.describe TypeVariant do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }

  let(:aspect) { described_class::DEFAULTS }

  describe "the base variant" do
    it "is created with its type and carries no name" do
      expect(bug.default_variant).to be_present
      expect(bug.default_variant.variant_name).to be_nil
      expect(bug.default_variant).to be_is_default_variant
    end

    it "is the only one a type may have" do
      duplicate = bug.variants.new(is_default_variant: true, variant_name: nil,
                                   workflow: bug.default_variant.workflow)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is named after the type it configures" do
      expect(bug.default_variant.display_name).to eq("Bug")
      expect(bug.default_variant.composite_name).to eq("Bug")
    end
  end

  describe "a named variant" do
    subject(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "is named in its own right, and by its type where both are needed" do
      expect(variant.display_name).to eq("Hardware")
      expect(variant.composite_name).to eq("Bug: Hardware")
    end

    it "takes its identity from the type" do
      expect(variant.name).to eq(bug.name)
      expect(variant.is_milestone).to eq(bug.is_milestone)
    end

    it "requires a name" do
      expect(build(:type_variant, type: bug, variant_name: nil)).not_to be_valid
    end

    it "is unique per type, case-insensitively" do
      variant # the existing "Hardware" it has to collide with

      expect(build(:type_variant, type: bug, variant_name: "hardware")).not_to be_valid
      expect(build(:type_variant, type: task, variant_name: "Hardware")).to be_valid
    end
  end

  describe "resolving an aspect" do
    let(:base) { bug.default_variant }
    let(:leaf) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "is itself while it owns the aspect" do
      expect(leaf.owner_of(aspect)).to eq(leaf)
      expect(leaf).not_to be_linked(aspect)
    end

    it "resolves to its type's base while it inherits the aspect" do
      leaf.link!(aspect)

      expect(leaf).to be_linked(aspect)
      expect(leaf.source_for(aspect)).to eq(base)
      expect(leaf.owner_of(aspect)).to eq(base)
    end
  end

  describe "exclusions" do
    let(:aspect) { TypeVariant::FORM_CONFIGURATION }
    let(:leaf) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "are the variant's own exclusions for an inherited aspect" do
      leaf.link!(aspect)
      leaf.update!(form_configuration_excluded_elements: %w[assignee custom_field_7])

      expect(leaf.excluded_elements(aspect)).to match_array(%w[assignee custom_field_7])
    end

    it "report a repeated element once" do
      leaf.link!(aspect)
      leaf.update!(form_configuration_excluded_elements: %w[assignee assignee])

      expect(leaf.excluded_elements(aspect)).to eq(["assignee"])
    end

    it "are empty for an aspect that cannot be narrowed" do
      leaf.link!(TypeVariant::DEFAULTS)

      expect(leaf.excluded_elements(TypeVariant::DEFAULTS)).to be_empty
    end
  end

  describe "the aspect allowlist" do
    it "accepts every known aspect" do
      described_class::ASPECTS.each do |known|
        expect { described_class.validated_configuration_aspect(known) }.not_to raise_error
      end
    end

    it "refuses anything else" do
      expect { described_class.validated_configuration_aspect("workflows; DROP TABLE types") }
        .to raise_error(ArgumentError)
      expect { described_class.validated_configuration_aspect(:nope) }
        .to raise_error(ArgumentError)
    end
  end

  describe "the excludable aspect allowlist" do
    it "accepts every excludable aspect" do
      described_class::EXCLUDABLE_ASPECTS.each do |excludable|
        expect { described_class.validated_excludable_aspect(excludable) }.not_to raise_error
      end
    end

    it "refuses an aspect that cannot be narrowed" do
      expect { described_class.validated_excludable_aspect(TypeVariant::DEFAULTS) }
        .to raise_error(ArgumentError)
    end

    it "refuses anything else" do
      expect { described_class.validated_excludable_aspect("form_configuration; DROP TABLE types") }
        .to raise_error(ArgumentError)
      expect { described_class.validated_excludable_aspect(:nope) }
        .to raise_error(ArgumentError)
    end
  end

  describe "linked_aspects validation" do
    let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "accepts a known aspect" do
      variant.linked_aspects = [TypeVariant::DEFAULTS]

      expect(variant).to be_valid
    end

    it "rejects an unknown aspect" do
      variant.linked_aspects = ["workflows; DROP TABLE types"]

      expect(variant).not_to be_valid
      expect(variant.errors).to be_added(:linked_aspects, :inclusion)
    end

    it "rejects any linked aspect on the base variant" do
      base = bug.default_variant
      base.linked_aspects = [TypeVariant::DEFAULTS]

      expect(base).not_to be_valid
      expect(base.errors).to be_added(:linked_aspects, :present)
    end
  end

  describe "#work_packages" do
    let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }
    let(:applying) { create(:project, types: [bug]) }
    let(:other) { create(:project, types: [bug]) }

    before { applying.project_types.find_by(type: bug).update!(variant:) }

    it "returns its type's work packages in the projects applying it, and no others" do
      mine = create(:work_package, project: applying, type: bug)
      create(:work_package, project: other, type: bug)      # a project not applying this variant
      create(:work_package, project: applying, type: task)  # applying project, different type

      expect(variant.work_packages).to contain_exactly(mine)
    end
  end

  describe "#migration_targets" do
    let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }
    let(:sibling) { create(:type_variant, type: bug, variant_name: "Firmware") }

    it "offers other variants of the same type, including the base, but not itself" do
      expect(variant.migration_targets).to include(sibling, bug.default_variant)
      expect(variant.migration_targets).not_to include(variant)
    end

    it "does not offer variants of another type" do
      onsite = create(:type_variant, type: task, variant_name: "Onsite")

      expect(variant.migration_targets).not_to include(onsite)
    end

    context "when a single project applies it" do
      let(:project) { create(:project, types: [bug]) }
      let(:owned_here) { create(:type_variant, type: bug, variant_name: "Owned here", project_id: project.id) }
      let(:owned_elsewhere) { create(:type_variant, type: bug, variant_name: "Owned elsewhere", project_id: create(:project).id) }

      before { project.project_types.find_by(type: bug).update!(variant:) }

      it "offers a variant owned by that project but not one owned by another" do
        expect(variant.migration_targets).to include(owned_here)
        expect(variant.migration_targets).not_to include(owned_elsewhere)
      end
    end

    context "when several projects apply it" do
      let(:project_a) { create(:project, types: [bug]) }
      let(:project_b) { create(:project, types: [bug]) }
      let(:owned_by_a) { create(:type_variant, type: bug, variant_name: "Owned by A", project_id: project_a.id) }

      before do
        project_a.project_types.find_by(type: bug).update!(variant:)
        project_b.project_types.find_by(type: bug).update!(variant:)
      end

      it "offers only global variants, none owned by a single applying project" do
        expect(variant.migration_targets).to include(sibling)
        expect(variant.migration_targets).not_to include(owned_by_a)
      end
    end
  end

  describe "the workflow a variant references" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }

    it "may be a global workflow" do
      variant = build(:project_owned_type_variant, type: bug, project:, variant_name: "Internal",
                                                   workflow: create(:named_workflow))

      expect(variant).to be_valid
    end

    it "may not belong to another project" do
      variant = build(:project_owned_type_variant, type: bug, project:, variant_name: "Internal",
                                                   workflow: create(:project_owned_workflow, project: other_project))

      expect(variant).not_to be_valid
      expect(variant.errors).to be_added(:workflow, :not_available_to_this_variant)
    end

    it "may not belong to a project when the variant is global" do
      variant = build(:type_variant, type: bug, variant_name: "Hardware",
                                     workflow: create(:project_owned_workflow, project:))

      expect(variant).not_to be_valid
      expect(variant.errors).to be_added(:workflow, :not_available_to_this_variant)
    end
  end

  describe "destroying a variant" do
    shared_let(:role) { create(:project_role) }
    shared_let(:old_status) { create(:status) }
    shared_let(:new_status) { create(:status) }

    let(:type) { create(:type, name: "Throwaway") }
    let(:variant) { type.default_variant }

    before do
      create(:status_transition, type_variant: variant, role:, old_status:, new_status:)
    end

    it "leaves the workflow behind for an admin to reuse or delete" do
      workflow_id = variant.workflow_id

      type.destroy!

      expect(Workflow.where(id: workflow_id)).to be_present
      expect(Workflows::StatusTransition.where(workflow_id:).count).to eq(1)
    end
  end
end
