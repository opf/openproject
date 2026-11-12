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

class Tables::Messages < Tables::Base
  # rubocop:disable Metrics/AbcSize
  def self.table(migration)
    create_table migration do |t|
      t.bigint :forum_id, null: false
      t.bigint :parent_id
      t.string :subject, default: "", null: false
      t.text :content
      t.bigint :author_id
      t.integer :replies_count, default: 0, null: false
      t.bigint :last_reply_id
      t.timestamps precision: nil, default: -> { "CURRENT_TIMESTAMP" }
      t.boolean :locked, default: false
      t.integer :sticky, default: 0
      t.datetime :sticked_on, precision: false, default: nil, null: true

      t.index :author_id, name: "index_messages_on_author_id"
      t.index :forum_id, name: "messages_board_id" # Name kept for compatibility
      t.index :created_at, name: "index_messages_on_created_at"
      t.index :last_reply_id, name: "index_messages_on_last_reply_id"
      t.index :parent_id, name: "messages_parent_id"
      t.index %i[forum_id updated_at]
    end
  end
  # rubocop:enable Metrics/AbcSize
end
