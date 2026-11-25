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

RSpec.describe Projects::Copy::CustomFieldValuesService do
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:project, types: [type]) }
  shared_let(:target) { create(:project, types: [type]) }

  subject(:service_call) { described_class.new(source:, target:).call }

  context "without restrictions or project values" do
    it "succeeds without copying anything" do
      expect(service_call).to be_success
      expect(service_call.result).to eq({})
      expect(target.custom_field_value_restrictions).to be_empty
    end
  end

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, :project_specific_blocklist, types: [type], possible_values: %w[A B]) }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let!(:own_option) { create(:custom_option, custom_field:, value: "Own", project: source, position: 3) }
    let!(:other_option) { create(:custom_option, custom_field:, value: "Other", project: source, position: 4) }
    let(:copied_options) { custom_field.custom_options.where(project: target) }

    before do
      create(:project_specific_value_restriction, project: source, custom_option: option_b)
    end

    it "copies the restrictions" do
      expect(service_call).to be_success
      expect(target.custom_field_value_restrictions.pluck(:custom_field_id, :restriction, :custom_option_id))
        .to contain_exactly([custom_field.id, "block", option_b.id])
    end

    it "copies the options of the project in their order, after all other options" do
      expect(service_call).to be_success
      expect(custom_field.custom_options.reload.map { [it.value, it.project] })
        .to eq([["A", nil], ["B", nil], ["Own", source], ["Other", source], ["Own", target], ["Other", target]])
    end

    it "maps the options of the project to their copies" do
      expect(service_call.result).to eq(
        custom_field.id => {
          own_option.id.to_s => copied_options.find_by!(value: "Own").id.to_s,
          other_option.id.to_s => copied_options.find_by!(value: "Other").id.to_s
        }
      )
    end

    it "keeps the restrictions and options of the source project" do
      service_call

      expect(source.custom_field_value_restrictions.pluck(:custom_option_id)).to contain_exactly(option_b.id)
      expect(custom_field.custom_options.where(project: source)).to contain_exactly(own_option, other_option)
    end

    context "with an option that cannot be copied" do
      before { own_option.update_column(:value, "") }

      it "fails with the errors of the option" do
        expect(service_call).to be_failure
        expect(service_call.errors.details[:value]).to include(error: :blank)
      end
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist, types: [type]) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let!(:own_item) { create(:hierarchy_item, parent: acme, label: "Own", short: "OW", project: source) }
    let!(:own_child) { create(:hierarchy_item, parent: own_item, label: "Own child", project: source) }
    let(:copied_item) { CustomField::Hierarchy::Item.find_by!(project: target, label: "Own") }
    let(:copied_child) { CustomField::Hierarchy::Item.find_by!(project: target, label: "Own child") }

    before do
      create(:project_specific_value_restriction, project: source, hierarchy_item: acme)
    end

    it "copies the restrictions" do
      expect(service_call).to be_success
      expect(target.custom_field_value_restrictions.pluck(:custom_field_id, :restriction, :hierarchy_item_id))
        .to contain_exactly([custom_field.id, "allow", acme.id])
    end

    it "copies the items of the project below the global parent and their copied parent" do
      expect(service_call).to be_success
      expect(copied_item).to have_attributes(parent: acme, short: "OW")
      expect(copied_child).to have_attributes(parent: copied_item)
    end

    it "places the copies in the position cache after the items of the source project" do
      service_call

      expect(custom_field.hierarchy_root.descendants.reorder(:position_cache))
        .to eq([acme, own_item, own_child, copied_item, copied_child])
    end

    it "maps the items of the project to their copies" do
      expect(service_call.result).to eq(
        custom_field.id => {
          own_item.id.to_s => copied_item.id.to_s,
          own_child.id.to_s => copied_child.id.to_s
        }
      )
    end

    it "keeps the items of the source project" do
      service_call

      expect(CustomField::Hierarchy::Item.where(project: source)).to contain_exactly(own_item, own_child)
    end
  end
end
