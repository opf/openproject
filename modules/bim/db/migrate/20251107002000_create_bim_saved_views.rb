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

class CreateBimSavedViews < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_saved_views do |t|
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

      # Camera position and orientation
      t.jsonb :camera_eye, null: false, default: {}     # [x, y, z]
      t.jsonb :camera_look, null: false, default: {}    # [x, y, z]
      t.jsonb :camera_up, null: false, default: {}      # [x, y, z]

      # Projection type
      t.string :projection, limit: 20, default: 'perspective' # 'perspective' or 'orthogonal'

      # View visibility (public vs private)
      t.boolean :is_public, default: false

      t.timestamps
    end

    add_index :bim_saved_views, [:ifc_model_id, :name], unique: true
    add_index :bim_saved_views, :is_public
  end
end
