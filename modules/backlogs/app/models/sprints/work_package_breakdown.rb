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

# Reconstructs how a sprint's work package set moved over its lifetime, reading historic
# sprint_id/status_id/story_points values from work_package_journals.
module Sprints
  class WorkPackageBreakdown
    Block = Data.define(:work_package_count, :story_points)
    ChangeBlock = Data.define(:added_count, :removed_count, :added_story_points, :removed_story_points)
    Snapshot = Data.define(:work_package_id, :story_points, :status_id)

    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    def initially_planned
      @initially_planned ||= block(start_snapshots)
    end

    def completed
      @completed ||= block(finish_snapshots.select { done?(it) })
    end

    def unfinished
      @unfinished ||= block(finish_snapshots.reject { done?(it) })
    end

    def changed_after_start
      @changed_after_start ||= begin
        added_ids = added_after_start_ids
        removed_ids = removed_after_start_ids

        ChangeBlock.new(
          added_count: added_ids.size,
          removed_count: removed_ids.size,
          added_story_points: added_ids.sum { |id| finish_points[id] || 0 },
          removed_story_points: removed_ids.sum { |id| start_points[id] || 0 }
        )
      end
    end

    def reference_start
      Timestamp.new(timeframe.effective_start)
    end

    def reference_finish
      return Timestamp.now if @sprint.started_at? && !@sprint.completed_at?

      Timestamp.new(timeframe.effective_finish)
    end

    def added_after_start_ids
      finish_points.keys - start_points.keys
    end

    def removed_after_start_ids
      start_points.keys - finish_points.keys
    end

    def done_status_ids
      @done_status_ids ||= @project.statuses_considered_closed.ids
    end

    private

    def timeframe
      @timeframe ||= Timeframe.new(@sprint)
    end

    def start_points
      @start_points ||= points_by_id(start_snapshots)
    end

    def finish_points
      @finish_points ||= points_by_id(finish_snapshots)
    end

    def start_snapshots
      snapshots_at(reference_start)
    end

    def finish_snapshots
      snapshots_at(reference_finish)
    end

    def snapshots_at(timestamp)
      snapshots_by_tick.fetch(timestamp.to_time.to_i, [])
    end

    def ticks
      [reference_start, reference_finish].map(&:to_time).uniq
    end

    def snapshots_by_tick
      @snapshots_by_tick ||= ::WorkPackages::JournalTimeline
                               .new(sprint_journals, ticks:, user: @user)
                               .relation
                               .pluck(:tick, :work_package_id, :story_points, :status_id)
                               .group_by { |tick, *| tick.to_i }
                               .transform_values { |rows| rows.map { |_tick, *attributes| Snapshot.new(*attributes) } }
    end

    def sprint_journals
      Journal::WorkPackageJournal.where(project_id: @project.id, sprint_id: @sprint.id)
    end

    def block(snapshots)
      Block.new(work_package_count: snapshots.size, story_points: snapshots.sum { it.story_points || 0 })
    end

    def points_by_id(snapshots)
      snapshots.to_h { [it.work_package_id, it.story_points] }
    end

    def done?(snapshot)
      done_status_ids.include?(snapshot.status_id)
    end
  end
end
