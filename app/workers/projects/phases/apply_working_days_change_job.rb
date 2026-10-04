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

class Projects::Phases::ApplyWorkingDaysChangeJob < ApplyWorkingDaysChangeJobBase
  private

  def apply_working_days_change
    Project.where(id: applicable_phases.select(:project_id)).find_each do |project|
      phases = project.available_phases.drop_while { !it.start_date? }
      from = phases.first&.start_date
      next unless from

      ProjectPhases::RescheduleService.new(user: User.current, project:).call(phases:, from:)

      project.journal_cause = journal_cause

      project.touch_and_save_journals
    end
  end

  def applicable_phases
    days_of_week = changed_days.keys
    dates = changed_non_working_dates.keys

    Project::Phase
      .active
      .covering_dates_or_days_of_week(days_of_week:, dates:)
  end
end
