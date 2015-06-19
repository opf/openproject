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

class RenameChangesetWpJoinTable < ActiveRecord::Migration
  def up
    remove_index :changesets_issues, name: :changesets_issues_ids

    rename_table :changesets_issues, :changesets_work_packages
    rename_column :changesets_work_packages, :issue_id, :work_package_id

    add_index :changesets_work_packages,
              [:changeset_id, :work_package_id],
              unique: true,
              name: :changesets_work_packages_ids
  end

  def down
    remove_index :changesets_work_packages, name: :changesets_work_packages_ids

    rename_table :changesets_work_packages, :changesets_issues
    rename_column :changesets_issues, :work_package_id, :issue_id

    add_index :changesets_issues,
              [:changeset_id, :issue_id],
              unique: true,
              name: :changesets_issues_ids
  end
end
