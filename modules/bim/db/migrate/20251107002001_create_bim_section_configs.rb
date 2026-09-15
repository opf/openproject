# frozen_string_literal: true

# -- copyright
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
# ++

class CreateBimSectionConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_section_configs do |t|
      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :ifc_models, on_delete: :cascade },
                   index: true

      t.references :user,
                   null: true,
                   foreign_key: { to_table: :users, on_delete: :nullify },
                   index: true

      t.string :name, null: false, limit: 255
      t.text :description

      # Section boxes - array of 6-plane clipping boxes
      # Each box: { min: [x, y, z], max: [x, y, z], enabled: true/false }
      t.jsonb :section_boxes, default: []

      # Section planes - array of custom section planes
      # Each plane: { pos: [x, y, z], dir: [x, y, z], enabled: true/false }
      t.jsonb :section_planes, default: []

      # Edge rendering configuration
      t.boolean :show_edges, default: true
      t.string :edge_color, limit: 7, default: '#000000'

      # Section fill configuration
      t.boolean :show_fills, default: false
      t.string :fill_color, limit: 7, default: '#FF0000'
      t.decimal :fill_opacity, precision: 3, scale: 2, default: 0.5

      # View visibility
      t.boolean :is_public, default: false

      t.timestamps
    end

    add_index :bim_section_configs, [:ifc_model_id, :name], unique: true
    add_index :bim_section_configs, :is_public
    add_index :bim_section_configs, :section_boxes, using: :gin
    add_index :bim_section_configs, :section_planes, using: :gin
  end
end
