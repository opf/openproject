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

class WorkPackageIndices < ActiveRecord::Migration[4.2]
  def up
    # drop obsolete fields
    remove_column :work_packages, :planning_element_status_comment
    remove_column :work_packages, :planning_element_status_id
    remove_column :work_packages, :sti_type
    remove_column :work_package_journals, :planning_element_status_comment
    remove_column :work_package_journals, :planning_element_status_id
    remove_column :work_package_journals, :sti_type

    add_index :work_packages, :type_id
    add_index :work_packages, :status_id
    add_index :work_packages, :category_id

    add_index :work_packages, :author_id
    add_index :work_packages, :assigned_to_id

    add_index :work_packages, :created_at
    add_index :work_packages, :fixed_version_id
  end

  def down
    add_column :work_packages, :planning_element_status_comment, :string
    add_column :work_packages, :planning_element_status_id, :integer
    add_column :work_packages, :sti_type, :string
    add_column :work_package_journals, :planning_element_status_comment, :string
    add_column :work_package_journals, :planning_element_status_id, :integer
    add_column :work_package_journals, :sti_type, :string

    remove_index :work_packages, :type_id
    remove_index :work_packages, :status_id
    remove_index :work_packages, :category_id

    remove_index :work_packages, :author_id
    remove_index :work_packages, :assigned_to_id

    remove_index :work_packages, :created_at
    remove_index :work_packages, :fixed_version_id
  end
end
