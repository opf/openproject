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

class CreateFieldRules < ActiveRecord::Migration[8.1]
  def change
    create_table :field_rule_sets do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :field_rules do |t|
      t.references :rule_set, null: false, foreign_key: { to_table: :field_rule_sets, on_delete: :cascade }, index: false
      t.string :field_key, null: false
      t.boolean :hidden, null: false, default: false
      t.boolean :required, null: false, default: false
      t.boolean :read_only, null: false, default: false
      t.boolean :enforce_on_update, null: false, default: false
      t.text :default_value
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index %i[rule_set_id field_key], unique: true
    end

    create_table :field_rule_schemes do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :field_rule_scheme_items do |t|
      t.references :scheme, null: false, foreign_key: { to_table: :field_rule_schemes, on_delete: :cascade }, index: false
      t.references :type, null: false, foreign_key: { on_delete: :cascade }
      t.references :rule_set, null: false, foreign_key: { to_table: :field_rule_sets }
      t.timestamps
      t.index %i[scheme_id type_id], unique: true
    end

    create_table :project_field_rule_schemes do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :scheme, null: false, foreign_key: { to_table: :field_rule_schemes }
      t.timestamps
    end
  end
end
