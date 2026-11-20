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

class RepositionWorkPackages < ActiveRecord::Migration[8.1]
  def change
    reversible do |direction|
      direction.up do
        # Used to be copied 1:1 from modules/backlogs/app/services/work_packages/rebuild_positions_service.rb.
        # In the meantime, the implementation of the service changed to accommodate backlog buckets.
        # But those did not exist at the time this migration represents.
        execute <<~SQL.squish
          UPDATE work_packages
          SET position = mapping.new_position
          FROM (
            SELECT
              id,
              ROW_NUMBER() OVER (
                PARTITION BY project_id, sprint_id
                ORDER BY position, created_at
              ) AS new_position
            FROM work_packages
          ) AS mapping
          WHERE work_packages.id = mapping.id
        SQL
      end
    end
  end
end
