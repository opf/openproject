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

require "rails_helper"

RSpec.describe UserCustomFieldSections::DropService do
  let(:admin) { build(:admin) }
  let(:section_a) { create(:user_custom_field_section, position: 1) }
  let(:section_b) { create(:user_custom_field_section, position: 2) }
  let(:section_c) { create(:user_custom_field_section, position: 3) }
  let!(:cf1) { create(:user_custom_field, user_custom_field_section: section_a) }
  let!(:cf2) { create(:user_custom_field, user_custom_field_section: section_a) }
  let!(:cf3) { create(:user_custom_field, user_custom_field_section: section_b) }

  before do
    section_a.update_column(:attribute_order, ["login", cf1.column_name, cf2.column_name])
    section_b.update_column(:attribute_order, ["firstname", cf3.column_name])
  end

  def drop(key, list_id:, prev_id:)
    described_class.new(user: admin, key:).call(list_id:, prev_id:)
  end

  it "reorders a custom field after another custom field" do
    result = drop(cf2.id.to_s, list_id: section_a.id, prev_id: "login")

    expect(result).to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf2.column_name, cf1.column_name])
    expect(result.result[:section_changed]).to be(false)
    expect(result.result[:old_section]).to be_nil
  end

  it "reorders a built-in attribute after a custom field" do
    result = drop("login", list_id: section_a.id, prev_id: cf2.id.to_s)

    expect(result).to be_success
    expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, "login"])
  end

  it "moves a custom field across sections, reparenting it" do
    result = drop(cf1.id.to_s, list_id: section_b.id, prev_id: "firstname")

    expect(result).to be_success
    expect(section_b.reload.attribute_order).to eq(["firstname", cf1.column_name, cf3.column_name])
    expect(section_a.reload.attribute_order).to eq(["login", cf2.column_name])
    expect(cf1.reload.custom_field_section_id).to eq(section_b.id)
    expect(result.result[:section_changed]).to be(true)
    expect(result.result[:current_section]).to eq(section_b)
    expect(result.result[:old_section]).to eq(section_a)
  end

  it "moves a built-in attribute into an empty section with a blank prev_id" do
    result = drop("login", list_id: section_c.id, prev_id: "")

    expect(result).to be_success
    expect(section_c.reload.attribute_order).to eq(["login"])
    expect(section_a.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
  end

  it "takes a custom field's source section from its record, not from the order listing it" do
    UserCustomField.where(id: cf3.id).update_all(custom_field_section_id: section_a.id)

    result = drop(cf3.id.to_s, list_id: section_b.id, prev_id: "")

    expect(result).to be_success
    expect(cf3.reload.custom_field_section_id).to eq(section_b.id)
    expect(section_b.reload.attribute_order).to eq([cf3.column_name, "firstname"])
    expect(result.result[:old_section]).to eq(section_a)
  end

  it "moves a custom field that no section orders yet" do
    section_a.update_column(:attribute_order, ["login", cf2.column_name])

    result = drop(cf1.id.to_s, list_id: section_a.id, prev_id: "login")

    expect(result).to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  it "fails without mutation for a key that is neither a user custom field nor a built-in attribute" do
    foreign_field = create(:project_custom_field)

    ["not_a_real_attribute", "0", "#{cf1.id}abc", foreign_field.id.to_s].each do |key|
      expect(drop(key, list_id: section_a.id, prev_id: "")).not_to be_success
    end
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  it "fails without mutation for a built-in attribute no section orders" do
    expect(drop("mail", list_id: section_a.id, prev_id: "")).not_to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  it "fails without mutation for an anchor from another section" do
    result = drop(cf1.id.to_s, list_id: section_a.id, prev_id: "firstname")

    expect(result).not_to be_success
    expect(result.errors).to eq(I18n.t(:error_invalid_list_move_anchor))
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  it "fails without mutation for a self anchor" do
    expect(drop("login", list_id: section_a.id, prev_id: "login")).not_to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  it "fails without mutation for an unknown list_id" do
    expect(drop(cf1.id.to_s, list_id: 0, prev_id: "")).not_to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name, cf2.column_name])
  end

  context "when user is not admin" do
    let(:admin) { build(:user) }

    it "returns a failure" do
      expect(drop(cf1.id.to_s, list_id: section_a.id, prev_id: "")).not_to be_success
    end
  end
end
