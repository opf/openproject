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

# The reports were converted to CostReport records in
# MigrateCostQueriesToCostReports, which each carry the id they had here so that
# links to them keep working.
class DropCostQueries < ActiveRecord::Migration[8.1]
  def up
    drop_table :cost_queries
  end

  def down
    create_table :cost_queries do |t|
      t.bigint :user_id, null: false
      t.bigint :project_id
      t.string :name, null: false
      t.boolean :is_public, default: false, null: false
      t.datetime :created_at, precision: nil, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :updated_at, precision: nil, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string :serialized, limit: 2000, null: false
    end
  end
end
