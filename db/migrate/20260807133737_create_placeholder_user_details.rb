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

class CreatePlaceholderUserDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :placeholder_user_details do |t|
      t.references :principal, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      # Nullable: ActiveRecord serializes an empty filter to NULL, because the
      # coder loads NULL back as `[]`.
      t.jsonb :user_filter, default: []
      t.text :description

      t.timestamps
    end

    # Delegation assumes a detail is always there; it is only auto-built for new
    # records, so existing placeholder users need one.
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          INSERT INTO placeholder_user_details (principal_id, user_filter, created_at, updated_at)
          SELECT id, '[]'::jsonb, NOW(), NOW()
          FROM users
          WHERE type = 'PlaceholderUser'
        SQL
      end
    end
  end
end
