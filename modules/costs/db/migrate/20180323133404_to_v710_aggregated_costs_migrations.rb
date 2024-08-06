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

require Rails.root.join("db/migrate/migration_utils/migration_squasher").to_s
# This migration aggregates the migrations detailed in MIGRATION_FILES
class ToV710AggregatedCostsMigrations < ActiveRecord::Migration[5.1]
  MIGRATION_FILES = <<-MIGRATIONS
    20121022124254_aggregated_costs_migrations.rb
    20130529145329_remove_signoff_from_cost_objects.rb
    20130625094710_add_costs_column_to_work_package.rb
    20130916094369_legacy_issues_costs_data_to_work_packages.rb
    20130918084158_add_cost_object_journals.rb
    20130918084919_add_cost_object_id_to_work_package_journals.rb
    20130918160542_add_journal_columns_to_time_entry_journals.rb
    20130918180542_legacy_variable_cost_object_journal_data.rb
    20160504070128_add_index_for_latest_cost_activity.rb
  MIGRATIONS

  def up
    Migration::MigrationSquasher.squash(migrations) do
      create_table "cost_entries", id: :integer do |t|
        t.integer "user_id",                                                            null: false
        t.integer "project_id",                                                         null: false
        t.integer "work_package_id",                                                    null: false
        t.integer "cost_type_id",                                                       null: false
        t.float "units", null: false
        t.date "spent_on", null: false
        t.datetime "created_on",                                                         null: false
        t.datetime "updated_on",                                                         null: false
        t.string "comments", null: false
        t.boolean "blocked", default: false, null: false
        t.decimal "overridden_costs", precision: 15, scale: 4
        t.decimal "costs",            precision: 15, scale: 4
        t.integer "rate_id"
        t.integer "tyear",                                                              null: false
        t.integer "tmonth",                                                             null: false
        t.integer "tweek",                                                              null: false
      end

      create_table "cost_objects", id: :integer do |t|
        t.integer "project_id",                                 null: false
        t.integer "author_id",                                  null: false
        t.string "subject", null: false
        t.text "description", null: false
        t.string "type", null: false
        t.date "fixed_date", null: false
        t.datetime "created_on"
        t.datetime "updated_on"
      end

      add_index :cost_objects, %i[project_id updated_on]

      create_table "cost_types", id: :integer do |t|
        t.string "name",                           null: false
        t.string "unit",                           null: false
        t.string "unit_plural",                    null: false
        t.boolean "default", default: false, null: false
        t.datetime "deleted_at"
      end

      create_table "labor_budget_items", id: :integer do |t|
        t.integer "cost_object_id", null: false
        t.float "hours", null: false
        t.integer "user_id"
        t.string "comments", default: "", null: false
        t.decimal "budget", precision: 15, scale: 4
      end

      create_table "material_budget_items", id: :integer do |t|
        t.integer "cost_object_id", null: false
        t.float "units", null: false
        t.integer "cost_type_id"
        t.string "comments", default: "", null: false
        t.decimal "budget", precision: 15, scale: 4
      end

      create_table "rates", id: :integer do |t|
        t.date "valid_from", null: false
        t.decimal "rate", precision: 15, scale: 4, null: false
        t.string "type", null: false
        t.integer "project_id"
        t.integer "user_id"
        t.integer "cost_type_id"
      end

      change_table "time_entries", id: :integer do |t|
        t.decimal "overridden_costs", precision: 15, scale: 4
        t.decimal "costs",            precision: 15, scale: 4
        t.integer "rate_id"
      end

      create_table :cost_object_journals, id: :integer do |t|
        t.integer :journal_id,  null: false
        t.integer :project_id,  null: false
        t.integer :author_id,   null: false
        t.string :subject, null: false
        t.text :description
        t.date :fixed_date, null: false
        t.datetime :created_on
      end

      add_column :work_packages, :cost_object_id, :integer
      add_column :work_package_journals, :cost_object_id, :integer, null: true

      add_column :time_entry_journals, :overridden_costs, :decimal, precision: 15, scale: 2, null: true
      add_column :time_entry_journals, :costs, :decimal, precision: 15, scale: 2, null: true
      add_column :time_entry_journals, :rate_id, :integer

      TimeEntry.reset_column_information
    end
  end

  def down
    drop_table "cost_entries"
    drop_table "cost_objects"
    drop_table "cost_types"
    drop_table "labor_budget_items"
    drop_table "material_budget_items"
    drop_table "rates"
    drop_table "cost_object_journals"

    change_table "time_entries" do |t|
      t.remove_column "overridden_costs"
      t.remove_column "costs"
      t.remove_column "rate_id"
    end

    remove_column :work_packages, :cost_object_id
    remove_column :work_package_journals, :cost_object_id

    remove_column :time_entry_journals, :overridden_costs
    remove_column :time_entry_journals, :costs
    remove_column :time_entry_journals, :rate_id

    TimeEntry.reset_column_information
  end

  def migrations
    MIGRATION_FILES.split.map do |m|
      m.gsub(/_.*\z/, "")
    end
  end
end
