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

# The stretch of time a sprint's charts cover, the resolution they cover it at, and the points
# in time they are sampled at. Shared by every chart on the sprint report so that two of them
# drawn side by side agree on where the axis begins and ends.
#
# A window usually belongs to the one sprint being reported on, and +spanning+ builds one that
# reaches back over the sprints before it instead. Either way it closes where that sprint does.
#
# Three instants decide the shape, and none of them replace one another:
#
# - +charted_from+ -- where the chart opens: the moment the opening sprint was started, or the
#   opening of its planned start date while it has not been.
# - +measured_until+ -- how far a measured series is sampled. The current time while the sprint
#   is still open, the time it closed once it has, and nothing at all before it opens.
# - +charted_until+ -- where the sprint got to (for a completed sprint) or is planned to go to
#   (for a running one). If the sprint is running longer than planned, there is no plan any more
#   and the current time is used instead.
#
# +planned_finish+ is carried through for the series that are spent against the plan rather than
# measured, which have to reach it whatever the sprint actually did.
#
# The viewer's time zone is settled by the caller and handed down to Timeframe and Ticks.
# Everything below either works in absolute instants or is told which zone to use, so that the
# days these series are sampled over start and end where the person reading the chart expects.
module Sprints
  class ChartWindow
    # Beyond this an hourly series says more about rendering cost than about progress.
    HOURLY_STEP_LIMIT = 31.days

    # Beyond this a sprint says nothing a reader can act on, and an hourly series over it would
    # not render at all.
    CHARTABLE_SPAN = 1.year

    # A window over several sprints, opening with the earliest of them that still leaves a span
    # anyone can read. Seven long sprints can exceed CHARTABLE_SPAN between them, and opening
    # later costs history, which is less than the whole chart.
    def self.spanning(sprints, zone: Time.zone)
      windows = sprints.map { new(sprints.last, zone:, opening_sprint: it) }

      windows.reject(&:too_long_to_chart?).min_by(&:charted_from) || windows.last
    end

    def initialize(sprint, zone: Time.zone, opening_sprint: sprint)
      @sprint = sprint
      @opening_sprint = opening_sprint
      @zone = zone
    end

    attr_reader :zone

    delegate :planned_finish, to: :timeframe

    def charted_from
      opening_timeframe.effective_start
    end

    # How far a measured series is sampled: up to now, and never past where the window closes.
    # Nothing at all before the window opens, which is not the same as before the sprint began --
    # preceding sprints in the window have been measurable all along.
    def measured_until
      return nil if now < charted_from

      [now, charted_until].min
    end

    def charted_until
      timeframe.effective_finish
    end

    def charted_range
      charted_from..charted_until
    end

    # How far the chart reaches, which both of its limits are stated against. Whole days, because
    # that is the resolution both are set at.
    def charted_span
      (charted_until.to_date - charted_from.to_date).to_i.days
    end

    def step
      charted_span > HOURLY_STEP_LIMIT ? :day : :hour
    end

    def too_long_to_chart?
      charted_span > CHARTABLE_SPAN
    end

    # Empty for a sprint that has not begun and for one too long to draw, so that every series
    # built from these comes back empty rather than each chart guarding for itself.
    def ticks
      return [] if too_long_to_chart? || measured_until.nil?

      @ticks ||= WorkPackages::JournalTimeline::Ticks.build(from: charted_from,
                                                            to: measured_until,
                                                            step:,
                                                            zone:)
    end

    def non_working_intervals
      return [] if too_long_to_chart?

      @non_working_intervals ||= Day.non_working_intervals(from: charted_from.to_date, to: charted_until.to_date)
    end

    private

    attr_reader :sprint, :opening_sprint

    def now = Time.current.in_time_zone(zone)

    def timeframe
      @timeframe ||= Timeframe.new(sprint, zone:)
    end

    def opening_timeframe
      @opening_timeframe ||= opening_sprint == sprint ? timeframe : Timeframe.new(opening_sprint, zone:)
    end
  end
end
