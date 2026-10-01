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

require "rails_helper"

RSpec.describe CustomFields::DropService do
  let(:admin) { build(:admin) }

  shared_examples "drops fields within and across sections" do |cf_factory:, section_factory:, section_assoc:|
    let(:section_a) { create(section_factory, position: 1) }
    let(:section_b) { create(section_factory, position: 2) }
    let!(:cf1) { create(cf_factory, section_assoc => section_a) }
    let!(:cf2) { create(cf_factory, section_assoc => section_a) }

    subject(:service) { described_class.new(user: admin, custom_field: cf2) }

    describe "reordering within the same section" do
      it "moves to the target position" do
        result = service.call(target_id: section_a.id, position: 1)
        expect(result).to be_success
        expect(section_a.reload.attribute_order).to eq([cf2.column_name, cf1.column_name])
      end

      it "reports section_changed as false" do
        result = service.call(target_id: section_a.id, position: 1)
        expect(result.result[:section_changed]).to be(false)
      end
    end

    describe "moving to a different section" do
      it "removes the field from the source section" do
        service.call(target_id: section_b.id, position: 1)
        expect(section_a.reload.attribute_order).not_to include(cf2.column_name)
      end

      it "inserts the field at the target position in the new section" do
        service.call(target_id: section_b.id, position: 1)
        expect(section_b.reload.attribute_order.first).to eq(cf2.column_name)
      end

      it "updates the custom field's section" do
        service.call(target_id: section_b.id, position: 1)
        expect(cf2.reload.custom_field_section_id).to eq(section_b.id)
      end

      it "reports section_changed as true with both sections" do
        result = service.call(target_id: section_b.id, position: 1)
        expect(result.result[:section_changed]).to be(true)
        expect(result.result[:current_section]).to eq(section_b)
        expect(result.result[:old_section]).to eq(section_a)
      end
    end

    context "when user is not admin" do
      let(:admin) { build(:user) }

      it "returns a failure" do
        expect(service.call(target_id: section_a.id, position: 1)).not_to be_success
      end
    end
  end

  describe "with UserCustomField" do
    include_examples "drops fields within and across sections",
                     cf_factory: :user_custom_field,
                     section_factory: :user_custom_field_section,
                     section_assoc: :user_custom_field_section
  end

  describe "with ProjectCustomField" do
    include_examples "drops fields within and across sections",
                     cf_factory: :project_custom_field,
                     section_factory: :project_custom_field_section,
                     section_assoc: :project_custom_field_section
  end

  describe "anchor wire (list_id/prev_id)" do
    let(:section_a) { create(:project_custom_field_section, position: 1) }
    let(:section_b) { create(:project_custom_field_section, position: 2) }
    let(:section_c) { create(:project_custom_field_section, position: 3) }
    let!(:cf1) { create(:project_custom_field, project_custom_field_section: section_a) }
    let!(:cf2) { create(:project_custom_field, project_custom_field_section: section_a) }
    let!(:cf3) { create(:project_custom_field, project_custom_field_section: section_a) }
    let!(:cf4) { create(:project_custom_field, project_custom_field_section: section_b) }

    subject(:service) { described_class.new(user: admin, custom_field: cf3) }

    it "reorders within the section after the anchor field" do
      result = service.call(list_id: section_a.id, prev_id: cf1.id)

      expect(result).to be_success
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf3.column_name, cf2.column_name])
      expect(result.result[:section_changed]).to be(false)
      expect(result.result[:old_section]).to be_nil
    end

    it "moves to the top of the section for a blank prev_id" do
      result = service.call(list_id: section_a.id, prev_id: "")

      expect(result).to be_success
      expect(section_a.reload.attribute_order).to eq([cf3.column_name, cf1.column_name, cf2.column_name])
    end

    it "moves across sections after the target-section anchor, transactionally" do
      service_for_cf2 = described_class.new(user: admin, custom_field: cf2)
      result = service_for_cf2.call(list_id: section_b.id, prev_id: cf4.id)

      expect(result).to be_success
      expect(section_b.reload.attribute_order).to eq([cf4.column_name, cf2.column_name])
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf3.column_name])
      expect(cf2.reload.custom_field_section_id).to eq(section_b.id)
      expect(result.result[:section_changed]).to be(true)
      expect(result.result[:current_section]).to eq(section_b)
      expect(result.result[:old_section]).to eq(section_a)
    end

    it "fails without mutation when the insert fails after reparenting across sections" do
      service_for_cf2 = described_class.new(user: admin, custom_field: cf2)

      # Instance stub (not allow_any_instance_of): force the post-reparent
      # insert to fail so the rollback guard's un-reachable-in-practice
      # branch (remove_from_order + update! already applied, then
      # insert_after_key false) is actually exercised.
      allow(ProjectCustomFieldSection).to receive(:find_by).with(id: section_b.id).and_return(section_b)
      allow(section_b).to receive(:insert_after_key).and_return(false)

      result = service_for_cf2.call(list_id: section_b.id, prev_id: cf4.id)

      expect(result).not_to be_success
      expect(cf2.reload.custom_field_section_id).to eq(section_a.id)
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(section_b.reload.attribute_order).to eq([cf4.column_name])
    end

    it "moves into an empty section with a blank prev_id" do
      result = service.call(list_id: section_c.id, prev_id: "")

      expect(result).to be_success
      expect(section_c.reload.attribute_order).to eq([cf3.column_name])
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_c.id)
    end

    it "fails without mutation for an unknown prev_id" do
      result = service.call(list_id: section_a.id, prev_id: 0)

      expect(result).not_to be_success
      expect(result.errors).to eq(I18n.t(:error_invalid_list_move_anchor))
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "fails without mutation for a prev_id from another section" do
      result = service.call(list_id: section_a.id, prev_id: cf4.id)

      expect(result).not_to be_success
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(section_b.reload.attribute_order).to eq([cf4.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "fails without mutation for a self prev_id" do
      result = service.call(list_id: section_a.id, prev_id: cf3.id)

      expect(result).not_to be_success
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end

    it "fails without mutation for an unknown list_id" do
      result = service.call(list_id: 0, prev_id: cf1.id)

      expect(result).not_to be_success
      expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
      expect(cf3.reload.custom_field_section_id).to eq(section_a.id)
    end
  end
end
