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

# Builds the points in time a JournalTimeline is sampled at: +from+, every period end in
# between, and +to+.
#
# Period ends are derived in +zone+ rather than UTC, because a "day" is only meaningful
# relative to a zone and half-hour offsets (e.g. Asia/Kolkata) place hour ends off the UTC
# hour. The returned instants are absolute and directly comparable to a tstzrange.
class WorkPackages::JournalTimeline::Ticks
  STEPS = %i[hour day].freeze

  def self.build(...) = new(...).build

  def initialize(from:, to:, step:, zone: Time.zone)
    raise ArgumentError, "step must be one of #{STEPS.join(', ')}" unless step.in?(STEPS)

    @zone = zone
    @step = step
    @from = from.in_time_zone(zone)
    @to = to.in_time_zone(zone)
  end

  attr_reader :from, :to, :step, :zone

  def build
    return [] if from > to

    ticks = [from]

    cursor = period_end_after(from)
    while cursor < to
      ticks << cursor
      cursor = period_end_after(cursor)
    end

    (ticks << to).uniq.map(&:utc)
  end

  private

  # The end of the period +time+ falls into, or the next one when +time+ already sits on it.
  # Advancing by the step in +zone+ keeps DST correct: a spring-forward day yields 23 hourly
  # ticks and a fall-back day 25, while day ends stay at local midnight either way.
  def period_end_after(time)
    end_of_period = time.public_send(:"end_of_#{step}")

    return end_of_period if end_of_period > time

    (time + 1.public_send(step)).public_send(:"end_of_#{step}")
  end
end
