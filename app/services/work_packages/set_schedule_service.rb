#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

class WorkPackages::SetScheduleService
  attr_accessor :user, :work_packages

  def initialize(user:, work_package:)
    self.user = user
    self.work_packages = Array(work_package)
  end

  def call(changed_attributes = %i(start_date due_date))
    altered = []

    if (%i(parent parent_id) & changed_attributes).any?
      altered += schedule_by_parent
    end

    if (%i(start_date due_date parent parent_id) & changed_attributes).any?
      altered += schedule_following
    end

    result = ServiceResult.success(result: work_packages.first)

    altered.each do |wp|
      result.add_dependent!(ServiceResult.success(result: wp))
    end

    result
  end

  private

  # rubocop:disable Metrics/AbcSize
  def schedule_by_parent
    work_packages
      .select { |wp| wp.start_date.nil? && wp.parent }
      .each do |wp|
        days = WorkPackages::Shared::Days.for(wp)
        wp.start_date = days.soonest_working_day(wp.parent.soonest_start)
        if wp.due_date || wp.duration
          wp.due_date = [
            wp.start_date,
            days.due_date(wp.start_date, wp.duration),
            wp.due_date
          ].compact.max
        end
      end
  end
  # rubocop:enable Metrics/AbcSize

  # Finds all work packages that need to be rescheduled because of a
  # rescheduling of the service's work package and reschedules them.
  #
  # The order of the rescheduling is important as successors' dates are
  # calculated based on their predecessors' dates and ancestors' dates based on
  # their children's dates.
  #
  # Thus, the work packages following (having a follows relation, direct or
  # transitively) the service's work package are first all loaded, and then
  # sorted by their need to be scheduled before one another:
  #
  # - predecessors are scheduled before their successors
  # - children/descendants are scheduled before their parents/ancestors
  #
  # Manually scheduled work packages are not encountered at this point as they
  # are filtered out when fetching the work packages eligible for rescheduling.
  def schedule_following
    altered = []

    WorkPackages::ScheduleDependency.new(work_packages).in_schedule_order do |scheduled, dependency|
      reschedule(scheduled, dependency)

      altered << scheduled if scheduled.changed?
    end

    altered
  end

  # Schedules work packages based on either
  #  - their descendants if they are parents
  #  - their predecessors (or predecessors of their ancestors) if they are
  #    leaves
  def reschedule(scheduled, dependency)
    if dependency.has_descendants?
      reschedule_by_descendants(scheduled, dependency)
    else
      reschedule_by_predecessors(scheduled, dependency)
    end
  end

  # Inherits the start/due_date from the descendants of this work package.
  #
  # Only parent work packages are scheduled like this. start_date receives the
  # minimum of the dates (start_date and due_date) of the descendants due_date
  # receives the maximum of the dates (start_date and due_date) of the
  # descendants
  def reschedule_by_descendants(scheduled, dependency)
    set_dates(scheduled, dependency.start_date, dependency.due_date)
  end

  # Calculates the dates of a work package based on its follows relations.
  #
  # The follows relations of ancestors are considered to be equal to own follows
  # relations as they inhibit moving a work package just the same. Only leaf
  # work packages are calculated like this.
  #
  # work package is moved to a later date:
  #   - following work packages are moved forward only to ensure they start
  #     after their predecessor's finish date. They may not need to move at all
  #     when there a time buffer between a follower and its predecessors
  #     (predecessors can also be acquired transitively by ancestors)
  #
  # work package moved to an earlier date:
  #   - following work packages do not move at all.
  def reschedule_by_predecessors(scheduled, dependency)
    min_start_date = dependency.soonest_start_date
    return unless min_start_date

    if !scheduled.start_date
      schedule_on_missing_dates(scheduled, min_start_date)
    elsif min_start_date > scheduled.start_date
      reschedule_to_date(scheduled, min_start_date)
    end
  end

  def reschedule_to_date(scheduled, date)
    new_start_date = [scheduled.start_date, date].compact.max
    # a new due date is set only if the moving work package already has one
    if scheduled.due_date
      new_due_date = [
        WorkPackages::Shared::Days.for(scheduled).due_date(new_start_date, scheduled.duration),
        new_start_date,
        scheduled.due_date
      ].compact.max
    end

    set_dates(scheduled, new_start_date, new_due_date)
  end

  def schedule_on_missing_dates(scheduled, min_start_date)
    min_start_date = WorkPackages::Shared::Days.for(scheduled).soonest_working_day(min_start_date)
    set_dates(scheduled,
              min_start_date,
              scheduled.due_date && scheduled.due_date < min_start_date ? min_start_date : scheduled.due_date)
  end

  def set_dates(work_package, start_date, due_date)
    work_package.start_date = start_date
    work_package.due_date = due_date
    work_package.duration = WorkPackages::Shared::Days
                              .for(work_package)
                              .duration(start_date, due_date)
  end
end
