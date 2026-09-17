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

require_relative "base"

class Tables::CustomFields < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.string :type, limit: 30, default: "", null: false
      t.string :field_format, limit: 30, default: "", null: false
      t.string :regexp, default: ""
      t.integer :min_length, default: 0, null: false
      t.integer :max_length, default: 0, null: false
      t.boolean :is_required, default: false, null: false
      t.boolean :is_for_all, default: false, null: false
      t.boolean :is_filter, default: true, null: false
      t.integer :position, default: 1
      t.boolean :searchable, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :editable, default: true # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :admin_only, default: false, null: false
      t.boolean :multi_value, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.text :default_value
      t.string :name, limit: nil, default: nil
      t.datetime :created_at, precision: nil
      t.datetime :updated_at, precision: nil
      t.boolean :content_right_to_left, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :allow_non_open_versions, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.references :custom_field_section
      t.integer :position_in_custom_field_section, null: true
      t.jsonb :formula, null: true

      t.index %i[id type], name: "index_custom_fields_on_id_and_type"
      t.index :formula, using: :gin
    end
  end
end
