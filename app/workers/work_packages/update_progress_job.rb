#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WorkPackages::UpdateProgressJob < ApplicationJob
  queue_with_priority :default

  def perform(previous_mode: nil)
    if previous_mode == "disabled"
      unset_all_percent_complete_values
    end
    fix_remaining_work_set_with_100p_complete
    fix_remaining_work_exceeding_work
    fix_only_work_being_set
    fix_only_remaining_work_being_set
    derive_unset_remaining_work_from_work_and_p_complete
    derive_unset_work_from_remaining_work_and_p_complete
    derive_p_complete_from_work_and_remaining_work

    create_journals_for_updated_work_packages
  end

  private

  def unset_all_percent_complete_values
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET done_ratio = NULL
      WHERE done_ratio IS NOT NULL
    SQL
  end

  def fix_remaining_work_set_with_100p_complete
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET estimated_hours = remaining_hours,
          remaining_hours = 0
      WHERE estimated_hours IS NULL
        AND remaining_hours > 0
        AND done_ratio = 100
    SQL
  end

  def fix_remaining_work_exceeding_work
    # avoid a division by zero when work and remaining work are both zero in
    # `#derive_p_complete_from_work_and_remaining_work` method.
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET done_ratio = 0
      WHERE remaining_hours = estimated_hours
    SQL
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET remaining_hours = estimated_hours,
          done_ratio = 0
      WHERE remaining_hours > estimated_hours
        AND done_ratio IS NULL
    SQL
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET remaining_hours = ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
      WHERE remaining_hours > estimated_hours
        AND done_ratio IS NOT NULL
    SQL
  end

  def fix_only_work_being_set
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET remaining_hours = estimated_hours,
          done_ratio = 0
      WHERE estimated_hours IS NOT NULL
        AND remaining_hours IS NULL
        AND done_ratio IS NULL
    SQL
  end

  def fix_only_remaining_work_being_set
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET estimated_hours = remaining_hours,
          done_ratio = 0
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio IS NULL
    SQL
  end

  def derive_unset_remaining_work_from_work_and_p_complete
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET remaining_hours = ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
      WHERE estimated_hours IS NOT NULL
        AND remaining_hours IS NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def derive_unset_work_from_remaining_work_and_p_complete
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET estimated_hours = ROUND((remaining_hours * 100 / (100 - done_ratio))::numeric, 2)
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def derive_p_complete_from_work_and_remaining_work
    execute_sql_update(<<~SQL.squish)
      UPDATE work_packages
      SET done_ratio = (estimated_hours - remaining_hours) * 100 / estimated_hours
      WHERE estimated_hours IS NOT NULL
        AND remaining_hours IS NOT NULL
        AND (
          done_ratio IS NULL OR (estimated_hours > remaining_hours)
        )
    SQL
  end

  def create_journals_for_updated_work_packages
    WorkPackage.where(id: updated_work_package_ids).find_each do |work_package|
      Journals::CreateService.new(work_package, system_user)
        .call(cause: { type: "system_update", feature: "progress_calculation_changed" })
    end
  end

  def execute_sql_update(sql)
    result = ActiveRecord::Base.connection.execute("#{sql} RETURNING id")
    updated_work_package_ids.merge(result.field_values("id"))
  end

  def updated_work_package_ids
    @updated_work_package_ids ||= Set.new
  end

  def system_user
    @system_user ||= User.system
  end
end
