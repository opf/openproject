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

RSpec.describe Projects::CopyService, "with project-specific custom field values" do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:project, types: [type]) }

  let(:target) { service_call.result }

  subject(:service_call) do
    described_class.new(source:, user: admin)
                   .call(target_project_params: { name: "Copy", identifier: "copy" }, only: %w[work_packages])
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }

    before do
      create(:project_specific_value_restriction, project: source, custom_option: option_a)
      create(:work_package, project: source, type:, custom_values: { custom_field.id => option_a.id.to_s })
    end

    it "copies the restrictions" do
      expect(service_call).to be_success
      expect(target.custom_field_value_restrictions.pluck(:custom_field_id, :restriction, :custom_option_id))
        .to contain_exactly([custom_field.id, "allow", option_a.id])
    end

    it "keeps the allowed values of the copied work packages" do
      expect(service_call).to be_success
      expect(target.work_packages.sole.public_send(custom_field.attribute_getter)).to eq("A")
    end

    it "keeps the restrictions of the source project" do
      service_call

      expect(source.custom_field_value_restrictions.pluck(:custom_option_id)).to contain_exactly(option_a.id)
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist, types: [type]) }
    let(:item) { create(:hierarchy_item, parent: custom_field.hierarchy_root) }

    before do
      create(:project_specific_value_restriction, project: source, hierarchy_item: item)
      create(:work_package, project: source, type:, custom_values: { custom_field.id => item.id.to_s })
    end

    it "copies the restrictions and keeps the allowed values of the copied work packages" do
      expect(service_call).to be_success
      expect(target.custom_field_value_restrictions.pluck(:hierarchy_item_id)).to contain_exactly(item.id)
      expect(target.work_packages.sole.public_send(custom_field.attribute_getter)).to eq(item)
    end
  end

  context "for a list custom field with a block filter, without copying the work packages" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_blocklist, types: [type], possible_values: %w[A B])
    end
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }

    subject(:service_call) do
      described_class.new(source:, user: admin)
                     .call(target_project_params: { name: "Copy", identifier: "copy" }, only: [])
    end

    before do
      create(:project_specific_value_restriction, project: source, custom_option: option_b)
    end

    it "copies the restrictions" do
      expect(service_call).to be_success
      expect(target.custom_field_value_restrictions.pluck(:custom_field_id, :restriction, :custom_option_id))
        .to contain_exactly([custom_field.id, "block", option_b.id])
    end
  end

  context "for a list custom field with an option added by the project" do
    let(:custom_field) { create(:list_wp_custom_field, types: [type], possible_values: %w[A]) }
    let!(:own_option) { create(:custom_option, custom_field:, value: "Own", project: source) }
    let(:copied_option) { custom_field.custom_options.find_by(project: target) }

    before do
      create(:work_package, project: source, type:, custom_values: { custom_field.id => own_option.id.to_s })
    end

    it "copies the option into the copy" do
      expect(service_call).to be_success
      expect(copied_option).to have_attributes(value: "Own")
    end

    it "keeps the option of the source project" do
      service_call

      expect(custom_field.custom_options.where(project: source)).to contain_exactly(own_option)
    end

    it "sets the copied work packages to the copied option" do
      expect(service_call).to be_success
      expect(target.work_packages.sole.custom_values.sole.value).to eq(copied_option.id.to_s)
    end

    context "without copying the work packages" do
      subject(:service_call) do
        described_class.new(source:, user: admin)
                       .call(target_project_params: { name: "Copy", identifier: "copy" }, only: [])
      end

      it "copies the option into the copy" do
        expect(service_call).to be_success
        expect(copied_option).to have_attributes(value: "Own")
      end
    end
  end

  context "for a multi-value list custom field with an option added by the project" do
    let(:custom_field) { create(:list_wp_custom_field, types: [type], possible_values: %w[A], multi_value: true) }
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let!(:own_option) { create(:custom_option, custom_field:, value: "Own", project: source) }
    let(:copied_option) { custom_field.custom_options.find_by(project: target) }

    before do
      create(:work_package, project: source, type:,
                            custom_values: { custom_field.id => [option_a.id.to_s, own_option.id.to_s] })
    end

    it "sets the copied work packages to the global option and the copied option" do
      expect(service_call).to be_success
      expect(target.work_packages.sole.custom_values.pluck(:value))
        .to contain_exactly(option_a.id.to_s, copied_option.id.to_s)
    end
  end

  context "for a hierarchy custom field with items added by the project", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, types: [type]) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let!(:own_item) { create(:hierarchy_item, parent: acme, label: "Own", short: "OW", project: source) }
    let!(:own_child) { create(:hierarchy_item, parent: own_item, label: "Own child", project: source) }
    let(:copied_item) { CustomField::Hierarchy::Item.find_by(project: target, label: "Own") }
    let(:copied_child) { CustomField::Hierarchy::Item.find_by(project: target, label: "Own child") }

    before do
      create(:work_package, project: source, type:, custom_values: { custom_field.id => own_child.id.to_s })
    end

    it "copies the items into the copy at the same place in the hierarchy" do
      expect(service_call).to be_success
      expect(copied_item).to have_attributes(parent: acme, short: "OW")
      expect(copied_child).to have_attributes(parent: copied_item)
    end

    it "keeps the items of the source project" do
      service_call

      expect(CustomField::Hierarchy::Item.where(project: source)).to contain_exactly(own_item, own_child)
    end

    it "sets the copied work packages to the copied items" do
      expect(service_call).to be_success
      expect(target.work_packages.sole.public_send(custom_field.attribute_getter))
        .to have_attributes(label: "Own child", project: target)
    end

    context "without copying the work packages" do
      subject(:service_call) do
        described_class.new(source:, user: admin)
                       .call(target_project_params: { name: "Copy", identifier: "copy" }, only: [])
      end

      it "copies the items into the copy at the same place in the hierarchy" do
        expect(service_call).to be_success
        expect(copied_item).to have_attributes(parent: acme, short: "OW")
        expect(copied_child).to have_attributes(parent: copied_item)
      end
    end
  end
end
