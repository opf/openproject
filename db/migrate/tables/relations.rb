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

class Tables::Relations < Tables::Base
  def self.table(migration)
    create_table migration do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.integer :from_id, null: false # TODO: turn into bigint, foreign key
      t.integer :to_id, null: false # TODO: turn into bigint, foreign key
      t.integer :lag
      t.text :description
      t.string :relation_type

      t.index :from_id, name: "index_relations_on_from_id"
      t.index :to_id, name: "index_relations_on_to_id"
      t.index %i[from_id to_id relation_type],
              unique: true
      t.index %i[to_id from_id relation_type],
              unique: true
    end
  end
end
