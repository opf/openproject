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
class AddUniquenessForWatchersTable < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    execute <<~SQL.squish
      DELETE FROM watchers w1
      USING watchers w2
      WHERE w1.id > w2.id
        AND w1.user_id = w2.user_id
        AND w1.watchable_type = w2.watchable_type
        AND w1.watchable_id = w2.watchable_id;
    SQL

    add_index :watchers, ["user_id", "watchable_type", "watchable_id"],
              unique: true,
              algorithm: :concurrently,
              name: "index_watchers_on_user_id_and_watchable"
  end

  def down
    remove_index :watchers, name: "index_watchers_on_user_id_and_watchable", algorithm: :concurrently
  end
end
