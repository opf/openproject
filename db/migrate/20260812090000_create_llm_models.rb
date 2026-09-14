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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CreateLlmModels < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_models do |t|
      t.references :llm_connection, null: false, foreign_key: true
      # Whatever this deployment calls the model. Provider-specific: Scaleway
      # serves "qwen3.6-35b-a3b" for weights another catalogue lists as
      # "Qwen/Qwen3.6-35B-A3B".
      t.string :external_id, null: false
      t.string :display_name
      t.boolean :active, null: false, default: true
      # Entered by an administrator rather than discovered. Survives a refresh
      # that cannot see it, which is what makes a server offering
      # /v1/chat/completions but no /v1/models usable.
      t.boolean :manual, null: false, default: false
      t.datetime :last_seen_at
      t.jsonb :raw_metadata, null: false, default: {}

      t.timestamps null: false
    end

    add_index :llm_models, %i[llm_connection_id external_id], unique: true

    # Superseded by the table above.
    remove_column :llm_connections, :catalogue, :jsonb, null: false, default: {}
  end
end
