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
# The references are the actual start and completion timestamps of the sprint.
class SprintWorkPackageBreakdown
  Block = Struct.new(:work_package_count, :story_points, keyword_init: true)
  ChangeBlock = Struct.new(:added_count, :removed_count, :added_story_points, :removed_story_points,
                           keyword_init: true)

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

  def changed_after_start
    return empty_change_block unless started?

    added_ids = added_after_start_ids
    removed_ids = removed_after_start_ids

    ChangeBlock.new(
      added_count: added_ids.size,
      removed_count: removed_ids.size,
      added_story_points: added_ids.sum { |id| finish_points[id] || 0 },
      removed_story_points: removed_ids.sum { |id| start_points[id] || 0 }
    )
  end

  def reference_start
    return nil unless started?

    Timestamp.new(@sprint.started_at)
  end

  def reference_finish
    return nil unless started?

    if @sprint.completed_at
      Timestamp.new(@sprint.completed_at)
    else
      Timestamp.now
    end
  end

  def added_after_start_ids
    return [] unless started?

    finish_points.keys - start_points.keys
  end

  def removed_after_start_ids
    return [] unless started?

    start_points.keys - finish_points.keys
  end

  def done_status_ids
    @done_status_ids ||= @project.done_status_ids | Status.where(is_closed: true).ids
  end

  private

  def started? = @sprint.started_at?

  def empty_change_block
    ChangeBlock.new(added_count: 0, removed_count: 0, added_story_points: 0, removed_story_points: 0)
  end

  def start_points
    @start_points ||= sprint_work_packages_at(reference_start).pluck(:id, :story_points).to_h
  end

  def finish_points
    @finish_points ||= sprint_work_packages_at(reference_finish).pluck(:id, :story_points).to_h
  end

  def snapshot_block(timestamp, done: nil)
    return Block.new(work_package_count: 0, story_points: 0) unless started?

    scope = sprint_work_packages_at(timestamp)
    scope = filter_by_done(scope, done)

    Block.new(work_package_count: scope.count, story_points: scope.sum(:story_points) || 0)
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
