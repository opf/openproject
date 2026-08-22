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

class CreateLlmConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_connections do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :type, null: false, index: true
      t.boolean :enabled, null: false, default: false
      t.string :base_url, null: false
      # Ciphered through Redmine::Ciphering when database_cipher_key is configured.
      # Nullable: an unauthenticated self-hosted server needs no key.
      t.string :api_key
      # Which dialect the server speaks. Only a subset is implemented; the column
      # exists so that adding a format is a new adapter rather than a migration.
      t.string :api_format, null: false, default: "openai"
      # Provider-specific headers sent with every request, e.g. Azure's
      # api-version or a gateway's own key header.
      t.jsonb :custom_headers, null: false, default: {}
      t.jsonb :options, null: false, default: {}
      # Raw /v1/models payload plus any server-specific metadata, stored verbatim.
      t.jsonb :catalogue, null: false, default: {}
      t.datetime :catalogue_fetched_at
      t.string :connection_fingerprint
      # Model references are strings, never foreign keys: a selection must survive
      # the model disappearing from the remote catalogue.
      t.string :default_chat_model_id
      t.string :default_embedding_model_id
      t.datetime :last_connected_at

      t.timestamps null: false
    end
  end
end
