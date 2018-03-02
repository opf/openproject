#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require Rails.root.join('db', 'migrate', 'migration_utils', 'migration_squasher').to_s
require Rails.root.join('db', 'migrate', 'migration_utils', 'setting_renamer').to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedCostsMigrations < ActiveRecord::Migration[5.0]
  def initialize(*)
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  MIGRATION_FILES = <<-MIGRATIONS
    001_create_deliverables.rb
    002_add_cost_types_default.rb
    003_add_deliverable_to_issues.rb
    004_add_rate.rb
    005_add_deliverables_date_fields.rb
    006_delete_cost_from_cost_entries.rb
    007_refactor_deliverable_intermediates.rb
    008_remove_budget_from_deliverable.rb
    009_add_comment_field_to_budget.rb
    010_add_free_text_to_budget_and_entries.rb
    011_add_deleted_at_to_cost_types.rb
    012_refactor_terms.rb
    013_create_cost_queries.rb
    014_add_denormalized_costs_fields.rb
    015_add_cost_query_variables.rb
    016_denormalize_spent_on_of_cost_entries.rb
    017_rename_permissions.rb
    018_higher_precision_for_currency.rb
    20091123144305_add_permission_inheritance.rb
    20091130214149_primary_key_for_groups_users.rb
    20091204172554_remove_costs_from_issues.rb
    20120313152442_create_initial_variable_cost_object_journals.rb
    20121022124253_remove_group_user_enhancements.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = 'redmine_costs'

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table 'cost_entries' do |t|
        t.integer 'user_id',                                                            null: false
        t.integer 'project_id',                                                         null: false
        t.integer 'issue_id',                                                           null: false
        t.integer 'cost_type_id',                                                       null: false
        t.float 'units',                                                              null: false
        t.date 'spent_on',                                                           null: false
        t.datetime 'created_on',                                                         null: false
        t.datetime 'updated_on',                                                         null: false
        t.string 'comments',                                                           null: false
        t.boolean 'blocked',                                         default: false, null: false
        t.decimal 'overridden_costs', precision: 15, scale: 4
        t.decimal 'costs',            precision: 15, scale: 4
        t.integer 'rate_id'
        t.integer 'tyear',                                                              null: false
        t.integer 'tmonth',                                                             null: false
        t.integer 'tweek',                                                              null: false
      end

      create_table 'cost_objects' do |t|
        t.integer 'project_id',                                 null: false
        t.integer 'author_id',                                  null: false
        t.string 'subject',                                    null: false
        t.text 'description',                                null: false
        t.string 'type',                                       null: false
        t.boolean 'project_manager_signoff', default: false, null: false
        t.boolean 'client_signoff',          default: false, null: false
        t.date 'fixed_date',                                 null: false
        t.datetime 'created_on'
        t.datetime 'updated_on'
      end

      create_table 'cost_types' do |t|
        t.string 'name',                           null: false
        t.string 'unit',                           null: false
        t.string 'unit_plural',                    null: false
        t.boolean 'default',     default: false, null: false
        t.datetime 'deleted_at'
      end

      create_table 'labor_budget_items' do |t|
        t.integer 'cost_object_id',                                                null: false
        t.float 'hours',                                                         null: false
        t.integer 'user_id'
        t.string 'comments',                                      default: '', null: false
        t.decimal 'budget',         precision: 15, scale: 4
      end

      create_table 'material_budget_items' do |t|
        t.integer 'cost_object_id',                                                null: false
        t.float 'units',                                                         null: false
        t.integer 'cost_type_id'
        t.string 'comments',                                      default: '', null: false
        t.decimal 'budget',         precision: 15, scale: 4
      end

      create_table 'rates' do |t|
        t.date 'valid_from',                                  null: false
        t.decimal 'rate',         precision: 15, scale: 4, null: false
        t.string 'type',                                        null: false
        t.integer 'project_id'
        t.integer 'user_id'
        t.integer 'cost_type_id'
      end

      if @issues_table_exists
        change_table 'issues' do |t|
          t.column :cost_object_id, :integer, null: true
        end
      end

      change_table 'time_entries' do |t|
        t.decimal 'overridden_costs', precision: 15, scale: 4
        t.decimal 'costs',            precision: 15, scale: 4
        t.integer 'rate_id'
      end
      TimeEntry.reset_column_information
      Migration::SettingRenamer.rename('plugin_redmine_costs', 'plugin_openproject_costs')
    end
  end

  def down
    drop_table 'cost_entries'
    drop_table 'cost_objects'
    drop_table 'cost_queries'
    drop_table 'cost_types'
    drop_table 'labor_budget_items'
    drop_table 'material_budget_items'
    drop_table 'rates'
    if @issues_table_exists
      remove_column :issues, :cost_object_id
    end

    change_table 'time_entries' do |t|
      t.remove_column 'overridden_costs'
      t.remove_column 'costs'
      t.remove_column 'rate_id'
    end
    TimeEntry.reset_column_information
  end
end
