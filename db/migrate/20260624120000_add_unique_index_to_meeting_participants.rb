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

class AddUniqueIndexToMeetingParticipants < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Remove duplicate participants sharing the same (meeting_id, user_id), keeping the most recently updated one.
    execute <<~SQL.squish
      DELETE FROM meeting_participants
      WHERE id IN (
        SELECT id
        FROM (
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY meeting_id, user_id ORDER BY updated_at DESC, id DESC) AS row_num
          FROM meeting_participants
          WHERE user_id IS NOT NULL
        ) t
        WHERE t.row_num > 1
      );
    SQL

    old_index = ActiveRecord::Base
      .connection
      .indexes(:meeting_participants)
      .detect { |index| index.columns == ["meeting_id"] }
      &.name

    if old_index.present?
      say "Removing redundant non-unique index on meeting_id"
      remove_index :meeting_participants, name: old_index, algorithm: :concurrently
    end

    say "Adding unique index on (meeting_id, user_id)"
    add_index :meeting_participants, %i[meeting_id user_id],
              unique: true,
              algorithm: :concurrently,
              name: "index_meeting_participants_on_meeting_id_and_user_id"
  end

  def down
    say "Removing unique index"
    remove_index :meeting_participants,
                 name: "index_meeting_participants_on_meeting_id_and_user_id",
                 algorithm: :concurrently,
                 if_exists: true

    say "Re-adding non-unique index on meeting_id"
    add_index :meeting_participants, :meeting_id,
              algorithm: :concurrently,
              name: "index_meeting_participants_on_meeting_id"
  end
end
