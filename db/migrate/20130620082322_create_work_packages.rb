#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class CreateWorkPackages < ActiveRecord::Migration
  def up
    create_table 'work_packages' do |t|
      # Issue
      t.column :tracker_id, :integer, default: 0, null: false
      t.column :project_id, :integer
      t.column :subject, :string, default: '', null: false
      t.column :description, :text
      t.column :due_date, :date
      t.column :category_id, :integer
      t.column :status_id, :integer, default: 0, null: false
      t.column :assigned_to_id, :integer
      t.column :priority_id, :integer, default: 0, null: false
      t.column :fixed_version_id, :integer
      t.column :author_id, :integer, default: 0, null: false
      t.column :lock_version, :integer, default: 0, null: false
      t.column :done_ratio, :integer, default: 0, null: false
      t.column :estimated_hours, :float
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp

      # Planning Element
      t.column :start_date, :date
      t.column :end_date, :date
      t.column :planning_element_status_comment, :text
      t.column :deleted_at, :datetime

      t.belongs_to :parent
      t.belongs_to :project
      t.belongs_to :responsible
      t.belongs_to :planning_element_type
      t.belongs_to :planning_element_status

      # STI
      t.column :type, :string

      # Nested Set
      t.column :parent_id, :integer, default: nil
      t.column :root_id, :integer, default: nil
      t.column :lft, :integer, default: nil
      t.column :rgt, :integer, default: nil
    end

    # Issue compatibility
    # Because of 't.belongs_to :project' (see above) column 'project_id'
    # becomes nullable. That breaks compatibility with issue behavior.
    change_table 'work_packages' do |t|
      t.change :project_id, :integer, default: 0, null: false
    end

    # Planning Elements
    add_index :work_packages, :parent_id
    add_index :work_packages, :project_id
    add_index :work_packages, :responsible_id
    add_index :work_packages, :planning_element_type_id
    add_index :work_packages, :planning_element_status_id

    # Nested Set
    add_index :work_packages, [:root_id, :lft, :rgt]

    change_table(:projects) do |t|
      t.belongs_to :work_packages_responsible

      t.index :work_packages_responsible_id
    end

    # Time Entry
    rename_column :time_entries, :issue_id, :work_package_id

    # Rename legacy tables 'issues' and 'planning_elements'
    rename_table :issues, :legacy_issues
    rename_table :planning_elements, :legacy_planning_elements
  end

  def down
    # Nested Set
    change_table(:projects) do |t|
      t.remove_belongs_to :work_packages_responsible
    end

    # Time Entry
    rename_column :time_entries, :work_package_id, :issue_id

    drop_table(:work_packages)

    # Revert renaming of legacy tables 'issues' and 'planning_elements'
    rename_table :legacy_issues, :issues
    rename_table :legacy_planning_elements, :planning_elements
  end
end
