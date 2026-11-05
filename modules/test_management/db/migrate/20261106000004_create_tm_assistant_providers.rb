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

class CreateTmAssistantProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :tm_assistant_providers do |t|
      t.string :name, null: false, limit: 100
      t.string :preset, null: false, default: "openrouter", limit: 32
      t.string :base_url, limit: 1024
      t.string :auth_style, limit: 16
      t.text :api_key_ciphertext
      t.string :model, limit: 255
      t.jsonb :user_models, null: false, default: []
      t.integer :timeout
      t.integer :max_tokens
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end
    add_index :tm_assistant_providers, "lower(name)", unique: true, name: "index_tm_assistant_providers_on_lower_name"
    add_index :tm_assistant_providers, :is_default,
              unique: true, where: "is_default", name: "index_tm_assistant_providers_one_default"
  end
end
