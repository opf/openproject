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

# Reconstructs how a sprint's work package set moved over its lifetime, using
# WorkPackage.at_timestamp (see Journable::Timestamps) to read historic
# sprint_id/status_id/story_points values from work_package_journals.
class SprintWorkPackageBreakdown
  Block = Struct.new(:work_package_count, :story_points, :from_date, :to_date, keyword_init: true)

  def initialize(sprint:, project:)
    @sprint = sprint
    @project = project
  end

  def initially_planned
    snapshot_block(reference_start)
  end

  def completed
    snapshot_block(reference_finish, done: true)
  end

  def unfinished
    snapshot_block(reference_finish, done: false)
  end

  # Net change in the sprint's work package set between reference_start and reference_finish.
  def changed_after_start
    start_snapshot = sprint_work_packages_at(reference_start)
    finish_snapshot = sprint_work_packages_at(reference_finish)

    Block.new(
      work_package_count: finish_snapshot.count - start_snapshot.count,
      story_points: (finish_snapshot.sum(:story_points) || 0) - (start_snapshot.sum(:story_points) || 0),
      from_date: reference_start,
      to_date: reference_finish
    )
  end

  # The sprint hasn't started yet: nothing to snapshot at a future start date, so use today.
  # The sprint has started: the fixed start date wins over a later "today".
  def reference_start
    [@sprint.start_date, Time.zone.today].min
  end

  # The sprint hasn't finished yet: nothing to snapshot at a future finish date, so use today.
  # The sprint has already finished: the fixed finish date wins, so later report views don't
  # pick up sprint_id/status changes that happened after the sprint was closed.
  def reference_finish
    [@sprint.finish_date, Time.zone.today].min
  end

  # Same "done" definition as WorkPackages::Scopes::WithoutStatusConsideredClosed:
  # the project's configured done statuses, or any globally closed status. Public so the
  # widget can build a "Show all" link filtered to the same statuses used for these counts.
  def done_status_ids
    @done_status_ids ||= @project.done_status_ids | Status.where(is_closed: true).ids
  end

  private

  def snapshot_block(date, done: nil)
    scope = sprint_work_packages_at(date)
    scope = filter_by_done(scope, done)

    Block.new(work_package_count: scope.count, story_points: scope.sum(:story_points) || 0,
              from_date: date, to_date: date)
  end

  def sprint_work_packages_at(date)
    WorkPackage
      .where(project_id: @project.id, sprint_id: @sprint.id)
      .at_timestamp(Timestamp.parse(date.in_time_zone.end_of_day.iso8601))
  end

  def filter_by_done(scope, done)
    case done
    when true then scope.where(status_id: done_status_ids)
    when false then scope.where.not(status_id: done_status_ids)
    else scope
    end
  end
end
