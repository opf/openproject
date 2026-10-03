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

class Tables::RecurringMeetings < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.datetime :start_time
      t.date :end_date, null: true
      t.text :title
      t.integer :frequency, default: 0, null: false
      t.integer :end_after, default: 0, null: false
      t.integer :iterations, null: true
      t.belongs_to :project, foreign_key: true, index: true
      t.belongs_to :author, foreign_key: { to_table: :users }

      t.timestamps

      t.integer :interval, default: 1, null: false
      t.string :time_zone, null: false
      t.string :uid

      t.index :uid, unique: true
    end
  end
end
