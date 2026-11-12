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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "base"

class Tables::Queries < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.bigint :project_id
      t.string :name, null: false
      t.text :filters
      t.bigint :user_id, null: false
      t.boolean :public, default: false, null: false
      t.text :column_names
      t.text :sort_criteria
      t.string :group_by
      t.boolean :display_sums, default: false, null: false
      t.boolean :timeline_visible, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :show_hierarchies, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.integer :timeline_zoom_level, default: 5
      t.text :timeline_labels
      t.text :highlighting_mode
      t.text :highlighted_attributes
      t.timestamps precision: nil, null: true
      t.text :display_representation
      t.boolean :starred, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
      t.boolean :include_subprojects, null: false, default: nil
      t.string :timestamps

      t.index :project_id, name: "index_queries_on_project_id"
      t.index :user_id, name: "index_queries_on_user_id"
      t.index :updated_at
    end
  end
end
