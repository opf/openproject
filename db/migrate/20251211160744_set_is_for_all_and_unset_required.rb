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

require Rails.root.join("db/migrate/migration_utils/utils")

class SetIsForAllAndUnsetRequired < ActiveRecord::Migration[8.0]
  include Migration::Utils

  def up
    # With WP-69399, project custom fields support both required and is_for_all as separate flags.
    # Before, there was only is_required, which implied is_for_all.
    #
    # Take all project custom fields that are required and set is_for_all to true:
    execute <<~SQL.squish
      UPDATE custom_fields
      SET is_for_all = TRUE
      WHERE type = 'ProjectCustomField' AND is_required = TRUE
    SQL

    # Additionally, bool and calculated value can no longer be required.
    execute <<~SQL.squish
      UPDATE custom_fields
      SET is_required = FALSE
      WHERE field_format IN ('bool', 'calculated_value')
    SQL
  end

  def down
    # Down migration can only partly reconstruct the data
    execute <<~SQL.squish
      UPDATE custom_fields
      SET is_for_all = FALSE
      WHERE type = 'ProjectCustomField'
    SQL
  end
end
