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

class RenameCostObjectToBudget < ActiveRecord::Migration[6.0]
  def up
    if primary_key_index_name(:cost_objects) != "cost_objects_pkey"
      warn "Found unexpected primary key name. Fixing primary key names..."

      require "./db/migrate/20190502102512_ensure_postgres_index_names"

      EnsurePostgresIndexNames.new.up
    end

    remove_column :cost_objects, :type
    rename_table :cost_objects, :budgets

    execute <<~SQL.squish
      UPDATE types
      SET attribute_groups = REGEXP_REPLACE(attribute_groups, ' cost_object', ' budget')
      WHERE attribute_groups LIKE '%cost_object%'
    SQL

    execute <<~SQL.squish
      UPDATE role_permissions
      SET permission = 'view_budgets'
      WHERE permission = 'view_cost_objects'
    SQL

    execute <<~SQL.squish
      UPDATE role_permissions
      SET permission = 'edit_budgets'
      WHERE permission = 'edit_cost_objects'
    SQL

    execute <<~SQL.squish
      UPDATE journals
      SET activity_type = 'budgets'
      WHERE activity_type = 'cost_objects'
    SQL

    execute <<~SQL.squish
      UPDATE attachments
      SET container_type = 'Budget'
      WHERE container_type = 'CostObject'
    SQL

    rename_in_queries("cost_object", "budget")
    rename_in_cost_queries("CostObject", "Budget")

    rename_column :budgets, :created_on, :created_at
    rename_column :budgets, :updated_on, :updated_at

    rename_table :cost_object_journals, :budget_journals
    remove_column :budget_journals, :created_on

    rename_column :work_packages, :cost_object_id, :budget_id
    rename_column :work_package_journals, :cost_object_id, :budget_id
    rename_column :labor_budget_items, :cost_object_id, :budget_id
    rename_column :labor_budget_items, :budget, :amount
    rename_column :material_budget_items, :cost_object_id, :budget_id
    rename_column :material_budget_items, :budget, :amount
  end

  def down
    rename_column :material_budget_items, :amount, :budget
    rename_column :material_budget_items, :budget_id, :cost_object_id
    rename_column :labor_budget_items, :amount, :budget
    rename_column :labor_budget_items, :budget_id, :cost_object_id
    rename_column :work_packages, :budget_id, :cost_object_id
    rename_column :work_package_journals, :budget_id, :cost_object_id

    add_column :budget_journals, :created_on, :timestamp
    rename_table :budget_journals, :cost_object_journals

    rename_column :budgets, :created_at, :created_on
    rename_column :budgets, :updated_at, :updated_on

    rename_in_queries("budget", "cost_object")
    rename_in_cost_queries("Budget", "CostObject")

    execute <<~SQL.squish
      UPDATE attachments
      SET container_type = 'CostObject'
      WHERE container_type = 'Budget'
    SQL

    execute <<~SQL.squish
      UPDATE journals
      SET activity_type = 'cost_objects'
      WHERE activity_type = 'budgets'
    SQL

    execute <<~SQL.squish
      UPDATE role_permissions
      SET permission = 'view_cost_objects'
      WHERE permission = 'view_budgets'
    SQL

    execute <<~SQL.squish
      UPDATE role_permissions
      SET permission = 'edit_cost_objects'
      WHERE permission = 'edit_budgets'
    SQL

    execute <<~SQL.squish
      UPDATE types
      SET attribute_groups = REGEXP_REPLACE(attribute_groups, ' budget', ' cost_object')
      WHERE attribute_groups LIKE '%budget%'
    SQL

    add_column :budgets, :type, :string

    execute <<~SQL.squish
      UPDATE budgets SET type = 'VariableCostObject'
    SQL

    change_column :budgets, :type, :string, null: false

    rename_table :budgets, :cost_objects
  end

  def rename_in_queries(old, new)
    execute <<~SQL.squish
      UPDATE queries
      SET filters = REGEXP_REPLACE(filters, '#{old}_id:', '#{new}_id:')
      WHERE filters LIKE '%#{old}_id%'
    SQL

    execute <<~SQL.squish
      UPDATE queries
      SET sort_criteria = REGEXP_REPLACE(sort_criteria, '#{old}', '#{new}')
      WHERE sort_criteria LIKE '%#{old}%'
    SQL

    execute <<~SQL.squish
      UPDATE queries
      SET column_names = REGEXP_REPLACE(column_names, '#{old}', '#{new}')
      WHERE column_names LIKE '%#{old}%'
    SQL

    execute <<~SQL.squish
      UPDATE queries
      SET group_by = REGEXP_REPLACE(group_by, '#{old}', '#{new}')
      WHERE group_by LIKE '%#{old}%'
    SQL

    execute <<~SQL.squish
      UPDATE queries
      SET timeline_labels = REGEXP_REPLACE(timeline_labels, '#{old.camelize(:lower)}', '#{new.camelize(:lower)}')
      WHERE timeline_labels LIKE '%#{old.camelize(:lower)}%'
    SQL
  end

  def rename_in_cost_queries(old, new)
    execute <<~SQL.squish
      UPDATE cost_queries
      SET serialized = REGEXP_REPLACE(serialized, '#{old}', '#{new}')
      WHERE serialized LIKE '%#{old}%'
    SQL
  end

  def primary_key_index_name(table_name)
    connection = ActiveRecord::Base.connection
    table = connection.quote table_name
    sql = "SELECT indexname FROM pg_indexes WHERE tablename = #{table} AND indexdef LIKE '%(id)';"

    connection.execute(sql).pluck("indexname").compact.first
  end
end
