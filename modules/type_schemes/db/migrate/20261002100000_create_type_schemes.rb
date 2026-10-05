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

class CreateTypeSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :type_schemes do |t|
      t.string  :name, null: false, index: { unique: true }
      t.text    :description
      t.boolean :is_default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :type_schemes, :is_default, unique: true, where: "is_default", name: "idx_type_scheme_one_default"

    create_table :type_scheme_items do |t|
      t.references :scheme, null: false, index: false, foreign_key: { to_table: :type_schemes, on_delete: :cascade }
      t.references :type,   null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.timestamps
      t.index %i[scheme_id type_id], unique: true
      t.index :scheme_id, unique: true, where: "is_default", name: "idx_type_scheme_item_one_default"
    end

    create_table :project_type_schemes do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :scheme,  null: false, foreign_key: { to_table: :type_schemes }
      t.timestamps
    end
  end
end
