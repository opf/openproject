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
#       Journal::WorkPackageJournal.where(project_id: project.id, sprint_id: sprint.id),
#       ticks:
#     ).relation
#       .where.not(status_id: closed_status_ids)
#       .group(:tick)
#       .sum(:story_points)                    # => { Time(UTC) => Float }
#
# Entries are read-only and carry no work package behaviour; see Entry.
#
# A single tick is the frozen-snapshot case and needs no separate code path.
#
# The filters are a constructor argument rather than chained onto the result because they run
# before the visibility check, which is the more expensive of the two. They belong on the
# journalized columns rather than on the current work_packages row, because membership is
# historic -- a work package moved out of a sprint drops out of the series from that point
# onwards.
#
# Unlike Journable::HistoricActiveRecordRelation (which powers baseline comparison), this
# yields a row per tick rather than collapsing to the first matching one, so it can back a
# dense time series. Exactly one journal is valid per work package per instant, guaranteed by
# the non_overlapping_journals_validity_periods exclusion constraint, so no DISTINCT is needed.
class WorkPackages::JournalTimeline
  def initialize(filters = Journal::WorkPackageJournal.all, ticks:, user: User.current)
    @filters = filters
    @ticks = Array(ticks)
    @user = user
  end

  attr_reader :filters, :ticks, :user

  def relation
    return Entry.none if ticks.empty?

    from(ticked_journals)
  end

  private

  def journal_class = Journal::WorkPackageJournal

  def from(scope) = Entry.from(Arel.sql("(#{scope.to_sql}) #{Entry.table_name}"))

  # Spreading last keeps the row-multiplying step off the visibility check.
  def ticked_journals
    from(visible_journals)
      .joins(ticks_join)
      .select("ticks.tick", "#{Entry.table_name}.*")
  end

  # WorkPackage.visible cannot be used here: its semi-join matches on work package id, so with
  # one row per journal a single visible journal would whitelist the whole history. Visibility
  # is therefore decided per row -- against the journal's own project_id, so that moving a work
  # package between projects does not retroactively reveal or hide earlier values.
  def visible_journals
    journals = from(filtered_journals)

    journals
      .where(project_id: Project.allowed_to(user, :view_work_packages))
      .or(journals.where(work_package_id: shared_work_package_ids))
  end

  # Work packages visible but not through project permission are exactly the shared ones.
  # TODO: replace with a dedicated WorkPackage scope returning only share-visible work packages,
  # rather than deriving the set by subtraction.
  def shared_work_package_ids
    return [] unless Member.of_any_work_package.exists?(principal: user)

    WorkPackage
      .visible(user)
      .where.not(project_id: Project.allowed_to(user, :view_work_packages))
      .select(:id)
  end

  def filtered_journals
    filters
      .joins(journals_join)
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

  def journals_join
    sanitize(<<~SQL.squish, data_type: journal_class.name)
      INNER JOIN #{Journal.table_name}
        ON #{Journal.table_name}.data_id = #{journal_class.table_name}.id
       AND #{Journal.table_name}.data_type = :data_type
    SQL
  end

  def interval_condition
    from, to = ticks.minmax

    sanitize("#{Journal.table_name}.validity_period && tstzrange(:from, :to, '[]')", from:, to:)
  end

  def ticks_join
    <<~SQL.squish
      INNER JOIN (VALUES #{tick_values}) AS ticks(tick)
        ON #{Entry.table_name}.validity_period @> ticks.tick
    SQL
  end

  def tick_values
    ticks.map { sanitize("(CAST(:tick AS timestamptz))", tick: it) }.join(", ")
  end

  def sanitize(statement, **binds) = journal_class.sanitize_sql_array([statement, binds])
end
