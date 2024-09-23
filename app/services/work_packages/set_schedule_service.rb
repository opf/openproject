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

class WorkPackages::SetScheduleService
  attr_accessor :user, :work_packages, :initiated_by

  def initialize(user:, work_package:, initiated_by: nil)
    self.user = user
    self.work_packages = Array(work_package)
    self.initiated_by = initiated_by
  end

  def call(changed_attributes = %i(start_date due_date))
    altered = []

    if %i(parent parent_id).intersect?(changed_attributes)
      altered += schedule_by_parent
    end

    if %i(start_date due_date parent parent_id).intersect?(changed_attributes)
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
          assign_cause_for_journaling(wp, :parent)
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
    assign_cause_for_journaling(scheduled, :children)
  end

  # Calculates the dates of a work package based on its follows relations.
  #
  # The start date of a work package is constrained by its direct and indirect
  # predecessors, as it must start strictly after all predecessors finish.
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
    return unless dependency.soonest_start_date

    new_start_date = [scheduled.start_date, dependency.soonest_start_date].compact.max
    new_due_date = determine_due_date(scheduled, new_start_date)
    set_dates(scheduled, new_start_date, new_due_date)
    assign_cause_for_journaling(scheduled, :predecessor)
  end

  def determine_due_date(work_package, start_date)
    # due date is set only if the moving work package already has one or has a
    # duration. If not, due date is nil (and duration will be nil too).
    return unless work_package.due_date || work_package.duration

    due_date =
      if work_package.duration
        days(work_package).due_date(start_date, work_package.duration)
      else
        work_package.due_date
      end

    # if due date is before start date, then start is used as due date.
    [start_date, due_date].max
  end

  def set_dates(work_package, start_date, due_date)
    work_package.start_date = start_date
    work_package.due_date = due_date
    work_package.duration = days(work_package).duration(start_date, due_date)
  end

  def days(work_package)
    WorkPackages::Shared::Days.for(work_package)
  end

  def assign_cause_for_journaling(work_package, relation)
    return {} if initiated_by.nil?
    return {} unless work_package.changes.keys.intersect?(%w(start_date due_date duration))

    if initiated_by.is_a?(WorkPackage)
      assign_cause_initiated_by_work_package(work_package, relation)
    elsif initiated_by.is_a?(CauseOfChange::Base)
      work_package.journal_cause = initiated_by
    end
  end

  def assign_cause_initiated_by_work_package(work_package, _relation)
    # For now we only track a generic cause, and not a specialized reason depending on the relation
    # work_package.journal_cause = case relation
    #                             when :parent then Journal::CausedByWorkPackageParentChange.new(initiated_by)
    #                             when :children then Journal::CausedByWorkPackageChildChange.new(initiated_by)
    #                             when :predecessor then Journal::CausedByWorkPackagePredecessorChange.new(initiated_by)
    #                             end

    work_package.journal_cause = Journal::CausedByWorkPackageRelatedChange.new(work_package: initiated_by)
  end
end
