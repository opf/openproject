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

# A set of work package journals measured over a ChartWindow's ticks, as the ChartPoints a chart
# draws. What is measured is the caller's: +counts+ for how many there were, +sums+ for what they
# held.
#
# Every tick gets a point. A tick the query returned nothing for measured zero rather than
# nothing at all, which is what keeps a series dense enough for the chart to step between its
# points rather than interpolate across the gaps.
#
# The journals are what each chart filters for itself; the window, the viewer and the zero
# filling are what they must do alike.
module Sprints
  class ChartSeries
    def initialize(window:, user:)
      @window = window
      @user = user
    end

    def counts(journals)
      points(timeline(journals).group(:tick).count)
    end

    def sums(journals, column)
      points(timeline(journals).group(:tick).sum(column))
    end

    private

    attr_reader :window, :user

    delegate :ticks, to: :window

    # The grouped keys come back as the database's own instants rather than as the ticks that
    # were asked for, so the two are matched by the second they fall on.
    def points(aggregates)
      measured = aggregates.transform_keys(&:to_i)

      ticks.map { ChartPoint.new(at: it, value: (measured[it.to_i] || 0).to_f) }
    end

    def timeline(journals)
      WorkPackages::JournalTimeline.new(journals, ticks:, user:).relation
    end
  end
end
