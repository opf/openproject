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
require Rails.root.join("db/migrate/20260922172230_migrate_list_custom_fields_to_hierarchy_items")

RSpec.describe MigrateListCustomFieldsToHierarchyItems, type: :model do
  let(:conn) { ActiveRecord::Base.connection }

  # All setup uses raw SQL because custom_options no longer exists once the
  # migration has run against the test database.

  def insert_list_cf(name)
    conn.select_value(<<~SQL.squish)
      INSERT INTO custom_fields (type, name, field_format, is_required, is_for_all, searchable,
                                 editable, admin_only, multi_value, created_at, updated_at)
      VALUES ('WorkPackageCustomField', '#{name}', 'list', false, false, false, true, false, false, NOW(), NOW())
      RETURNING id
    SQL
  end

  def insert_option(cf_id, value, position, default_value: false)
    conn.select_value(<<~SQL.squish)
      INSERT INTO custom_options (custom_field_id, value, position, default_value, created_at, updated_at)
      VALUES (#{cf_id}, '#{value}', #{position.nil? ? 'NULL' : position}, #{default_value}, NOW(), NOW())
      RETURNING id
    SQL
  end

  def items_of(cf_id)
    conn.select_all(<<~SQL.squish).to_a
      SELECT i.id, i.label, i.sort_order, i.default_value, i.position_cache
      FROM hierarchical_items i
      JOIN hierarchical_items root ON root.id = i.parent_id
      WHERE root.custom_field_id = #{cf_id}
      ORDER BY i.sort_order
    SQL
  end

  def mapped_item_id(option_id)
    conn.select_value("SELECT hierarchical_item_id FROM legacy_custom_option_mappings WHERE custom_option_id = #{option_id}")
  end

  def migrate!
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
  end

  # Puts the schema back into the pre-migration state: custom_options present.
  before do
    ActiveRecord::Migration.suppress_messages do
      unless conn.table_exists?(:custom_options)
        conn.create_table :custom_options do |t|
          t.bigint :custom_field_id
          t.integer :position
          t.boolean :default_value
          t.text :value
          t.timestamps null: true
        end
      end
    end
  end

  after do
    ActiveRecord::Migration.suppress_messages do
      conn.drop_table :custom_options, if_exists: true
    end

    # setval survives the example's transaction rollback while the rows it
    # numbered do not, so the sequence has to be pushed back past what is left.
    conn.execute(<<~SQL.squish)
      SELECT setval('hierarchical_items_id_seq',
                    GREATEST((SELECT COALESCE(MAX(id), 0) FROM hierarchical_items), 1))
    SQL
  end

  describe "up" do
    it "creates one item per option, in position order, tolerating gaps and nulls" do
      cf = insert_list_cf("Ordered")
      insert_option(cf, "third", 30)
      insert_option(cf, "first", 10)
      insert_option(cf, "last", nil)

      migrate!

      expect(items_of(cf).pluck("label")).to eq(%w[first third last])
      expect(items_of(cf).pluck("sort_order")).to eq([0, 1, 2])
    end

    it "hangs the items off a single root owned by the custom field" do
      cf = insert_list_cf("Rooted")
      insert_option(cf, "only", 1)

      migrate!

      roots = conn.select_all(<<~SQL.squish).to_a
        SELECT id, children_count FROM hierarchical_items WHERE custom_field_id = #{cf} AND parent_id IS NULL
      SQL
      expect(roots.size).to eq(1)
      expect(roots.first["children_count"]).to eq(1)
    end

    it "gives every item the closure rows its parent lookups rely on" do
      cf = insert_list_cf("Closure")
      insert_option(cf, "only", 1)

      migrate!

      root_id = conn.select_value("SELECT id FROM hierarchical_items WHERE custom_field_id = #{cf}")
      item_id = items_of(cf).first["id"]
      rows = conn.select_all(<<~SQL.squish).to_a
        SELECT ancestor_id, descendant_id, generations
        FROM hierarchical_item_hierarchies
        WHERE descendant_id IN (#{root_id}, #{item_id})
        ORDER BY generations
      SQL

      expect(rows).to contain_exactly(
        { "ancestor_id" => root_id, "descendant_id" => root_id, "generations" => 0 },
        { "ancestor_id" => item_id, "descendant_id" => item_id, "generations" => 0 },
        { "ancestor_id" => root_id, "descendant_id" => item_id, "generations" => 1 }
      )
    end

    it "fills the position cache used to order items" do
      cf = insert_list_cf("Positions")
      insert_option(cf, "a", 1)
      insert_option(cf, "b", 2)

      migrate!

      caches = items_of(cf).pluck("position_cache")
      expect(caches).to all(be_present)
    end

    it "suffixes duplicate values, leaving the first occurrence bare" do
      cf = insert_list_cf("Dupes")
      insert_option(cf, "Same", 1)
      insert_option(cf, "Same", 2)
      insert_option(cf, "Same", 3)

      migrate!

      expect(items_of(cf).pluck("label")).to eq(["Same", "Same (2)", "Same (3)"])
    end

    it "carries the default flag, including several on a multi value field" do
      cf = insert_list_cf("Defaults")
      insert_option(cf, "a", 1, default_value: true)
      insert_option(cf, "b", 2, default_value: true)
      conn.execute("UPDATE custom_fields SET multi_value = true WHERE id = #{cf}")

      migrate!

      expect(items_of(cf).pluck("default_value")).to eq([true, true])
    end

    it "leaves non list custom fields alone" do
      cf = insert_list_cf("Text")
      conn.execute("UPDATE custom_fields SET field_format = 'string' WHERE id = #{cf}")
      insert_option(cf, "orphan", 1)

      migrate!

      expect(conn.select_value("SELECT COUNT(*) FROM hierarchical_items WHERE custom_field_id = #{cf}")).to eq(0)
    end

    it "rewrites custom values onto the new item ids" do
      cf = insert_list_cf("Values")
      option_id = insert_option(cf, "picked", 1)
      wp = create(:work_package)
      conn.execute(<<~SQL.squish)
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage', #{wp.id}, #{cf}, '#{option_id}')
      SQL

      migrate!

      value = conn.select_value("SELECT value FROM custom_values WHERE custom_field_id = #{cf}")
      expect(value).to eq(mapped_item_id(option_id).to_s)
    end

    it "rewrites journal entries onto the new item ids" do
      cf = insert_list_cf("Journals")
      option_id = insert_option(cf, "picked", 1)
      wp = create(:work_package)
      journal_id = conn.select_value(<<~SQL.squish)
        SELECT id FROM journals WHERE journable_type = 'WorkPackage' AND journable_id = #{wp.id} LIMIT 1
      SQL
      conn.execute(<<~SQL.squish)
        INSERT INTO customizable_journals (journal_id, custom_field_id, value)
        VALUES (#{journal_id}, #{cf}, '#{option_id}')
      SQL

      migrate!

      value = conn.select_value("SELECT value FROM customizable_journals WHERE custom_field_id = #{cf}")
      expect(value).to eq(mapped_item_id(option_id).to_s)
    end

    it "leaves legacy ids and new item ids disjoint even when the sequence lags behind" do
      cf = insert_list_cf("Collision")
      conn.execute("SELECT setval('custom_options_id_seq', 5000)")
      lagging = conn.select_value(<<~SQL.squish)
        SELECT setval('hierarchical_items_id_seq',
                      GREATEST((SELECT COALESCE(MAX(id), 0) FROM hierarchical_items), 1))
      SQL
      high_option = insert_option(cf, "only", 1)
      # The premise of the example: left alone, the next item would be numbered
      # below the option id it must never be confused with.
      expect(lagging).to be < high_option

      migrate!

      new_ids = conn.select_values(<<~SQL.squish)
        SELECT id FROM hierarchical_items
        WHERE custom_field_id = #{cf} OR parent_id IN (SELECT id FROM hierarchical_items WHERE custom_field_id = #{cf})
      SQL
      expect(new_ids).to all(be > high_option)
    end

    it "drops custom_options" do
      migrate!

      expect(conn.table_exists?(:custom_options)).to be(false)
    end

    it "keeps new item ids above the highest option id ever issued, even if that option was later deleted" do
      cf = insert_list_cf("Watermark")
      insert_option(cf, "kept", 1)
      conn.execute("SELECT setval('custom_options_id_seq', 500000)")
      deleted_id = insert_option(cf, "gone", 2)
      conn.execute("DELETE FROM custom_options WHERE id = #{deleted_id}")

      migrate!

      new_ids = conn.select_values(<<~SQL.squish)
        SELECT id FROM hierarchical_items
        WHERE custom_field_id = #{cf} OR parent_id IN (SELECT id FROM hierarchical_items WHERE custom_field_id = #{cf})
      SQL
      expect(new_ids).to all(be > deleted_id)
    end

    it "keeps new item ids above the highest item id ever issued, even if that item was later deleted" do
      cf = insert_list_cf("Item watermark")
      insert_option(cf, "kept", 1)
      conn.execute("SELECT setval('hierarchical_items_id_seq', 700000)")
      deleted_id = conn.select_value("INSERT INTO hierarchical_items (created_at, updated_at) VALUES (NOW(), NOW()) RETURNING id")
      conn.execute("DELETE FROM hierarchical_items WHERE id = #{deleted_id}")

      migrate!

      new_ids = conn.select_values(<<~SQL.squish)
        SELECT id FROM hierarchical_items
        WHERE custom_field_id = #{cf} OR parent_id IN (SELECT id FROM hierarchical_items WHERE custom_field_id = #{cf})
      SQL
      expect(new_ids).to all(be > deleted_id)
    end

    it "does not rewrite a value that matches another field's option id" do
      cf_a = insert_list_cf("FieldA")
      cf_b = insert_list_cf("FieldB")
      insert_option(cf_a, "a-value", 1)
      option_b = insert_option(cf_b, "b-value", 1)
      wp = create(:work_package)
      conn.execute(<<~SQL.squish)
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage', #{wp.id}, #{cf_a}, '#{option_b}')
      SQL

      migrate!

      value = conn.select_value("SELECT value FROM custom_values WHERE custom_field_id = #{cf_a}")
      expect(value).to eq(option_b.to_s)
    end
  end

  describe "#assert_ids_disjoint!" do
    it "raises when a legacy option id collides with a migrated item id of the same field" do
      cf = insert_list_cf("Overlap")
      root_id = conn.select_value(<<~SQL.squish)
        INSERT INTO hierarchical_items (custom_field_id, children_count, created_at, updated_at)
        VALUES (#{cf}, 1, NOW(), NOW())
        RETURNING id
      SQL
      item_id = conn.select_value(<<~SQL.squish)
        INSERT INTO hierarchical_items (parent_id, sort_order, label, children_count, created_at, updated_at)
        VALUES (#{root_id}, 0, 'colliding', 0, NOW(), NOW())
        RETURNING id
      SQL
      conn.execute(<<~SQL.squish)
        INSERT INTO legacy_custom_option_mappings (custom_option_id, hierarchical_item_id, custom_field_id)
        VALUES (#{item_id}, #{item_id}, #{cf})
      SQL

      migration = described_class.new
      expect { migration.send(:assert_ids_disjoint!) }
        .to raise_error(ActiveRecord::MigrationError, /collide/)
    end
  end

  describe "down" do
    it "restores options with their original ids and current labels" do
      cf = insert_list_cf("Reverse")
      option_id = insert_option(cf, "Same", 1)
      insert_option(cf, "Same", 2)
      migrate!

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      values = conn.select_all("SELECT id, value FROM custom_options WHERE custom_field_id = #{cf} ORDER BY position").to_a
      expect(values.first["id"]).to eq(option_id)
      # Documented loss: the suffix applied on the way up is not undone.
      expect(values.pluck("value")).to eq(["Same", "Same (2)"])
    end

    it "points custom values back at the option ids" do
      cf = insert_list_cf("ReverseValues")
      option_id = insert_option(cf, "picked", 1)
      wp = create(:work_package)
      conn.execute(<<~SQL.squish)
        INSERT INTO custom_values (customized_type, customized_id, custom_field_id, value)
        VALUES ('WorkPackage', #{wp.id}, #{cf}, '#{option_id}')
      SQL
      migrate!

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(conn.select_value("SELECT value FROM custom_values WHERE custom_field_id = #{cf}")).to eq(option_id.to_s)
    end

    it "gives items added after the migration a fresh option id" do
      cf = insert_list_cf("Latecomer")
      option_id = insert_option(cf, "original", 1)
      migrate!
      root_id = conn.select_value("SELECT id FROM hierarchical_items WHERE custom_field_id = #{cf}")
      conn.execute(<<~SQL.squish)
        INSERT INTO hierarchical_items (parent_id, sort_order, label, children_count, created_at, updated_at)
        VALUES (#{root_id}, 1, 'added later', 0, NOW(), NOW())
      SQL

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      values = conn.select_all("SELECT id, value FROM custom_options WHERE custom_field_id = #{cf} ORDER BY position").to_a
      expect(values.pluck("value")).to eq(["original", "added later"])
      expect(values.last["id"]).to be > option_id
    end

    it "clears the hierarchy it built" do
      cf = insert_list_cf("Cleared")
      insert_option(cf, "only", 1)
      migrate!

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(conn.select_value("SELECT COUNT(*) FROM hierarchical_items WHERE custom_field_id = #{cf}")).to eq(0)
      expect(conn.select_value("SELECT COUNT(*) FROM legacy_custom_option_mappings WHERE custom_field_id = #{cf}")).to eq(0)
    end
  end
end
