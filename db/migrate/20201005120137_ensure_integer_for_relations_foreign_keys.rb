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

# The conversion of MySQL databases to PostgreSQL seems to create a lot of columns
# that should be of type `integer` but are created as `bigint`.
# This leads to cast errors e.g. when combining an array of integers with a bigint.
# This migration only focuses on two columns in the relations table
# as they need to be integers for custom sql (scope WorkPackages.for_scheduling).
class EnsureIntegerForRelationsForeignKeys < ActiveRecord::Migration[6.0]
  def up
    # The table information we have might be outdated
    Relation.reset_column_information

    # Nothing to do for us if the column already has the expected type
    return if Relation.column_for_attribute("from_id").sql_type == "integer"

    change_table :relations do |t|
      t.change :from_id, :integer, null: false
      t.change :to_id, :integer, null: false
    end

    Relation.reset_column_information
  end
end
