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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeSchemes::SchemeService do
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }
  let(:bug)   { create(:type, name: "Bug") }
  let(:project) { create(:project, types: [epic, story, bug]) }

  def items_for(*types, default: types.first)
    types.each_with_index.map { |t, i| { type_id: t.id, position: i + 1, is_default: t == default } }
  end

  describe ".create" do
    it "creates a valid scheme" do
      result = described_class.create(name: "A", description: "d", items: items_for(epic, story))
      expect(result).to be_success
      expect(result.result.items.map(&:type_id)).to eq([epic.id, story.id])
      expect(result.result.default_type).to eq(epic)
    end

    it "fails when the same type is listed twice" do
      items = items_for(epic, story) + [{ type_id: epic.id, position: 3, is_default: false }]
      result = described_class.create(name: "A", items:)
      expect(result).to be_failure
      expect(result.errors.symbols_for(:items)).to include(:duplicate_types)
      expect(TypeScheme.exists?(name: "A")).to be(false)
    end

    it "fails without a default" do
      result = described_class.create(name: "A", items: items_for(epic, story, default: nil))
      expect(result).to be_failure
      expect(result.errors.symbols_for(:items)).to include(:exactly_one_default)
    end
  end

  describe ".update" do
    let!(:scheme) { create(:type_scheme, types: [epic, story]) }

    it "switches the default to another type" do
      result = described_class.update(scheme, items: items_for(epic, story, default: story))
      expect(result).to be_success
      expect(scheme.reload.default_type).to eq(story)
    end

    it "reorders items" do
      result = described_class.update(scheme, items: [{ type_id: epic.id, position: 2, is_default: true },
                                                      { type_id: story.id, position: 1, is_default: false }])
      expect(result).to be_success
      expect(scheme.reload.types).to eq([story, epic])
    end

    it "removes and adds types, moving the default" do
      result = described_class.update(scheme, items: items_for(story, bug, default: bug))
      expect(result).to be_success
      expect(scheme.reload.types).to eq([story, bug])
      expect(scheme.default_type).to eq(bug)
    end

    it "keeps the old state when invalid" do
      result = described_class.update(scheme, items: items_for(story, bug, default: nil))
      expect(result).to be_failure
      expect(scheme.reload.types).to eq([epic, story])
      expect(scheme.default_type).to eq(epic)
    end

    context "when removing a type used by work packages" do
      let!(:work_package) { create(:work_package, project:, type: story) }

      before { ProjectTypeScheme.create!(project:, scheme:) }

      it "does not change any work package" do
        expect { described_class.update(scheme, items: items_for(epic)) }.not_to change(WorkPackage, :count)
        expect(work_package.reload.type_id).to eq(story.id)
        expect(scheme.reload.types).to eq([epic])
      end
    end
  end

  describe ".clone" do
    let!(:scheme) { create(:type_scheme, types: [epic, story], name: "X") }

    before { ProjectTypeScheme.create!(project:, scheme:) }

    it "copies items under a new name without projects" do
      copy = described_class.clone(scheme).result
      expect(copy).to be_persisted
      expect(copy.name).to eq("X - Custom")
      expect(copy.types).to eq([epic, story])
      expect(copy.default_type).to eq(epic)
      expect(copy.is_default).to be(false)
      expect(copy.project_assignments).to be_empty
    end

    it "picks a free name when the clone name is taken" do
      described_class.clone(scheme)
      expect(described_class.clone(scheme).result.name).to eq("X - Custom 2")
    end
  end

  describe ".deactivate" do
    it "sets active to false" do
      scheme = create(:type_scheme)
      expect(described_class.deactivate(scheme)).to be_success
      expect(scheme.reload.active).to be(false)
    end

    it "refuses to deactivate the default scheme" do
      scheme = create(:type_scheme, is_default: true)
      result = described_class.deactivate(scheme)
      expect(result).to be_failure
      expect(result.errors.symbols_for(:active)).to include(:default_scheme_required)
      expect(scheme.reload).to be_active
    end

    it "moves the projects of a deactivated scheme to the default scheme" do
      default = create(:type_scheme, types: [epic], is_default: true)
      scheme = create(:type_scheme, types: [story])
      ProjectTypeScheme.create!(project:, scheme:)

      described_class.deactivate(scheme)

      expect(ProjectTypeScheme.find_by(project_id: project.id).scheme).to eq default
    end
  end

  describe "schemes cannot be deleted" do
    it "has no destroy service" do
      expect(described_class).not_to respond_to(:destroy)
    end
  end

  describe "default scheme switching" do
    let!(:current) { create(:type_scheme, types: [epic], is_default: true) }
    let!(:other) { create(:type_scheme, types: [story]) }

    it "makes another scheme the default and clears the previous flag" do
      expect(described_class.update(other, is_default: true)).to be_success
      expect(other.reload).to be_is_default
      expect(current.reload).not_to be_is_default
    end

    it "refuses to unset the default flag directly" do
      result = described_class.update(current, is_default: false)
      expect(result).to be_failure
      expect(current.reload).to be_is_default
    end

    it "keeps the previous default when the new one is invalid" do
      other.update_columns(active: false)
      expect(described_class.update(other, is_default: true)).to be_failure
      expect(current.reload).to be_is_default
    end
  end

  describe ".assign" do
    let!(:scheme) { create(:type_scheme, types: [epic]) }
    let!(:other) { create(:type_scheme, types: [story]) }

    it "assigns and reassigns" do
      expect(described_class.assign(project, scheme)).to be_success
      expect(described_class.assign(project, other)).to be_success
      expect(ProjectTypeScheme.where(project_id: project.id).pluck(:scheme_id)).to eq([other.id])
    end

    it "has no unassign" do
      expect(described_class).not_to respond_to(:unassign)
    end

    it "fails for an inactive scheme" do
      scheme.update_columns(active: false)
      expect(described_class.assign(project, scheme)).to be_failure
      expect(ProjectTypeScheme.where(project_id: project.id)).to be_empty
    end
  end

  describe ".impact" do
    let!(:scheme) { create(:type_scheme, types: [epic, story, bug]) }
    let(:other_project) { create(:project, types: [story]) }

    before do
      ProjectTypeScheme.create!(project:, scheme:)
      create_list(:work_package, 2, project:, type: story)
      create(:work_package, project:, type: bug)
      create(:work_package, project: other_project, type: story)
    end

    it "counts projects and work packages of removed types in assigned projects only" do
      expect(described_class.impact(scheme, removed_type_ids: [story.id, bug.id]))
        .to eq(project_count: 1, work_package_counts: { story.id => 2, bug.id => 1 })
    end
  end

  describe ".impact without removed types" do
    it "skips the work package query" do
      scheme = create(:type_scheme, types: [epic])
      ProjectTypeScheme.create!(project:, scheme:)

      expect(described_class.impact(scheme)).to eq(project_count: 1, work_package_counts: {})
    end
  end

  describe ".activate" do
    it "re-enables a deactivated scheme" do
      scheme = create(:type_scheme, types: [epic])
      described_class.deactivate(scheme)

      described_class.activate(scheme)
      expect(scheme.reload).to be_active
    end
  end

  describe ".assign_default" do
    it "assigns the default scheme, creating it from all types when missing" do
      project
      expect(described_class.assign_default(project)).to be_success
      assigned = ProjectTypeScheme.find_by!(project_id: project.id).scheme
      expect(assigned).to be_is_default
    end
  end

  describe "input limits" do
    it "rejects names that are too long" do
      result = described_class.create(name: "x" * 256, items: [{ type_id: epic.id, position: 1, is_default: true }])
      expect(result).to be_failure
    end

    it "rejects out-of-range positions" do
      result = described_class.create(name: "Pos", items: [{ type_id: epic.id, position: 1_000_000, is_default: true }])
      expect(result).to be_failure
    end
  end

  describe "adding new types" do
    let(:admin) { create(:admin) }

    before { User.current = admin }
    after { User.current = nil }

    it "creates a new type and makes it the default when the scheme had none" do
      result = described_class.create(name: "New", new_type_names: ["Sub-Tasks"])

      expect(result).to be_success
      scheme = result.result
      expect(scheme.types.map(&:name)).to eq(["Sub-Tasks"])
      expect(scheme.default_type.name).to eq("Sub-Tasks")
    end

    it "appends new types after the existing items and keeps the default" do
      scheme = create(:type_scheme, types: [epic])

      result = described_class.update(scheme, new_type_names: ["Sub-Tasks"])

      expect(result).to be_success
      expect(scheme.reload.types.map(&:name)).to eq([epic.name, "Sub-Tasks"])
      expect(scheme.default_type).to eq(epic)
    end

    it "reuses an existing type instead of duplicating it" do
      existing = create(:type, name: "Sub-Tasks")

      result = described_class.create(name: "New", new_type_names: ["sub-tasks"])

      expect(result).to be_success
      expect(result.result.types).to eq([existing])
      expect(Type.where("LOWER(name) = ?", "sub-tasks").count).to eq(1)
    end

    it "does not create the type when the scheme is invalid" do
      expect do
        result = described_class.create(name: "", new_type_names: ["Sub-Tasks"])
        expect(result).to be_failure
      end.not_to change(Type, :count)
    end
  end

  describe "per-type colors" do
    let(:color) { create(:color) }

    def item(overrides = {})
      { type_id: epic.id, position: 1, is_default: true }.merge(overrides)
    end

    it "stores a palette color on the item" do
      result = described_class.create(name: "Palette", items: [item(color_id: color.id)])

      expect(result).to be_success
      expect(result.result.items.first.color).to eq(color)
    end

    it "creates a color from a custom hexcode and reuses it case-insensitively" do
      result = described_class.create(name: "Custom",
                                      items: [item(color_mode: "custom", color_hex: "#a1b2c3")])
      expect(result).to be_success

      resolved = Color.find_by("LOWER(hexcode) = ?", "#a1b2c3")
      expect(resolved).to be_present
      expect(result.result.items.first.color).to eq(resolved)

      again = described_class.create(name: "Custom 2",
                                     items: [item(color_mode: "custom", color_hex: "#A1B2C3")])
      expect(again.result.items.first.color).to eq(resolved)
      expect(Color.where("LOWER(hexcode) = ?", "#a1b2c3").count).to eq(1)
    end

    it "keeps the palette color in palette mode even when a hexcode is present" do
      result = described_class.create(name: "Mode",
                                      items: [item(color_mode: "palette", color_id: color.id,
                                                   color_hex: "#a1b2c3")])

      expect(result.result.items.first.color).to eq(color)
    end

    it "ignores an invalid hexcode" do
      result = described_class.create(name: "Invalid hex",
                                      items: [item(color_mode: "custom", color_hex: "nope")])

      expect(result).to be_success
      expect(result.result.items.first.color).to be_nil
    end

    it "clears the color when neither palette nor hex is given" do
      scheme = create(:type_scheme, types: [epic])
      scheme.items.first.update!(color:)

      described_class.update(scheme, items: [item(color_id: nil, color_hex: nil, color_mode: nil)])

      expect(scheme.reload.items.first.color).to be_nil
    end
  end
end
