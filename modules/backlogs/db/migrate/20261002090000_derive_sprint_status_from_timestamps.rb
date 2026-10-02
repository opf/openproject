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

class DeriveSprintStatusFromTimestamps < ActiveRecord::Migration[8.1]
  STATUS_EXPRESSION = <<~SQL.squish
    CASE
      WHEN completed_at IS NOT NULL THEN 'completed'
      WHEN started_at IS NOT NULL THEN 'active'
      ELSE 'in_planning'
    END
  SQL

  def up
    backfill_timestamps
    clear_contradicting_timestamps

    remove_column :sprints, :status
    add_column :sprints, :status, :virtual, type: :string, as: STATUS_EXPRESSION, stored: true
  end

  def down
    remove_column :sprints, :status
    add_column :sprints, :status, :string, default: "in_planning", null: false

    execute "UPDATE sprints SET status = #{STATUS_EXPRESSION}"
  end

  private

  def backfill_timestamps
    execute <<~SQL.squish
      UPDATE sprints
      SET started_at = COALESCE(start_date::timestamptz, created_at)
      WHERE status IN ('active', 'completed')
        AND started_at IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE sprints
      SET completed_at = COALESCE((finish_date + 1)::timestamptz - interval '1 microsecond', updated_at)
      WHERE status = 'completed'
        AND completed_at IS NULL
    SQL
  end

  def clear_contradicting_timestamps
    execute <<~SQL.squish
      UPDATE sprints
      SET completed_at = NULL
      WHERE status = 'active'
        AND completed_at IS NOT NULL
    SQL

    execute <<~SQL.squish
      UPDATE sprints
      SET started_at = NULL, completed_at = NULL
      WHERE status = 'in_planning'
        AND (started_at IS NOT NULL OR completed_at IS NOT NULL)
    SQL
  end
end
