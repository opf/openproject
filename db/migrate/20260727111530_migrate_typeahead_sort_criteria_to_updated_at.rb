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

require Rails.root.join("db/migrate/migration_utils/utils")

class MigrateTypeaheadSortCriteriaToUpdatedAt < ActiveRecord::Migration[8.1]
  include Migration::Utils

  # "Autocomplete" (the typeahead select) is no longer offered as a Sort-by option (see COMMS-930)
  # since its sortable SQL was always just "updated_at DESC" under the hood — so any query
  # currently sorting by it behaves identically to sorting by updated_at desc. Migrate persisted
  # sort_criteria accordingly, leaving any other sort criteria entries on the same query untouched.
  def up
    in_configurable_batches(Query) do |batches|
      batches.each_record do |query|
        criteria = query.sort_criteria
        next unless criteria.any? { |key, _direction| key == "typeahead" }

        migrated = criteria.map { |key, direction| key == "typeahead" ? ["updated_at", "desc"] : [key, direction] }
        migrated = migrated.uniq { |key, _direction| key }

        query.update_column(:sort_criteria, migrated)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
