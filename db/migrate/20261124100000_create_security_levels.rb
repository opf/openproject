# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateSecurityLevels < ActiveRecord::Migration[8.1]
  def change
    create_level_tables

    add_reference :projects, :security_level_scheme, foreign_key: { on_delete: :nullify }

    add_reference :work_packages, :security_level, index: false, foreign_key: { on_delete: :nullify }
    add_reference :work_package_journals, :security_level, index: false, foreign_key: false

    # Visibility filtering needs no index (see script/benchmarks/security_levels); this one keeps
    # the ON DELETE SET NULL of a removed level and per-level lookups off a sequential scan.
    add_index :work_packages, :security_level_id, where: "security_level_id IS NOT NULL"
  end

  private

  def create_level_tables
    create_table :security_level_schemes do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.timestamps
    end

    create_table :security_levels do |t|
      t.references :security_level_scheme, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.timestamps

      t.index %i[security_level_scheme_id name], unique: true
    end

    create_table :security_level_principals do |t|
      t.references :security_level, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :principal, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps

      t.index %i[security_level_id principal_id], unique: true
    end
  end
end
