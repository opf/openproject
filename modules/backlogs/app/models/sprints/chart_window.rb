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
# Three instants decide the shape, and none of them replace one another:
#
# - +charted_from+ -- where the chart opens: the moment the sprint was started, or the opening
#   of its planned start date while it has not been.
# - +measured_until+ -- how far a measured series is sampled. The current time for a running
#   sprint, the time it finished for a finished one, and nothing at all for one yet to begin.
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

    def initialize(sprint, zone: Time.zone)
      @sprint = sprint
      @zone = zone
    end

    attr_reader :zone

    delegate :planned_finish, :measured_until, to: :timeframe

    def charted_from
      timeframe.effective_start
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

    attr_reader :sprint

    def timeframe
      @timeframe ||= Timeframe.new(sprint, zone:)
    end
  end
end
