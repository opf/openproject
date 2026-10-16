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

module WorkPackages::UpdateService::MoveTimeEntries
  private

  def cleanup(work_package)
    super

    if work_package.saved_change_to_project_id?
      move_time_entries([work_package] + work_package.descendants, work_package.project_id)
    end
  end

  # Saved individually so that +TimeEntry#update_costs+ re-rates each entry against the target
  # project. Validations are skipped because entries logged under earlier settings (enforced
  # start times, required custom fields) may no longer validate and must not block the move.
  def move_time_entries(work_packages, project_id)
    TimeEntry
      .on_work_packages(work_packages)
      .find_each do |entry|
        entry.project_id = project_id
        entry.save(validate: false)
      end
  end
end
