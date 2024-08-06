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
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t|
      t.string :type, limit: 30, default: "", null: false
      t.string :field_format, limit: 30, default: "", null: false
      t.string :regexp, default: ""
      t.integer :min_length, default: 0, null: false
      t.integer :max_length, default: 0, null: false
      t.boolean :is_required, default: false, null: false
      t.boolean :is_for_all, default: false, null: false
      t.boolean :is_filter, default: false, null: false
      t.integer :position, default: 1
      t.boolean :searchable, default: false
      t.boolean :editable, default: true
      t.boolean :visible, default: true, null: false
      t.boolean :multi_value, default: false
      t.text :default_value
      t.string :name, limit: 255, default: nil
      t.datetime :created_at
      t.datetime :updated_at

      t.index %i[id type], name: "index_custom_fields_on_id_and_type"
    end
  end
  # rubocop:enable Metrics/AbcSize
end
