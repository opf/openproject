class Burndown
  unloadable

  def initialize(sprint, project, burn_direction = nil)
    burn_direction ||= Setting.plugin_openproject_backlogs["points_burn_direction"]

    @sprint_id = sprint.id

    make_date_series sprint

    series_data = OpenProject::Backlogs::Burndown::SeriesRawData.new(project,
                                                                     sprint,
                                                                     :points => ["story_points"])

    series_data.collect

    calculate_series series_data

    determine_max
  end

  attr_reader :days
  attr_reader :sprint_id
  attr_reader :max

  attr_reader :story_points
  attr_reader :story_points_ideal

  def series(select = :active)
    @available_series
  end

  private

  def make_date_series sprint
    @days = sprint.days
  end

  def calculate_series series_data
    series_data.collect_names.each do |c|
      # need to differentiate between hours and sp
      make_series c.to_sym, series_data.unit_for(c), series_data[c].to_a.sort_by{ |a| a.first }.collect(&:last)
    end

    calculate_ideals(series_data)
  end

  def calculate_ideals(data)
    (["story_points"] & data.collect_names).each do |ideal|
      calculate_ideal(ideal, data.unit_for(ideal))
    end
  end

  def calculate_ideal(name, unit)
    max = self.send(name).first || 0.0
    delta = max / (self.days.size - 1)

    ideal = []
    days.each_with_index do |d, i|
      ideal[i] = max - delta * i
    end

    make_series name.to_s + "_ideal", unit, ideal
  end

  def make_series(name, units, data)
    @available_series ||= {}
    s = OpenProject::Backlogs::Burndown::Series.new(data, name, units)
    @available_series[name] = s
    instance_variable_set("@#{name}", s)
  end

  def determine_max
    @max = {
      :points => @available_series.values.select{|s| s.unit == :points}.flatten.compact.max || 0.0,
      :hours => @available_series.values.select{|s| s.unit == :hours}.flatten.compact.max || 0.0
    }
  end

  def to_h(keys, values)
    return Hash[*keys.zip(values).flatten]
  end

  def workday_before(date = Date.today)
    d = date - 1
    #TODO: make weekday configurable
    d = workday_before(d) unless (d.wday > 0 and d.wday < 6)
    d
  end
end
