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

RSpec.describe CustomFields::Hierarchy::Items::DeleteService, with_ee: %i[custom_field_hierarchies] do
  subject(:result) { described_class.new(user:, model: item).call }

  let(:user) { create(:admin) }
  let(:wp_type) { create(:type_task) }
  let(:custom_field) { create(:hierarchy_wp_custom_field, types: [wp_type]) }
  let(:root) { custom_field.hierarchy_root }
  let!(:luke) { create(:hierarchy_item, parent: root, label: "luke", short: "LS") }
  let!(:mara) { create(:hierarchy_item, parent: luke, label: "mara") }
  let!(:leia) { create(:hierarchy_item, parent: root, label: "leia") }
  let(:item) { luke }

  it "deletes the entire branch" do
    expect(result).to be_success
    expect(CustomField::Hierarchy::Item.where(id: [luke.id, mara.id])).to be_empty
    expect(root.reload.children.to_a).to eq([leia])
  end

  it "does not rebuild the position cache" do
    expect { result }.not_to change { leia.reload.position_cache }
  end

  context "for the root" do
    let(:item) { root }

    it "does not delete the item" do
      expect(result).to be_failure
      expect(root.reload.self_and_descendants.count).to eq(4)
    end
  end

  context "with custom values of the branch" do
    let(:project) { create(:project, types: [wp_type]) }
    let(:work_package) { create(:work_package, project:, type: wp_type) }
    let(:work_package_with_child_value) { create(:work_package, project:, type: wp_type) }
    let(:work_package_with_another_value) { create(:work_package, project:, type: wp_type) }

    before do
      create(:work_package_custom_value, custom_field:, customized: work_package, value: luke.id)
      create(:work_package_custom_value, custom_field:, customized: work_package_with_child_value, value: mara.id)
      create(:work_package_custom_value, custom_field:, customized: work_package_with_another_value, value: leia.id)
    end

    it "removes the custom values of the deleted item" do
      expect(result).to be_success
      expect(work_package.reload.custom_value_for(custom_field).value).to be_nil
    end

    it "removes the custom values of descendants of the deleted item" do
      expect(result).to be_success
      expect(work_package_with_child_value.reload.custom_value_for(custom_field).value).to be_nil
    end

    it "keeps the custom values of unrelated items" do
      expect(result).to be_success
      expect(work_package_with_another_value.reload.custom_value_for(custom_field).value).to eq(leia.id.to_s)
    end
  end

  context "with calculated values depending on the item", with_ee: %i[calculated_values weighted_item_lists] do
    current_user { user }

    let(:projects) { [project_using_one, project_using_two, project_having_fields_enabled] }
    let(:project_using_one) { create(:project) }
    let(:project_using_two) { create(:project) }
    let(:project_having_fields_enabled) { create(:project) }
    let(:custom_field) { create(:weighted_item_list_project_custom_field, projects:) }
    let!(:luke) { create(:hierarchy_item, parent: root, label: "One", weight: 1) }
    let!(:mara) { nil }
    let!(:leia) { create(:hierarchy_item, parent: root, label: "Two", weight: 2) }
    let!(:calculated_value) do
      create(:calculated_value_project_custom_field,
             :skip_validations,
             projects:,
             formula: "{{cf_#{custom_field.id}}} * 2")
    end

    before do
      project_using_one.custom_values.create!(custom_field:, value: luke.id)
      project_using_one.custom_values.create!(custom_field: calculated_value, value: "123")

      project_using_two.custom_values.create!(custom_field:, value: leia.id)
      project_using_two.custom_values.create!(custom_field: calculated_value, value: "123")
    end

    it "updates calculated values affected by the change" do
      expect(result).to be_success
      expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: nil)
    end

    it "doesn't update calculated values unaffected by the change" do
      expect(result).to be_success
      expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
      expect(project_having_fields_enabled.custom_values).to be_empty
    end
  end
end
