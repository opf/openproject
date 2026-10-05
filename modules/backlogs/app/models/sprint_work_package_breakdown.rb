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
  Block = Data.define(:work_package_count, :story_points, :estimated_hours)
  ChangeBlock = Data.define(:added_count, :removed_count, :added_story_points, :removed_story_points,
                            :added_estimated_hours, :removed_estimated_hours)

  # @param metric [Symbol, nil] which sum to compute alongside the work package count -
  #   :story_points, :estimated_hours, or nil to skip both and only count work packages.
  def initialize(sprint:, project:, metric: nil)
    @sprint = sprint
    @project = project
    @metric = metric
  end

  def initially_planned
    @initially_planned ||= snapshot_block(reference_start)
  end

  def completed
    @completed ||= snapshot_block(reference_finish, done: true)
  end

  def unfinished
    @unfinished ||= snapshot_block(reference_finish, done: false)
  end

  def changed_after_start
    @changed_after_start ||= begin
      added_ids = added_after_start_ids
      removed_ids = removed_after_start_ids

      ChangeBlock.new(
        added_count: added_ids.size,
        removed_count: removed_ids.size,
        added_story_points: added_story_points(added_ids),
        removed_story_points: removed_story_points(removed_ids),
        added_estimated_hours: added_estimated_hours(added_ids),
        removed_estimated_hours: removed_estimated_hours(removed_ids)
      )
    end
  end

  def reference_start
    if @sprint.started_at?
      Timestamp.new(@sprint.started_at)
    else
      Timestamp.new(@sprint.start_date.in_time_zone.beginning_of_day)
    end
  end

  def reference_finish
    return Timestamp.new(@sprint.completed_at) if @sprint.completed_at?

    scheduled_finish = @sprint.finish_date.in_time_zone.end_of_day

    if @sprint.started_at?
      Timestamp.new([scheduled_finish, Time.zone.now].max)
    else
      Timestamp.new(scheduled_finish)
    end
  end

  def added_after_start_ids
    finish_ids - start_ids
  end

  def removed_after_start_ids
    start_ids - finish_ids
  end

  def done_status_ids
    @done_status_ids ||= @project.done_status_ids | Status.where(is_closed: true).ids
  end

  private

  def track_story_points?
    @metric == :story_points
  end

  def track_estimated_hours?
    @metric == :estimated_hours
  end

  def sum_values(ids, values_by_id)
    ids.sum { |id| values_by_id[id] || 0 }
  end

  def added_story_points(ids)
    sum_values(ids, finish_points) if track_story_points?
  end

  def removed_story_points(ids)
    sum_values(ids, start_points) if track_story_points?
  end

  def added_estimated_hours(ids)
    sum_values(ids, finish_hours) if track_estimated_hours?
  end

  def removed_estimated_hours(ids)
    sum_values(ids, start_hours) if track_estimated_hours?
  end

  def start_ids
    @start_ids ||= if track_story_points?
                     start_points.keys
                   elsif track_estimated_hours?
                     start_hours.keys
                   else
                     sprint_work_packages_at(reference_start).pluck(:id)
                   end
  end

  def finish_ids
    @finish_ids ||= if track_story_points?
                      finish_points.keys
                    elsif track_estimated_hours?
                      finish_hours.keys
                    else
                      sprint_work_packages_at(reference_finish).pluck(:id)
                    end
  end

  def start_points
    @start_points ||= sprint_work_packages_at(reference_start).pluck(:id, :story_points).to_h
  end

  def finish_points
    @finish_points ||= sprint_work_packages_at(reference_finish).pluck(:id, :story_points).to_h
  end

  def start_hours
    @start_hours ||= sprint_work_packages_at(reference_start).pluck(:id, :estimated_hours).to_h
  end

  def finish_hours
    @finish_hours ||= sprint_work_packages_at(reference_finish).pluck(:id, :estimated_hours).to_h
  end

  def snapshot_block(timestamp, done: nil)
    scope = filter_by_done(sprint_work_packages_at(timestamp), done)

    Block.new(
      work_package_count: scope.count,
      story_points: track_story_points? ? (scope.sum(:story_points) || 0) : nil,
      estimated_hours: track_estimated_hours? ? (scope.sum(:estimated_hours) || 0) : nil
    )
  end

  def sprint_work_packages_at(timestamp)
    WorkPackage
      .where(project: @project, sprint: @sprint)
      .visible
      .at_timestamp(timestamp)
  end

  def filter_by_done(scope, done)
    case done
    when true then scope.where(status_id: done_status_ids)
    when false then scope.where.not(status_id: done_status_ids)
    else scope
    end
  end
end
