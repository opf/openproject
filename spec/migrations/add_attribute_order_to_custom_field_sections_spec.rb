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
require Rails.root.join("db/migrate/20260604120001_add_attribute_order_to_custom_field_sections")

RSpec.describe AddAttributeOrderToCustomFieldSections, type: :model do
  let(:conn) { ActiveRecord::Base.connection }

  # All setup uses raw SQL because attribute_order does not exist during up tests.

  def insert_section(type:, position:)
    conn.select_value(<<~SQL.squish)
      INSERT INTO custom_field_sections (type, name, position, display_representation, created_at, updated_at)
      VALUES ('#{type}', '#{type} #{position}', #{position}, '{}', NOW(), NOW())
      RETURNING id
    SQL
  end

  def insert_cf(section_id:, position:)
    conn.select_value(<<~SQL.squish)
      INSERT INTO custom_fields
        (type, name, field_format, custom_field_section_id, position_in_custom_field_section,
         is_required, is_for_all, searchable, editable, admin_only, multi_value,
         created_at, updated_at)
      VALUES
        ('UserCustomField', 'CF #{position}', 'string', #{section_id}, #{position},
         false, false, false, true, false, false,
         NOW(), NOW())
      RETURNING id
    SQL
  end

  def attribute_order_of(section_id)
    conn.select_value("SELECT attribute_order FROM custom_field_sections WHERE id = #{section_id}")
  end

  # Before each example the schema is put in the pre-migration state:
  # attribute_order removed, position_in_custom_field_section added.
  before do
    ActiveRecord::Migration.suppress_messages do
      conn.add_column :custom_fields, :position_in_custom_field_section, :integer unless
        conn.column_exists?(:custom_fields, :position_in_custom_field_section)
      conn.remove_column :custom_field_sections, :attribute_order if
        conn.column_exists?(:custom_field_sections, :attribute_order)
    end
  end

  after do
    ActiveRecord::Migration.suppress_messages do
      unless conn.column_exists?(:custom_field_sections, :attribute_order)
        conn.add_column :custom_field_sections, :attribute_order, :string, array: true, null: false, default: []
      end
      conn.remove_column :custom_fields, :position_in_custom_field_section if
        conn.column_exists?(:custom_fields, :position_in_custom_field_section)
    end

    # The raw add/remove above changes columns without refreshing ActiveRecord's
    # cached column lists, leaving the models out of sync with the restored
    # schema. Reset them so later specs build SQL against the real columns.
    [CustomField, CustomFieldSection].each(&:reset_column_information)
  end

  describe "up migration" do
    it "seeds attribute_order for UserCustomFieldSection from position_in_custom_field_section" do
      section_id = insert_section(type: "UserCustomFieldSection", position: 1)
      cf1_id = insert_cf(section_id:, position: 1)
      cf2_id = insert_cf(section_id:, position: 2)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      order = conn.select_value("SELECT attribute_order::text FROM custom_field_sections WHERE id = #{section_id}")
      expect(order).to include("cf_#{cf1_id}", "cf_#{cf2_id}")
      expect(order.index("cf_#{cf1_id}")).to be < order.index("cf_#{cf2_id}")
    end

    it "prepends built-in attributes to the first UserCustomFieldSection only" do
      first_id  = insert_section(type: "UserCustomFieldSection", position: 1)
      second_id = insert_section(type: "UserCustomFieldSection", position: 2)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      first_order  = conn.select_value("SELECT attribute_order::text FROM custom_field_sections WHERE id = #{first_id}")
      second_order = conn.select_value("SELECT attribute_order::text FROM custom_field_sections WHERE id = #{second_id}")

      expect(first_order).to include("login", "firstname", "lastname", "mail", "language")
      expect(second_order).not_to include("login")
    end

    it "does not seed attribute_order for ProjectCustomFieldSection" do
      section_id = insert_section(type: "ProjectCustomFieldSection", position: 1)
      insert_cf(section_id:, position: 1)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      order = conn.select_value("SELECT attribute_order::text FROM custom_field_sections WHERE id = #{section_id}")
      expect(order).to eq("{}")
    end

    it "sets attribute_order to built-ins only for a UserCustomFieldSection with no custom fields" do
      section_id = insert_section(type: "UserCustomFieldSection", position: 1)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      order = conn.select_value("SELECT attribute_order::text FROM custom_field_sections WHERE id = #{section_id}")
      expect(order).to include("login")
    end
  end

  describe "down migration" do
    before do
      # Put schema back to post-migration-1 state for the down test.
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
    end

    it "restores position_in_custom_field_section for user CFs from attribute_order" do
      section = UserCustomFieldSection.create!(name: "S")
      cf1 = create(:user_custom_field, user_custom_field_section: section)
      cf2 = create(:user_custom_field, user_custom_field_section: section)
      section.update_column(:attribute_order, [cf2.column_name, cf1.column_name])

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(conn.select_value("SELECT position_in_custom_field_section FROM custom_fields WHERE id = #{cf2.id}").to_i).to eq(1)
      expect(conn.select_value("SELECT position_in_custom_field_section FROM custom_fields WHERE id = #{cf1.id}").to_i).to eq(2)
    end

    it "removes the attribute_order column" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(conn.column_exists?(:custom_field_sections, :attribute_order)).to be false
    end
  end
end
