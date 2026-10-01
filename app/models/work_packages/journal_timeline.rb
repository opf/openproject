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

# Reads historic work package attributes at many points in time at once.
#
# Returns a relation of Entry, carrying one row per (tick, work package) with a +tick+ column
# and the journalized attribute values in effect at that tick:
#
#     WorkPackages::JournalTimeline.new(
#       Journal::WorkPackageJournal.where(project_id: project.id,
#                                         sprint_id: sprint.id,
#                                         status_id: open_statuses),
#       ticks:
#     ).relation
#       .group(:tick)
#       .sum(:story_points)                    # => { Time(UTC) => Float }
#
# Entries are read-only and carry no work package behaviour; see Entry.
#
# A single tick is the frozen-snapshot case and needs no separate code path.
#
# Every condition on a journalized column belongs in the constructor rather than chained onto
# the result: filters there run before the visibility check and before the row-multiplying tick
# spread, whereas anything chained afterwards runs after both. They belong on the journalized
# columns rather than on the current work_packages row, because membership is historic -- a work
# package moved out of a sprint drops out of the series from that point onwards.
class WorkPackages::JournalTimeline
  def initialize(filters = Journal::WorkPackageJournal.all, ticks:, user: User.current)
    @filters = filters
    @ticks = Array(ticks)
    @user = user
  end

  attr_reader :filters, :ticks, :user

  def relation
    return Entry.unscoped.none if ticks.empty?

    from(ticked_journals)
  end

  private

  def journal_class = Journal::WorkPackageJournal

  def from(scope) = Entry.unscoped.from(Arel.sql("(#{scope.to_sql}) #{Entry.table_name}"))

  # Spreading last keeps the row-multiplying step off the visibility check.
  def ticked_journals
    from(visible_journals)
      .joins(ticks_join)
      .select("ticks.tick", "#{Entry.table_name}.*")
  end

  # Project permission is decided per row, against the journal's own project_id, so that
  # moving a work package between projects neither reveals nor hides earlier values. A share
  # carries no validity period and so grants the whole timeline.
  # Using the WorkPackage.visible scope, which checks for both project based permission as well as shares
  # would include all journals of a work package that was ever in a project the user has a membership in.
  def visible_journals
    journals = from(filtered_journals)

    # The .or might be a potential performance bottleneck.
    # Oftentimes, using a UNION is more performant. Requires measuring to know.
    journals
      .where(project_id: Project.allowed_to(user, :view_work_packages))
      .or(journals.where(work_package_id: WorkPackage.allowed_to_via_share_only(user, :view_work_packages)))
  end

  def filtered_journals
    filters
      .joins(:journal)
      .where(interval_condition)
      .select(journal_selects)
  end

  def journal_selects
    [
      "#{journal_class.table_name}.*",
      "#{Journal.table_name}.journable_id AS work_package_id",
      "#{Journal.table_name}.id AS journal_id",
      "#{Journal.table_name}.validity_period",
      "#{Journal.table_name}.updated_at"
    ]
  end

  def interval_condition
    sanitize("#{Journal.table_name}.validity_period && tstzrange(:from, :to, '[]')",
             from: ticks.min,
             to: ticks.max)
  end

  # One array literal with a single cast rather than a VALUES row per tick, which halves the
  # statement for the tick counts an hourly series produces.
  def ticks_join
    <<~SQL.squish
      INNER JOIN unnest(#{tick_array}) AS ticks(tick)
        ON #{Entry.table_name}.validity_period @> ticks.tick
    SQL
  end

  def tick_array
    sanitize("CAST(ARRAY[:ticks] AS timestamptz[])", ticks:)
  end

  def sanitize(statement, **binds) = journal_class.sanitize_sql_array([statement, binds])
end
