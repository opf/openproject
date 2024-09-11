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

class SimplifyProjectActiveAndTimestamp < ActiveRecord::Migration[6.0]
  STATUS_ACTIVE     = 1
  STATUS_ARCHIVED   = 9

  class Project < ApplicationRecord; end

  def change
    change_project_columns

    reversible do |change|
      change.up do
        fill_active_column
      end
      change.down do
        recreate_status_column_and_information
      end
    end
  end

  private

  def change_project_columns
    change_table :projects do |table|
      table.rename :created_on, :created_at
      table.rename :updated_on, :updated_at
      table.rename :is_public, :public
    end
  end

  def fill_active_column
    add_column :projects, :active, :boolean, default: true, null: false
    add_index :projects, :active

    Project.reset_column_information
    Project.where(status: STATUS_ARCHIVED).update_all(active: false)

    remove_column :projects, :status
  end

  def recreate_status_column_and_information
    add_column :projects, :status, :integer, default: STATUS_ACTIVE, null: false

    Project.reset_column_information
    Project.where(active: true).update_all(status: STATUS_ACTIVE)
    Project.where(active: false).update_all(status: STATUS_ARCHIVED)

    remove_column :projects, :active
  end
end
