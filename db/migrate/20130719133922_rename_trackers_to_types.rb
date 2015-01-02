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

class RenameTrackersToTypes < ActiveRecord::Migration
  # This migration leaves legacy issues as they are. After this
  # migration, those legacy issues have tracker_id columns as well as
  # having indexes that mention both tracker and issue, since there was
  # no index rename in the first place.

  def up
    # custom_fields_trackers
    remove_index :custom_fields_trackers,
                 name: :index_custom_fields_trackers_on_custom_field_id_and_tracker_id

    rename_table :custom_fields_trackers, :custom_fields_types

    rename_column :custom_fields_types, :tracker_id, :type_id

    add_index :custom_fields_types,
              [:custom_field_id, :type_id],
              name: :custom_fields_types_unique,
              unique: true

    # projects_trackers
    remove_index :projects_trackers,
                 name: :projects_trackers_project_id
    remove_index :projects_trackers,
                 name: :projects_trackers_unique

    rename_table :projects_trackers, :projects_types

    rename_column :projects_types, :tracker_id, :type_id

    add_index :projects_types,
              :project_id,
              name: :projects_types_project_id
    add_index :projects_types,
              [:project_id, :type_id],
              name: :projects_types_unique, unique: true

    # trackers
    rename_table :trackers, :types

    # work_packages
    rename_column :work_packages, :tracker_id, :type_id

    # workflows
    remove_index :workflows,
                 name: :wkfs_role_tracker_old_status

    rename_column :workflows,     :tracker_id, :type_id

    add_index :workflows,
              [:role_id, :type_id, :old_status_id],
              name: :wkfs_role_type_old_status
  end

  def down
    # custom_fields_trackers
    remove_index :custom_fields_types, name: :custom_fields_types_unique

    rename_column :custom_fields_types, :type_id, :tracker_id

    rename_table :custom_fields_types, :custom_fields_trackers

    add_index :custom_fields_trackers, [:custom_field_id, :tracker_id]

    # projects_trackers
    remove_index :projects_types, name: :projects_types_project_id
    remove_index :projects_types, name: :projects_types_unique

    rename_column :projects_types, :type_id, :tracker_id

    rename_table :projects_types, :projects_trackers

    add_index :projects_trackers,
              :project_id,
              name: :projects_trackers_project_id
    add_index :projects_trackers,
              [:project_id, :tracker_id],
              name: :projects_trackers_unique,
              unique: true

    # trackers
    rename_table :types, :trackers

    # work_packages
    rename_column :work_packages, :type_id, :tracker_id

    # workflows
    remove_index :workflows, name: :wkfs_role_type_old_status

    rename_column :workflows, :type_id, :tracker_id

    add_index :workflows,
              [:role_id, :tracker_id, :old_status_id],
              name: :wkfs_role_tracker_old_status
  end
end
