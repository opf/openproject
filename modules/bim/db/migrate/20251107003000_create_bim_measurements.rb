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

class CreateBimMeasurements < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_measurements do |t|
      t.references :ifc_model,
                   null: false,
                   foreign_key: { to_table: :ifc_models, on_delete: :cascade },
                   index: true

      t.references :user,
                   null: true,
                   foreign_key: { to_table: :users, on_delete: :nullify },
                   index: true

      # Measurement type: distance, area, volume, angle, elevation
      t.string :measurement_type, null: false, limit: 50

      # Calculated value
      t.decimal :value, null: false, precision: 15, scale: 4

      # Unit of measurement (m, m², m³, degrees, etc.)
      t.string :unit, null: false, limit: 20

      # Points used for measurement - array of [x, y, z] coordinates
      # For distance: 2+ points (multi-segment)
      # For area: 3+ points (polygon vertices)
      # For volume: bounding box or mesh vertices
      # For angle: 3 points (vertex + 2 directions)
      # For elevation: 1-2 points (point + optional reference)
      t.jsonb :points, null: false, default: []

      # Optional label/name for the measurement
      t.string :label, limit: 255

      # Description or notes
      t.text :description

      # Visual properties
      t.boolean :visible, default: true
      t.string :color, limit: 7, default: '#FF0000' # Hex color
      t.decimal :line_width, precision: 4, scale: 2, default: 2.0

      # Measurement metadata
      t.jsonb :metadata, default: {} # Additional calculation details

      t.timestamps
    end

    add_index :bim_measurements, :measurement_type
    add_index :bim_measurements, :visible
    add_index :bim_measurements, :points, using: :gin
    add_index :bim_measurements, [:ifc_model_id, :measurement_type]

    # Check constraint for valid measurement types
    add_check_constraint :bim_measurements,
                         "measurement_type IN ('distance', 'area', 'volume', 'angle', 'elevation')",
                         name: 'chk_valid_measurement_type'

    # Check constraint for positive values
    add_check_constraint :bim_measurements,
                         'value >= 0',
                         name: 'chk_positive_value'

    # Check constraint for line width
    add_check_constraint :bim_measurements,
                         'line_width > 0 AND line_width <= 10',
                         name: 'chk_line_width_range'
  end
end
