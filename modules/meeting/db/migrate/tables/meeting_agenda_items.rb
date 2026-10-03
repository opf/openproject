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

class Tables::MeetingAgendaItems < Tables::Base
  def self.table(migration)
    create_table migration do |t|
      t.references :meeting, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :title
      t.text :notes
      t.integer :position
      t.integer :duration_in_minutes
      t.timestamp :created_at, precision: nil, null: false
      t.timestamp :updated_at, precision: nil, null: false
      t.references :work_package, index: true
      t.integer :item_type, default: 0, limit: 1
      t.integer :lock_version, default: 0, null: false
      t.references :presenter, foreign_key: { to_table: :users }, index: true
      t.references :meeting_section

      t.index :notes,
              using: "gin",
              opclass: :gin_trgm_ops
    end
  end
end
