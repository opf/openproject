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
  end

  describe ".deactivate" do
    it "sets active to false" do
      scheme = create(:type_scheme)
      expect(described_class.deactivate(scheme)).to be_success
      expect(scheme.reload.active).to be(false)
    end
  end

  describe ".destroy" do
    let!(:scheme) { create(:type_scheme, types: [epic]) }

    it "destroys an unassigned scheme" do
      expect(described_class.destroy(scheme)).to be_success
      expect(TypeScheme.exists?(scheme.id)).to be(false)
    end

    it "fails and lists project names when assigned" do
      ProjectTypeScheme.create!(project:, scheme:)
      result = described_class.destroy(scheme)
      expect(result).to be_failure
      expect(result.errors.symbols_for(:project_assignments)).to include(:assigned_to_projects)
      expect(result.errors.full_messages.join).to include(project.name)
      expect(TypeScheme.exists?(scheme.id)).to be(true)
    end
  end

  describe ".assign / .unassign" do
    let!(:scheme) { create(:type_scheme, types: [epic]) }
    let!(:other) { create(:type_scheme, types: [story]) }

    it "assigns, reassigns and unassigns" do
      expect(described_class.assign(project, scheme)).to be_success
      expect(described_class.assign(project, other)).to be_success
      expect(ProjectTypeScheme.where(project_id: project.id).pluck(:scheme_id)).to eq([other.id])
      expect(described_class.unassign(project)).to be_success
      expect(ProjectTypeScheme.where(project_id: project.id)).to be_empty
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
end
