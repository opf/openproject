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

# The requested resource is now a placeholder user reachable through
# `placeholder_user_id`, so the inline copies of it are dropped.
#
# Journals are carried over first: their rows predate `placeholder_user_id` and
# would otherwise lose the record of what a past version asked for.
class RemoveInlineFilterColumnsFromResourceAllocations < ActiveRecord::Migration[8.1]
  def up
    carry_journals_over_to_placeholder_user

    remove_column :resource_allocations, :user_filter
    remove_column :resource_allocations, :filter_name
    remove_column :resource_allocations, :principal_explicit

    remove_column :resource_allocation_journals, :user_filter
    remove_column :resource_allocation_journals, :filter_name
    remove_column :resource_allocation_journals, :principal_explicit
  end

  def down
    add_column :resource_allocations, :user_filter, :jsonb, default: []
    add_column :resource_allocations, :filter_name, :string
    add_column :resource_allocations, :principal_explicit, :boolean, null: false, default: true

    add_column :resource_allocation_journals, :user_filter, :jsonb, default: []
    add_column :resource_allocation_journals, :filter_name, :string
    add_column :resource_allocation_journals, :principal_explicit, :boolean

    restore_inline_columns_from_placeholder_user(:resource_allocations)
    restore_inline_columns_from_placeholder_user(:resource_allocation_journals)
  end

  private

  def carry_journals_over_to_placeholder_user
    execute(<<~SQL.squish)
      UPDATE resource_allocation_journals raj
      SET placeholder_user_id = ra.placeholder_user_id
      FROM journals j
      JOIN resource_allocations ra ON ra.id = j.journable_id
      WHERE j.data_id = raj.id
        AND j.data_type = 'Journal::ResourceAllocationJournal'
        AND j.journable_type = 'ResourceAllocation'
        AND raj.principal_explicit = false
        AND raj.placeholder_user_id IS NULL
    SQL
  end

  def restore_inline_columns_from_placeholder_user(table)
    execute("UPDATE #{table} SET principal_explicit = (placeholder_user_id IS NULL)")

    execute(<<~SQL.squish)
      UPDATE #{table} t
      SET filter_name = u.lastname,
          user_filter = d.user_filter
      FROM users u
      JOIN placeholder_user_details d ON d.principal_id = u.id
      WHERE u.id = t.placeholder_user_id
    SQL
  end
end
