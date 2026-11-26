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
require Rails.root.join("db/migrate/20261124120000_repair_custom_field_section_attribute_order.rb")

RSpec.describe RepairCustomFieldSectionAttributeOrder, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:section_a) { create(:project_custom_field_section) }
  let(:section_b) { create(:project_custom_field_section) }
  let!(:field_in_a) { create(:project_custom_field, project_custom_field_section: section_a) }
  let!(:field_in_b) { create(:project_custom_field, project_custom_field_section: section_b) }
  let!(:moved_field) { create(:project_custom_field, project_custom_field_section: section_b) }

  before do
    moved_field.update_column(:custom_field_section_id, section_a.id)
  end

  it "moves the key of a field whose section changed into its current section" do
    migrate

    expect(section_a.reload.attribute_order).to eq([field_in_a.column_name, moved_field.column_name])
    expect(section_b.reload.attribute_order).to eq([field_in_b.column_name])
  end

  it "keeps the built-in attributes and order of user custom field sections" do
    user_section = create(:user_custom_field_section)
    user_field = create(:user_custom_field, user_custom_field_section: user_section)
    user_section.update_column(:attribute_order, ["login", user_field.column_name, "mail"])

    migrate

    expect(user_section.reload.attribute_order).to eq(["login", user_field.column_name, "mail"])
  end

  it "is idempotent" do
    migrate
    migrate

    expect(section_a.reload.attribute_order).to eq([field_in_a.column_name, moved_field.column_name])
    expect(section_b.reload.attribute_order).to eq([field_in_b.column_name])
  end
end
