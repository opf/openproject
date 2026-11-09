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

class Tables::OAuthApplications < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :secret, null: false
      t.string :owner_type
      t.bigint :owner_id
      t.bigint :client_credentials_user_id
      t.text :redirect_uri, null: false
      t.string :scopes, null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps precision: nil, null: false
      # Add owner of an application
      t.foreign_key :users, column: :owner_id, on_delete: :nullify
      # Allow to map a user to use for client credentials auth flow
      t.foreign_key :users, column: :client_credentials_user_id, on_delete: :nullify
      t.references :integration, polymorphic: true
      t.column :enabled, :boolean, default: true, null: false
      t.column :builtin, :boolean, default: false, null: false

      t.index :uid, unique: true
      t.index %i[owner_id owner_type]
    end
  end
end
