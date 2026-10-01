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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class AddParentToTypes < ActiveRecord::Migration[8.1]
  def up
    add_reference :types, :parent, foreign_key: { to_table: :types }, null: true

    remove_index :types, name: "index_types_on_LOWER_name"

    add_index :types, "LOWER(name), parent_id",
              unique: true,
              nulls_not_distinct: true,
              name: "index_types_on_LOWER_name_and_parent_id"
  end

  def down
    remove_index :types, name: "index_types_on_LOWER_name_and_parent_id"
    add_index :types, "LOWER(name)", unique: true, name: "index_types_on_LOWER_name"

    remove_reference :types, :parent
  end
end
