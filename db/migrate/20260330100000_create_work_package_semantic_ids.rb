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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateWorkPackageSemanticIds < ActiveRecord::Migration[8.1]
  def up
    # Atomic counter for per-project WP sequence allocation
    add_column :projects, :wp_sequence_counter, :integer, default: 0, null: false, if_not_exists: true

    # Per-project sequence number for semantic identifiers (e.g. PROJ-42)
    add_column :work_packages, :sequence_number, :integer, if_not_exists: true
    # Current semantic identifier stored directly on the work package (e.g. "PROJ-42")
    add_column :work_packages, :identifier, :string, if_not_exists: true

    create_table :work_package_semantic_aliases, if_not_exists: true do |t|
      t.string :identifier, null: false
      t.references :work_package, null: false, foreign_key: true
      t.timestamps
    end

    # Unique identifier across all WPs (past and present)
    add_index :work_package_semantic_aliases, :identifier, unique: true, if_not_exists: true

    # Fast lookup and uniqueness of the current semantic identifier (partial: excludes pre-backfill NULLs)
    add_index :work_packages, :identifier,
              unique: true,
              where: "identifier IS NOT NULL",
              if_not_exists: true

    # Enforce uniqueness of sequence numbers within a project (partial: excludes pre-backfill NULLs)
    add_index :work_packages, %i[project_id sequence_number],
              unique: true,
              where: "sequence_number IS NOT NULL",
              if_not_exists: true
  end

  def down
    drop_table :work_package_semantic_aliases, if_exists: true
    remove_index :work_packages, %i[project_id sequence_number], if_exists: true
    remove_column :work_packages, :identifier, if_exists: true
    remove_column :work_packages, :sequence_number, if_exists: true
    remove_column :projects, :wp_sequence_counter, if_exists: true
  end
end
