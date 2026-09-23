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

RSpec.describe WorkPackageTypes::VariantComparison do
  shared_let(:role) { create(:project_role) }
  shared_let(:new_status) { create(:status, name: "New") }
  shared_let(:closed_status) { create(:status, name: "Closed") }
  shared_let(:rejected_status) { create(:status, name: "Rejected") }
  shared_let(:severity) { create(:work_package_custom_field, name: "Severity") }
  shared_let(:project) { create(:project) }

  let(:type) { create(:type, name: "Bug") }
  let(:comparison) { described_class.new(type:) }

  let(:base) do
    type.default_variant.tap do |variant|
      variant.attribute_groups = [["Details", %w[assignee responsible]], ["Extra", [severity.attribute_name]]]
      variant.required_attributes = ["assignee"]
      variant.save!

      create(:status_transition, type_variant: variant, role:, old_status: new_status, new_status: closed_status)
    end
  end

  def profile_for(variant) = comparison.columns.find { it.id == variant.id }

  def inheriting_variant(name)
    create(:type_variant, type:, variant_name: name, workflow: base.workflow).tap do |variant|
      TypeVariant::ASPECTS.each { link_configuration(variant, source: base, aspect: it) }
    end
  end

  before { base }

  describe "#columns" do
    it "leads with the parent type, then names the variants alphabetically" do
      create(:type_variant, type:, variant_name: "Zeta")
      create(:type_variant, type:, variant_name: "Alpha")

      expect(comparison.columns.map { it.variant.display_name }).to eq([type.name, "Alpha", "Zeta"])
    end
  end

  describe "#sections" do
    it "reports the scope first and covers every aspect under the configuration overview" do
      expect(comparison.sections.map(&:first)).to eq(%i[scope configuration form workflows])
      expect(comparison.rows_of(:configuration).map(&:key)).to match_array(TypeVariant::ASPECTS)
    end
  end

  describe "#same_as_type?" do
    it "is false for the parent type itself" do
      expect(comparison).not_to be_same_as_type(profile_for(base))
    end

    it "is true for a variant inheriting every aspect" do
      variant = inheriting_variant("Twin")

      expect(comparison).to be_same_as_type(profile_for(variant))
    end

    it "is false when the workflow resolves differently" do
      variant = inheriting_variant("Almost")
      variant.update!(workflow: create(:named_workflow))

      expect(comparison).not_to be_same_as_type(profile_for(variant))
    end
  end

  describe "the form digest" do
    it "treats the same fields in a different section order as a different form" do
      variant = create(:type_variant, type:, variant_name: "Reordered")
      variant.attribute_groups = [["Extra", [severity.attribute_name]], ["Details", %w[assignee responsible]]]
      variant.required_attributes = ["assignee"]
      variant.save!

      expect(profile_for(variant).fields).to match_array(profile_for(base).fields)
      expect(profile_for(variant).form_digest).not_to eq(profile_for(base).form_digest)
    end

    it "distinguishes variants that require different fields" do
      variant = create(:type_variant, type:, variant_name: "Optional")
      variant.attribute_groups = [["Details", %w[assignee responsible]], ["Extra", [severity.attribute_name]]]
      variant.required_attributes = []
      variant.save!

      expect(profile_for(variant).fields).to match_array(profile_for(base).fields)
      expect(profile_for(variant).form_digest).not_to eq(profile_for(base).form_digest)
    end
  end

  describe "#duplicates_of" do
    it "pairs variants that resolve to the same configuration" do
      first = create(:type_variant, type:, variant_name: "First")
      second = create(:type_variant, type:, variant_name: "Second")

      expect(comparison.duplicates_of(profile_for(first)).map(&:id)).to eq([second.id])
      expect(comparison.duplicates_of(profile_for(second)).map(&:id)).to eq([first.id])
    end

    it "ignores which projects apply a variant" do
      first = create(:type_variant, type:, variant_name: "First")
      second = create(:type_variant, type:, variant_name: "Second")
      create(:project_type, project:, type:, variant: first)

      expect(profile_for(first).project_count).to eq(1)
      expect(comparison.duplicates_of(profile_for(first)).map(&:id)).to eq([second.id])
    end

    it "reports nothing for the parent type" do
      inheriting_variant("Twin")

      expect(comparison.duplicates_of(profile_for(base))).to be_empty
    end

    it "reports nothing for a variant matching the parent type, which is told that instead" do
      inheriting_variant("Twin")
      other = inheriting_variant("Other twin")

      expect(comparison).to be_same_as_type(profile_for(other))
      expect(comparison.duplicates_of(profile_for(other))).to be_empty
    end
  end

  describe "#cell" do
    let(:same_as_base_row) { comparison.rows_of(:form).find { it.key == :same_as_base } }
    let(:fields_row) { comparison.rows_of(:form).find { it.key == :fields } }

    it "leaves the parent type without a verdict on itself" do
      create(:type_variant, type:, variant_name: "Other")

      expect(comparison.cell(profile_for(base), same_as_base_row).same_as_base).to be_nil
    end

    it "reports whether one aspect matches the parent type" do
      twin = inheriting_variant("Twin")
      independent = create(:type_variant, type:, variant_name: "Independent")

      expect(comparison.cell(profile_for(twin), same_as_base_row).same_as_base).to be(true)
      expect(comparison.cell(profile_for(independent), same_as_base_row).same_as_base).to be(false)
    end

    it "counts custom fields among the fields of the form" do
      expect(comparison.cell(profile_for(base), fields_row).count).to eq(3)
    end
  end

  describe "query count" do
    def queries_for(variant_count)
      comparison_type = create(:type)
      variant_count.times { create(:type_variant, type: comparison_type) }

      ActiveRecord::QueryRecorder.new do
        subject = described_class.new(type: comparison_type)
        subject.columns.each { |profile| subject.duplicates_of(profile) }
      end.count
    end

    it "does not grow with the number of variants" do
      expect(queries_for(10)).to eq(queries_for(2))
    end
  end
end
