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

class CreateAIAssistantChats < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_assistant_chats do |t|
      t.references :skill, null: false, foreign_key: { to_table: :ai_assistant_skills, on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps

      t.index %i[user_id work_package_id created_at]
    end

    create_table :ai_assistant_chat_messages do |t|
      t.references :chat, null: false, foreign_key: { to_table: :ai_assistant_chats, on_delete: :cascade }, index: false
      t.string :role, null: false
      t.text :content, null: false, default: ""
      # pending while the reply job runs; done or failed after it.
      t.string :status, null: false, default: "done"
      t.string :locale
      # A proposed change, in the same shape as a finding's change set.
      t.jsonb :change_set
      t.integer :base_lock_version
      t.string :state, null: false, default: "open"
      t.jsonb :events, null: false, default: []

      t.timestamps

      t.index %i[chat_id id]
    end
  end
end
