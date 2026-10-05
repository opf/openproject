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
# frozen_string_literal: true

class CreateScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :screens do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.string :screen_type, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
      t.check_constraint "screen_type IN ('create','edit','view','transition')", name: "screens_type_check"
    end

    create_table :screen_sections do |t|
      t.references :screen, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index %i[id screen_id], unique: true
    end
    add_index :screen_sections, "screen_id, lower(name)", unique: true,
                                                         name: "index_screen_sections_on_screen_and_lower_name"

    create_table :screen_items do |t|
      t.bigint :screen_id, null: false
      t.bigint :section_id, null: false
      t.string :field_key, null: false
      t.integer :position, null: false, default: 0
      t.string :width, null: false, default: "full"
      t.boolean :visible, null: false, default: true
      t.timestamps
      t.index %i[screen_id field_key], unique: true
      t.index %i[section_id position]
      t.check_constraint "width IN ('full','half')", name: "screen_items_width_check"
    end
    add_foreign_key :screen_items, :screen_sections, column: %i[section_id screen_id],
                                                     primary_key: %i[id screen_id], on_delete: :cascade

    create_table :screen_schemes do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :screen_scheme_items do |t|
      t.references :scheme, null: false, foreign_key: { to_table: :screen_schemes, on_delete: :cascade }, index: false
      t.references :type, null: false, foreign_key: { on_delete: :cascade }
      t.references :create_screen, null: true, foreign_key: { to_table: :screens, on_delete: :restrict }
      t.references :edit_screen, null: true, foreign_key: { to_table: :screens, on_delete: :restrict }
      t.references :view_screen, null: true, foreign_key: { to_table: :screens, on_delete: :restrict }
      t.references :transition_screen, null: true, foreign_key: { to_table: :screens, on_delete: :restrict }
      t.timestamps
      t.index %i[scheme_id type_id], unique: true
    end

    create_table :project_screen_schemes do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :scheme, null: false, foreign_key: { to_table: :screen_schemes, on_delete: :restrict }
      t.timestamps
    end
  end
end
