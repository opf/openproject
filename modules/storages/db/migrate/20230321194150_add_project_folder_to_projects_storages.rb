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

class AddProjectFolderToProjectsStorages < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL.squish
      CREATE TYPE project_folder_modes AS ENUM ('inactive', 'manual');
    SQL

    change_table :projects_storages do |table|
      table.string :project_folder_id
      table.enum :project_folder_mode, enum_type: :project_folder_modes, default: :inactive, null: false
    end
  end

  def down
    remove_column :projects_storages, :project_folder_id
    remove_column :projects_storages, :project_folder_mode

    execute <<-SQL.squish
      DROP TYPE project_folder_modes;
    SQL
  end
end
