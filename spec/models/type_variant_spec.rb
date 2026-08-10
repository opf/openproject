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

RSpec.describe TypeVariant, with_flag: { type_variants: true } do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }

  let(:aspect) { described_class::WORKFLOWS }

  describe "the base variant" do
    it "is created with its type and carries no name" do
      expect(bug.default_variant).to be_present
      expect(bug.default_variant.variant_name).to be_nil
      expect(bug.default_variant).to be_is_default_variant
    end

    it "is the only one a type may have" do
      duplicate = bug.variants.new(is_default_variant: true, variant_name: nil)

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
    let(:owner) { task.default_variant }
    let(:middle) { bug.default_variant }
    let(:leaf) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "is itself while it owns the aspect" do
      expect(leaf.effective_source_for(aspect)).to eq(leaf)
      expect(leaf).not_to be_linked(aspect)
    end

    it "walks the chain to the variant that owns it" do
      middle.update!(workflows_source: owner)
      leaf.update!(workflows_source: middle)

      expect(leaf).to be_linked(aspect)
      expect(leaf.effective_source_for(aspect)).to eq(owner)
    end

    it "resolves to itself on a cycle rather than looping" do
      leaf.update!(workflows_source: middle)
      middle.update_columns(workflows_source_id: leaf.id)

      expect(leaf.effective_source_for(aspect)).to eq(leaf)
      expect(leaf.effective_excluded_elements(aspect)).to be_empty
    end
  end

  describe "cycle prevention" do
    let(:one) { bug.default_variant }
    let(:two) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "rejects a variant sourcing itself" do
      one.workflows_source = one

      expect(one).not_to be_valid
    end

    it "rejects a source whose own chain reaches back" do
      two.update!(workflows_source: one)
      one.workflows_source = two

      expect(one).not_to be_valid
      expect(one.errors).to be_of_kind(:workflows_source_id, :would_create_cycle)
    end

    it "rejects a source further along a chain that reaches back" do
      three = create(:type_variant, type: bug, variant_name: "Firmware")
      two.update!(workflows_source: one)
      three.update!(workflows_source: two)
      one.workflows_source = three

      expect(one).not_to be_valid
      expect(one.errors).to be_of_kind(:workflows_source_id, :would_create_cycle)
    end

    it "allows a link that joins a chain without closing it" do
      three = create(:type_variant, type: bug, variant_name: "Firmware")
      two.update!(workflows_source: one)

      expect(three.tap { it.workflows_source = two }).to be_valid
    end

    it "allows the same pair on a different aspect" do
      two.update!(workflows_source: one)
      one.pdf_export_source = two

      expect(one).to be_valid
    end
  end

  describe "exclusions" do
    let(:aspect) { TypeVariant::FORM_CONFIGURATION }
    let(:owner) { task.default_variant }
    let(:middle) { bug.default_variant }
    let(:leaf) { create(:type_variant, type: bug, variant_name: "Hardware") }

    it "accumulate over the whole chain" do
      middle.update!(form_configuration_source: owner, form_configuration_excluded_elements: ["custom_field_7"])
      leaf.update!(form_configuration_source: middle, form_configuration_excluded_elements: ["assignee"])

      expect(leaf.effective_excluded_elements(aspect)).to match_array(%w[assignee custom_field_7])
    end

    it "leave the variant above unaffected" do
      middle.update!(form_configuration_source: owner)
      leaf.update!(form_configuration_source: middle, form_configuration_excluded_elements: ["assignee"])

      expect(middle.effective_excluded_elements(aspect)).to be_empty
    end

    it "report a repeated element once" do
      middle.update!(form_configuration_source: owner, form_configuration_excluded_elements: ["assignee"])
      leaf.update!(form_configuration_source: middle, form_configuration_excluded_elements: ["assignee"])

      expect(leaf.effective_excluded_elements(aspect)).to eq(["assignee"])
    end

    it "are empty for an aspect that cannot be narrowed" do
      middle.update!(workflows_source: owner)

      expect(middle.effective_excluded_elements(TypeVariant::WORKFLOWS)).to be_empty
    end
  end

  describe "the aspect allowlist" do
    it "accepts every known aspect" do
      described_class::ASPECTS.each do |known|
        expect { described_class.effective_source_id_subquery(1, known) }.not_to raise_error
      end
    end

    it "refuses anything else" do
      expect { described_class.effective_source_id_subquery(1, "workflows; DROP TABLE types") }
        .to raise_error(ArgumentError)
      expect { described_class.effective_configuration_lateral("1", :nope) }
        .to raise_error(ArgumentError)
    end
  end
end
