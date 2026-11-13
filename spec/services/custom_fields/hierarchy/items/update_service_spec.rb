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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomFields::Hierarchy::Items::UpdateService, with_ee: %i[custom_field_hierarchies] do
  subject(:result) { described_class.new(user:, model: item).call(attributes) }

  let(:user) { create(:admin) }
  let(:custom_field) { create(:wp_custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }
  let!(:luke) { create(:hierarchy_item, parent: root, label: "luke", short: "LS") }
  let!(:mara) { create(:hierarchy_item, parent: luke, label: "mara") }
  let!(:lando) { create(:hierarchy_item, parent: root, label: "lando") }
  let!(:chewbacca) { create(:hierarchy_item, parent: root, label: "AWOOO") }
  let(:preordered_labels) { root.reload.self_and_descendants_preordered.pluck(:label) }

  describe "changing label and short" do
    let(:item) { luke }
    let(:attributes) { { label: "Luke Skywalker", short: "LSW" } }

    it "updates the item" do
      expect(result).to be_success
      expect(luke.reload).to have_attributes(label: "Luke Skywalker", short: "LSW")
    end

    context "with the label of a sibling" do
      let(:attributes) { { label: "lando" } }

      it "does not update the item" do
        expect(result).to be_failure
        expect(luke.reload.label).to eq("luke")
      end
    end
  end

  describe "changing the parent" do
    let(:item) { luke }
    let(:attributes) { { parent: lando } }

    it "moves the item with its descendants" do
      expect(result).to be_success
      expect(luke.reload.ancestors).to contain_exactly(root, lando)
      expect(mara.reload.ancestors).to contain_exactly(root, lando, luke)
    end

    it "rebuilds the position cache" do
      expect(result).to be_success
      expect(root.self_and_descendants.reorder(:position_cache).pluck(:label)).to eq(preordered_labels)
    end

    context "with an existing child of the new parent" do
      let!(:jabba) { create(:hierarchy_item, parent: lando, label: "jabba") }

      it "appends the item to the new parent" do
        expect(result).to be_success
        expect(lando.reload.children.to_a).to eq([jabba, luke])
      end
    end

    context "with project items below the new parent" do
      let(:project) { create(:project) }
      let!(:jedi) { create(:hierarchy_item, parent: lando, label: "jedi", project:) }

      before { custom_field.update!(allow_additional_project_values: true) }

      it "keeps the item before the project items" do
        expect(result).to be_success
        expect(lando.reload.children.to_a).to eq([luke, jedi])
      end
    end
  end

  describe "changing the sort order" do
    let(:item) { chewbacca }
    let(:attributes) { { sort_order: 1 } }

    it "moves the item to that position" do
      expect(result).to be_success
      expect(root.reload.children.to_a).to eq([luke, chewbacca, lando])
    end

    it "rebuilds the position cache" do
      expect(result).to be_success
      expect(root.self_and_descendants.reorder(:position_cache).pluck(:label)).to eq(preordered_labels)
    end

    context "with a string" do
      let(:attributes) { { sort_order: "1" } }

      it "moves the item to that position" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, chewbacca, lando])
      end
    end

    context "to the first position" do
      let(:attributes) { { sort_order: 0 } }

      it "moves the item to the front" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([chewbacca, luke, lando])
      end
    end

    context "to the last position" do
      let(:item) { lando }
      let(:attributes) { { sort_order: 3 } }

      it "moves the item to the end" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, chewbacca, lando])
      end
    end

    context "to a position before the first" do
      let(:item) { lando }
      let(:attributes) { { sort_order: -10 } }

      it "moves the item to the front" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([lando, luke, chewbacca])
      end
    end

    context "to a position after the last" do
      let(:attributes) { { sort_order: 99 } }

      it "keeps the item at the end" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, lando, chewbacca])
      end
    end

    context "to its own position" do
      let(:item) { lando }
      let(:attributes) { { sort_order: lando.sort_order } }

      it "keeps the order" do
        expect(result).to be_success
        expect(root.reload.children.to_a).to eq([luke, lando, chewbacca])
      end
    end
  end

  describe "changing the weight", with_ee: %i[calculated_values weighted_item_lists] do
    current_user { user }

    let(:projects) { [project_using_one, project_using_two, project_having_fields_enabled] }
    let(:project_using_one) { create(:project) }
    let(:project_using_two) { create(:project) }
    let(:project_having_fields_enabled) { create(:project) }
    let(:custom_field) { create(:weighted_item_list_project_custom_field, projects:) }
    let!(:luke) { create(:hierarchy_item, parent: root, label: "One", weight: 1) }
    let!(:mara) { nil }
    let!(:lando) { create(:hierarchy_item, parent: root, label: "Two", weight: 2) }
    let!(:chewbacca) { nil }
    let!(:calculated_value) do
      create(:calculated_value_project_custom_field,
             :skip_validations,
             projects:,
             formula: "{{cf_#{custom_field.id}}} * 2")
    end

    let(:item) { luke }
    let(:attributes) { { weight: 42 } }

    before do
      project_using_one.custom_values.create!(custom_field:, value: luke.id)
      project_using_one.custom_values.create!(custom_field: calculated_value, value: "123")

      project_using_two.custom_values.create!(custom_field:, value: lando.id)
      project_using_two.custom_values.create!(custom_field: calculated_value, value: "123")
    end

    it "updates calculated values affected by the change" do
      expect(result).to be_success
      expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: "84.0")
    end

    it "doesn't update calculated values unaffected by the change" do
      expect(result).to be_success
      expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
      expect(project_having_fields_enabled.custom_values).to be_empty
    end
  end
end
