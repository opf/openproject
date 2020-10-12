#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Burndown
  def initialize(sprint, project, burn_direction = nil)
    @sprint_id = sprint.id

    make_date_series sprint

    series_data = OpenProject::Backlogs::Burndown::SeriesRawData.new(project,
                                                                     sprint,
                                                                     points: ['story_points'])

    series_data.collect_data

    calculate_series series_data

    determine_max
  end

  attr_reader :days
  attr_reader :sprint_id
  attr_reader :max

  attr_reader :story_points
  attr_reader :story_points_ideal

  def series(_select = :active)
    @available_series
  end

  private

  def make_date_series(sprint)
    @days = sprint.days
  end

  def calculate_series(series_data)
    series_data.collect_names.each do |c|
      # need to differentiate between hours and sp
      make_series c.to_sym, series_data.unit_for(c), series_data[c].to_a.sort_by(&:first).map(&:last)
    end

    calculate_ideals(series_data)
  end

  def calculate_ideals(data)
    (['story_points'] & data.collect_names).each do |ideal|
      calculate_ideal(ideal, data.unit_for(ideal))
    end
  end

  def calculate_ideal(name, unit)
    max = send(name).first || 0.0
    delta = max / (days.size - 1)

    ideal = []
    days.each_with_index do |_d, i|
      ideal[i] = max - delta * i
    end

    make_series name.to_s + '_ideal', unit, ideal
  end

  def make_series(name, units, data)
    @available_series ||= {}
    s = OpenProject::Backlogs::Burndown::Series.new(data, name, units)
    @available_series[name] = s
    instance_variable_set("@#{name}", s)
  end

  def determine_max
    @max = {
      points: @available_series.values.select { |s| s.unit == :points }.flatten.compact.reject(&:nan?).max || 0.0,
      hours: @available_series.values.select { |s| s.unit == :hours }.flatten.compact.reject(&:nan?).max || 0.0
    }
  end

  def to_h(keys, values)
    Hash[*keys.zip(values).flatten]
  end

  def workday_before(date = Date.today)
    d = date - 1
    # TODO: make weekday configurable
    d = workday_before(d) unless d.wday > 0 and d.wday < 6
    d
  end
end
