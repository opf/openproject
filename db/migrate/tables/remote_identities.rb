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

class Tables::RemoteIdentities < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :user, null: false, index: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.bigint :auth_source_id, null: false
      t.string :origin_user_id, null: false
      t.timestamps
      t.string :auth_source_type, null: false
      t.string :integration_type, null: false
      t.bigint :integration_id, null: false

      t.index %i[auth_source_type auth_source_id]
      t.index %i[integration_type integration_id]
      t.index %i[user_id auth_source_type auth_source_id integration_id integration_type],
              unique: true
    end
  end
end
