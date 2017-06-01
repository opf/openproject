#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class CreateWorkPackageJournals < ActiveRecord::Migration[4.2]
  def change
    create_table :work_package_journals do |t|
      t.integer :journal_id,                                      null: false
      t.integer :type_id,                         default: 0,  null: false
      t.integer :project_id,                      default: 0,  null: false
      t.string :subject,                         default: '', null: false
      t.text :description
      t.date :due_date
      t.integer :category_id
      t.integer :status_id,                       default: 0,  null: false
      t.integer :assigned_to_id
      t.integer :priority_id,                     default: 0,  null: false
      t.integer :fixed_version_id
      t.integer :author_id,                       default: 0,  null: false
      t.integer :lock_version,                    default: 0,  null: false
      t.integer :done_ratio,                      default: 0,  null: false
      t.float :estimated_hours
      t.datetime :created_at
      t.datetime :updated_at
      t.date :start_date
      t.text :planning_element_status_comment
      t.datetime :deleted_at
      t.integer :parent_id
      t.integer :responsible_id
      t.integer :planning_element_status_id
      t.string :sti_type
      t.integer :root_id
      t.integer :lft
      t.integer :rgt
    end
  end
end
