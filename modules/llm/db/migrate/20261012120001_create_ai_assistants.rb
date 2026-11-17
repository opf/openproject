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

class CreateAIAssistants < ActiveRecord::Migration[8.1]
  def change
    create_assistants
    create_skills
    create_chats
    create_messages
    create_proposals
  end

  private

  def create_assistants
    create_table :ai_assistants do |t|
      # None for a global assistant, else the user or group that owns it.
      t.references :principal, foreign_key: { to_table: :users, on_delete: :cascade }, index: false
      t.string :name, null: false
      t.text :description
      t.text :instructions
      t.string :icon
      # Not a foreign key: syncing the models of an LLM connection replaces the llm_models rows.
      t.string :model_id
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index :name, unique: true, where: "principal_id IS NULL", name: "index_ai_assistants_on_global_name"
      t.index %i[principal_id name], unique: true, where: "principal_id IS NOT NULL"
    end
  end

  def create_skills
    create_table :ai_assistant_skills do |t|
      t.references :assistant, null: false, foreign_key: { to_table: :ai_assistants, on_delete: :cascade }, index: false
      t.string :skill_key, null: false
      # Shown in the menu; empty uses the text of the skill type.
      t.string :label
      t.text :description
      t.text :prompt
      # changes, comment_only or read_only: what the skill may propose.
      t.string :proposal_scope, null: false, default: "changes"
      t.jsonb :conditions, null: false, default: {}
      t.jsonb :settings, null: false, default: {}
      t.integer :position
      t.boolean :active, null: false, default: true

      t.timestamps

      # Not unique: one assistant can have several variants of a skill type.
      t.index %i[assistant_id skill_key]
    end
  end

  def create_chats
    create_table :ai_assistant_chats do |t|
      t.references :skill, null: false, foreign_key: { to_table: :ai_assistant_skills, on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps

      t.index %i[user_id work_package_id created_at]
    end
  end

  def create_messages
    create_table :ai_assistant_chat_messages do |t|
      t.references :chat, null: false, foreign_key: { to_table: :ai_assistant_chats, on_delete: :cascade }, index: false
      t.string :role, null: false
      t.text :content, null: false, default: ""
      # pending while the reply job runs; done or failed after it.
      t.string :status, null: false, default: "done"
      t.string :locale
      t.integer :base_lock_version
      t.jsonb :events, null: false, default: []

      t.timestamps

      t.index %i[chat_id id]
    end
  end

  def create_proposals
    create_table :ai_assistant_proposals do |t|
      t.references :message, null: false, index: false,
                             foreign_key: { to_table: :ai_assistant_chat_messages, on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string :severity
      t.string :area
      t.text :text
      t.jsonb :evidence, null: false, default: []
      t.jsonb :change_set
      t.integer :base_lock_version
      t.string :state, null: false, default: "open"
      t.string :dismiss_reason

      t.timestamps

      t.index %i[message_id position]
    end
  end
end
