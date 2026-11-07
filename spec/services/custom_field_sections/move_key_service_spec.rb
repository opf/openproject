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

RSpec.describe CustomFieldSections::MoveKeyService do
  let(:section_a) { create(:user_custom_field_section, position: 1) }
  let(:section_b) { create(:user_custom_field_section, position: 2) }
  let!(:cf1) { create(:user_custom_field, user_custom_field_section: section_a) }

  before do
    section_a.update_column(:attribute_order, ["login", cf1.column_name])
    section_b.update_column(:attribute_order, ["firstname"])
  end

  def move(key, from:, to:, prev_key:, custom_field: nil)
    described_class.new(key:, from:, to:, custom_field:).call(prev_key:)
  end

  it "moves a key without a record within its section" do
    result = move("login", from: section_a, to: section_a, prev_key: cf1.column_name)

    expect(result).to be_success
    expect(section_a.reload.attribute_order).to eq([cf1.column_name, "login"])
    expect(result.result).to eq(section_changed: false, current_section: section_a, old_section: nil)
  end

  it "moves a custom field across sections, reparenting it" do
    result = move(cf1.column_name, from: section_a, to: section_b, prev_key: "firstname", custom_field: cf1)

    expect(result).to be_success
    expect(section_a.reload.attribute_order).to eq(["login"])
    expect(section_b.reload.attribute_order).to eq(["firstname", cf1.column_name])
    expect(cf1.reload.custom_field_section_id).to eq(section_b.id)
    expect(result.result).to eq(section_changed: true, current_section: section_b, old_section: section_a)
  end

  it "fails without mutation when the insert fails after reparenting across sections" do
    allow(section_b).to receive(:insert_after_key).and_return(false)

    result = move(cf1.column_name, from: section_a, to: section_b, prev_key: "firstname", custom_field: cf1)

    expect(result).not_to be_success
    expect(cf1.reload.custom_field_section_id).to eq(section_a.id)
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name])
    expect(section_b.reload.attribute_order).to eq(["firstname"])
  end

  it "fails without mutation when a key without a record left the source section before the lock" do
    stale_section_a = UserCustomFieldSection.find(section_a.id)
    section_a.update_column(:attribute_order, [cf1.column_name])

    result = move("login", from: stale_section_a, to: section_b, prev_key: "")

    expect(result).not_to be_success
    expect(section_a.reload.attribute_order).to eq([cf1.column_name])
    expect(section_b.reload.attribute_order).to eq(["firstname"])
  end

  it "fails without mutation when the custom field was reparented before the lock" do
    UserCustomField.where(id: cf1.id).update_all(custom_field_section_id: section_b.id)

    result = move(cf1.column_name, from: section_a, to: section_b, prev_key: "", custom_field: cf1)

    expect(result).not_to be_success
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name])
    expect(section_b.reload.attribute_order).to eq(["firstname"])
  end

  it "fails without mutation when the custom field no longer passes validation" do
    cf1.update_column(:name, "")

    result = move(cf1.column_name, from: section_a, to: section_b, prev_key: "", custom_field: cf1)

    expect(result).not_to be_success
    expect(result.errors).to be_present
    expect(cf1.reload.custom_field_section_id).to eq(section_a.id)
    expect(section_a.reload.attribute_order).to eq(["login", cf1.column_name])
    expect(section_b.reload.attribute_order).to eq(["firstname"])
  end
end
