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

class AddUniqueIndexToUserPreferencesOnUserId < ActiveRecord::Migration[8.0]
  def up
    say "Removing duplicate user_preferences if any exist"

    # Remove any duplicate user_preferences, keeping the most recently updated one
    execute <<~SQL.squish
      DELETE FROM user_preferences
      WHERE id IN (
        SELECT id
        FROM (
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC, id DESC) AS row_num
          FROM user_preferences
        ) t
        WHERE t.row_num > 1
      );
    SQL

    old_index = ActiveRecord::Base
      .connection
      .indexes(:user_preferences)
      .detect { |index| index.columns == ["user_id"] }
      &.name

    if old_index.present?
      say "Removing old non-unique index"
      remove_index :user_preferences, name: old_index
    end

    say "Adding unique index on user_id"
    add_index :user_preferences, :user_id,
              unique: true,
              name: "index_user_preferences_on_user_id"
  end

  def down
    say "Removing unique index"
    remove_index :user_preferences, name: "index_user_preferences_on_user_id", if_exists: true

    say "Re-adding non-unique index"
    add_index :user_preferences, :user_id,
              name: "index_user_preferences_on_user_id"
  end
end
