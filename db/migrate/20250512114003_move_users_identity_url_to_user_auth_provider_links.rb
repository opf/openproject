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

class MoveUsersIdentityUrlToUserAuthProviderLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :user_auth_provider_links do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :auth_provider, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.string :external_id, null: false
      t.timestamps null: false
      t.index %i[user_id auth_provider_id], unique: true
      t.index %i[auth_provider_id external_id], unique: true
    end

    # Code to migrate data into the new table was moved into 20250804133700 after adding a fix
  end
end
