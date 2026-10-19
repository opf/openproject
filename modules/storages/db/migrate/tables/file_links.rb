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

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::FileLinks < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :storage, foreign_key: { on_delete: :cascade }
      t.references :creator,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :users }
      t.bigint :container_id, null: true
      t.string :container_type, null: true

      t.string :origin_id
      t.string :origin_name
      t.string :origin_created_by_name
      t.string :origin_last_modified_by_name
      t.string :origin_mime_type
      t.datetime :origin_created_at, precision: nil
      t.datetime :origin_updated_at, precision: nil

      t.timestamps precision: nil

      # i.e. show all file links per WP.
      t.index %i[container_id container_type]
      # i.e. show all work packages per file.
      t.index %i[origin_id storage_id]
    end
  end
end
