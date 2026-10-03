# frozen_string_literal: true

# -- copyright
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
# ++

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::Meetings < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.string :title
      t.bigint :author_id
      t.bigint :project_id
      t.string :location
      t.datetime :start_time, precision: nil
      t.float :duration
      t.timestamps precision: nil, null: false
      t.integer :state, default: 0, null: false
      t.integer :lock_version, default: 0, null: false
      t.references :recurring_meeting, index: true
      t.boolean :template, default: false, null: false
      t.string :uid
      t.boolean :notify, default: true, null: false

      t.index %i[project_id updated_at]
      t.index :uid, unique: true
    end
  end
end
