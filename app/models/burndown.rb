class Burndown
  unloadable

  class Series < Array
    def initialize(*args)
      @units = args.pop
      @name = args.pop
      @display = true

      raise "Unsupported unit '#{@units}'" unless [:points, :hours].include? @units
      raise "Name '#{@name}' must be a symbol" unless @name.is_a?  Symbol
      super(*args)
    end

    attr_reader :units
    attr_reader :name
    attr_accessor :display
  end

  def initialize(sprint, project, burn_direction = nil)
    burn_direction ||= Setting.plugin_redmine_backlogs[:points_burn_direction]

    @sprint_id = sprint.id

    days = make_date_series sprint

    collect = [:remaining_hours]

    series_data = collect_for_series(sprint, project, collect)

    calculate_series collect, series_data

    determine_max
  end

  attr_reader :days
  attr_reader :sprint_id
  attr_reader :max

  attr_reader :points_committed
  attr_reader :points_resolved
  attr_reader :points_accepted
  attr_reader :remaining_hours
  attr_reader :ideal
  attr_reader :points_to_resolve
  attr_reader :points_to_accept
  attr_reader :required_burn_rate_points
  attr_reader :required_burn_rate_hours

  def series(select = :active)
    @available_series.values.select{|s| (select == :all) || s.display }.sort{|x,y| "#{x.name}" <=> "#{y.name}"}
  end

  private

  def make_date_series sprint
    @days = sprint.days
  end

  def collect_for_series(sprint, project, collect)
    stories = sprint.stories(project) # TODO: also have to look for stories that have been moved between sprints

    days = sprint.days(nil)
    collected_days = days.sort.select{ |d| d <= Date.today }

    series_data = {}
    collect.each do |c|
      series_data[c] = {}

      collected_days.each do |day|
        series_data[c][day] = 0
      end
    end

    stories.each do |story|
      changes = last_changes_on_value_per_day story, collect

      changes.each_pair do |attribute, values_by_day|
        collected_days.each do |day|

          valued_day = values_by_day[day] ? day : values_by_day.keys.sort.select{ |d| d < day }.last

          series_data[attribute.to_sym][day] += values_by_day[valued_day].to_f
        end
      end
    end

    series_data
  end

  def last_changes_on_value_per_day(story, collect)
    changes = {}
    collect.each do |c|
      changes[c.to_s] = {}
    end

    days_with_change = story.journals.group_by{ |j| j.created_on.to_date }

    days_with_change.each_pair do |date, journals|
      journals.sort_by{ |j| j.created_on }.each do |journal| #by that, we only take the last value of the day
        journal.details.each do |d|
          changes[d.prop_key][date] = d.value if changes.keys.include?(d.prop_key)
        end
      end
    end

    collect.each do |c|
      changes[c.to_s][story.created_on.to_date] = story.send(c) if changes[c.to_s].nil?
    end

    changes
  end

  def calculate_series collect, series_data
    collect.each do |c|
      make_series c, :hours, series_data[c].to_a.sort_by{ |a| a.first}.collect(&:last) #need to differentiate between hours and sp
    end

    calculate_ideals(collect)
  end

  def calculate_ideals(collect)
    if collect.include?(:remaining_hours)
      max = self.remaining_hours.first
      delta = max / (self.days.size - 1)

      ideal = []
      days.each_with_index do |d, i|
        ideal[i] = max - delta * i
      end

      make_series :ideal, :hours, ideal
    end
  end

  def load_from_cache(_series, sprint)
    day_index = to_h(days, (0..(days.size - 1)).to_a)
    BurndownDay.find(:all, :order=>'created_at', :conditions => ["version_id = ?", sprint.id]).each {|data|
      day = day_index[data.created_at.to_date]
      next if !day

      _series[day] = [data.points_committed.to_f, data.points_resolved.to_f, data.points_accepted.to_f, data.remaining_hours.to_f]
    }
  end


  def make_series(name, units, data)
    @available_series ||= {}
    s = Burndown::Series.new(data, name, units)
    @available_series[name] = s
    instance_variable_set("@#{name}", s)
  end

  def determine_max
    @max = {
      :points => @available_series.values.select{|s| s.units == :points}.flatten.compact.max || 0.0,
      :hours => @available_series.values.select{|s| s.units == :hours}.flatten.compact.max || 0.0
    }
  end

  def to_h(keys, values)
    return Hash[*keys.zip(values).flatten]
  end

  def workday_before(date = Date.today)
    d = date - 1
    d = workday_before(d) unless (d.wday > 0 and d.wday < 6) #TODO: make wday configurable
    d
  end
end
