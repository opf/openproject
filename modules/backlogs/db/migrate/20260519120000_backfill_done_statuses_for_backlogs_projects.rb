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

class BackfillDoneStatusesForBacklogsProjects < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO done_statuses_for_project (project_id, status_id)
      SELECT DISTINCT projects.id, statuses.id
      FROM projects
      JOIN enabled_modules ON enabled_modules.project_id = projects.id AND enabled_modules.name = 'backlogs'
      CROSS JOIN statuses
      WHERE statuses.is_closed = true
        AND NOT EXISTS (
          SELECT 1
          FROM done_statuses_for_project existing
          WHERE existing.project_id = projects.id
            AND existing.status_id = statuses.id
        )
    SQL
  end

  def down; end
end
