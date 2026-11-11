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

class AddProjectSpecificValuesToCustomFields < ActiveRecord::Migration[8.1]
  def up
    add_column :custom_fields, :settings, :jsonb, null: false, default: {}

    execute <<~SQL.squish
      UPDATE custom_fields
      SET settings = jsonb_strip_nulls(
        jsonb_build_object(
          'regexp', regexp,
          'min_length', min_length,
          'max_length', max_length,
          'min_value', min_value,
          'max_value', max_value,
          'default_value', default_value,
          'content_right_to_left', content_right_to_left,
          'allow_non_open_versions', allow_non_open_versions,
          'user_self_editable', CASE WHEN type = 'UserCustomField' THEN editable END
        )
      )
    SQL

    change_table :custom_fields, bulk: true do |t|
      t.remove :regexp
      t.remove :min_length
      t.remove :max_length
      t.remove :min_value
      t.remove :max_value
      t.remove :default_value
      t.remove :content_right_to_left
      t.remove :allow_non_open_versions
      t.remove :editable
    end

    add_reference :custom_options, :project, foreign_key: true
    add_reference :hierarchical_items, :project, foreign_key: true
  end

  def down
    remove_reference :hierarchical_items, :project, foreign_key: true
    remove_reference :custom_options, :project, foreign_key: true

    change_table :custom_fields, bulk: true do |t|
      t.string :regexp, default: ""
      t.integer :min_length, default: 0, null: false
      t.integer :max_length, default: 0, null: false
      t.float :min_value
      t.float :max_value
      t.text :default_value
      # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :content_right_to_left, default: false
      t.boolean :allow_non_open_versions, default: false
      t.boolean :editable, default: true
      # rubocop:enable Rails/ThreeStateBooleanColumn
    end

    execute <<~SQL.squish
      UPDATE custom_fields
      SET regexp = COALESCE(settings->>'regexp', ''),
          min_length = COALESCE((settings->>'min_length')::integer, 0),
          max_length = COALESCE((settings->>'max_length')::integer, 0),
          min_value = (settings->>'min_value')::float,
          max_value = (settings->>'max_value')::float,
          default_value = settings->>'default_value',
          content_right_to_left = COALESCE((settings->>'content_right_to_left')::boolean, false),
          allow_non_open_versions = COALESCE((settings->>'allow_non_open_versions')::boolean, false),
          editable = COALESCE((settings->>'user_self_editable')::boolean, true)
    SQL

    remove_column :custom_fields, :settings
  end
end
