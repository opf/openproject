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

class AddUniquenessForCostTypeNames < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    execute <<~SQL.squish
      UPDATE cost_types SET name = cost_types.name || ' ' || counter.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY LOWER(name) ORDER BY id) AS rn FROM cost_types) AS counter
      WHERE cost_types.id = counter.id AND counter.rn > 1;
    SQL

    add_index :cost_types, "LOWER(name)", unique: true, algorithm: :concurrently, name: "index_cost_types_on_LOWER_name"
  end

  def down
    remove_index :cost_types, name: "index_cost_types_on_LOWER_name", algorithm: :concurrently
  end
end
