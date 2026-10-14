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

# The proposals of an answer in an AI Assistance conversation. An answer can carry several,
# each applied or dismissed on its own. Replaces the single change set on chat messages.
class CreateAIAssistantProposals < ActiveRecord::Migration[8.1]
  def up
    create_proposals
    move_chat_proposals

    change_table :ai_assistant_chat_messages, bulk: true do |t|
      t.remove :change_set, type: :jsonb
      t.remove :state, type: :string, null: false, default: "open"
    end
  end

  def down
    change_table :ai_assistant_chat_messages, bulk: true do |t|
      t.jsonb :change_set
      t.string :state, null: false, default: "open"
    end
    drop_table :ai_assistant_proposals
  end

  private

  def create_proposals
    create_table :ai_assistant_proposals do |t|
      t.references :message, null: false, index: false,
                             foreign_key: { to_table: :ai_assistant_chat_messages, on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string :source, null: false, default: "ai"
      t.string :rule_key
      t.string :severity
      t.string :area
      t.text :text
      t.jsonb :evidence, null: false, default: []
      t.jsonb :change_set
      t.integer :base_lock_version
      t.string :state, null: false, default: "open"
      t.string :dismiss_reason

      t.timestamps
    end

    add_index :ai_assistant_proposals, %i[message_id position]
  end

  def move_chat_proposals
    execute <<~SQL.squish
      INSERT INTO ai_assistant_proposals (message_id, change_set, base_lock_version, state, created_at, updated_at)
      SELECT id, change_set, base_lock_version, state, created_at, updated_at
      FROM ai_assistant_chat_messages
      WHERE change_set IS NOT NULL
    SQL
  end
end
