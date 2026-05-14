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

# Rewrites persisted :version_id filters to :target_version_id on Query records
# referenced by version-attribute Boards::Grid widgets, and on the matching
# widget options["filters"] snapshots. Both columns are YAML-serialized TEXT,
# so we operate on the literal serialized form via REPLACE().
class ConvertVersionIdFilterInVersionBoards < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE queries
      SET    filters = REPLACE(filters, E'\\nversion_id:', E'\\ntarget_version_id:')
      WHERE  id IN (
        SELECT CAST((regexp_match(gw.options, 'queryId:\\s*(\\d+)'))[1] AS INTEGER)
        FROM   grid_widgets gw
        JOIN   grids g ON g.id = gw.grid_id
        WHERE  g.type = 'Boards::Grid'
          AND  g.options ~ 'attribute: version'
          AND  gw.identifier = 'work_package_query'
          AND  gw.options ~ 'queryId:\\s*\\d+'
      )
      AND filters LIKE E'%\\nversion_id:%'
    SQL

    execute <<~SQL.squish
      UPDATE grid_widgets
      SET    options = REPLACE(options, E'\\n- :version_id:', E'\\n- :target_version_id:')
      WHERE  grid_id IN (
        SELECT id FROM grids
        WHERE  type = 'Boards::Grid' AND options ~ 'attribute: version'
      )
      AND identifier = 'work_package_query'
      AND options LIKE E'%\\n- :version_id:%'
    SQL
  end

  def down
    # we do not rollback
  end
end
