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

class CreateOAuthClientTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :oauth_client_tokens do |t|
      t.references :oauth_client, null: false, foreign_key: { to_table: :oauth_clients, on_delete: :cascade }
      t.references :user, null: false, index: true, foreign_key: { to_table: :users, on_delete: :cascade }

      t.string :access_token
      t.string :refresh_token
      t.string :token_type
      t.integer :expires_in
      t.string :scope
      t.string :origin_user_id # ID of the current user on the _OAuth2_provider_side_

      t.timestamps
      t.index %i[user_id oauth_client_id], unique: true
    end
  end
end
