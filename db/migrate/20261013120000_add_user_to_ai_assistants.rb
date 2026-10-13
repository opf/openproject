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

# A personal assistant belongs to a user and shows only in their menu. A null user means
# a global assistant. Names are unique among global assistants and among a user's own.
class AddUserToAIAssistants < ActiveRecord::Migration[8.1]
  def change
    add_reference :ai_assistants, :user, foreign_key: { on_delete: :cascade }, null: true, index: false

    remove_index :ai_assistants, :name, unique: true
    add_index :ai_assistants, :name, unique: true, where: "user_id IS NULL",
                                     name: "index_ai_assistants_on_global_name"
    add_index :ai_assistants, %i[user_id name], unique: true, where: "user_id IS NOT NULL",
                                                name: "index_ai_assistants_on_user_id_and_name"
  end
end
