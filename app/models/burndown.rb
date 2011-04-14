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

    _series = ([nil] * days.size)

    collect = [:remaining_hours]

    series_data = collect_for_series(sprint, project, collect)

    collect.each do |c|
      make_series c, :hours, series_data[c].to_a.sort_by{ |a| a.first}.collect(&:last) #need to differentiate between hours and sp
    end

    # load cache
    #load_from_cache(_series, sprint)

    #calculate_last_and_first_day(sprint, project, _series)

    # fill out series
    #last = nil
    #_series = _series.enum_for(:each_with_index).collect{|v, i| v.nil? ? last : (last = v; v) }

    # make registered series
    #points_committed, points_resolved, points_accepted, remaining_hours = _series.transpose
    #make_series :points_committed, :points, points_committed
    #make_series :points_resolved, :points, points_resolved
    #make_series :points_accepted, :points, points_accepted
    #make_series :remaining_hours, :hours, remaining_hours

    # calculate burn-up ideal
    #calculate_series_burn_up_ideal(daycount, points_commited)

    # burn-down equivalents to the burn-up chart
    #make_series :points_to_resolve, :points, points_committed.zip(points_resolved).collect{|c, r| c - r}
    #make_series :points_to_accept, :points, points_committed.zip(points_accepted).collect{|c, a| c - a}

    # required burn-rate
    #make_series :required_burn_rate_points, :points, @points_to_resolve.enum_for(:each_with_index).collect{|p, i| p / (daycount - i) }
    #make_series :required_burn_rate_hours, :hours, remaining_hours.enum_for(:each_with_index).collect{|r, i| r / (daycount-i) }

    # mark series to be displayed if they're not constant-zero, or
    # just constant in case of points-committed
    # @available_series.values.each{|s|
    #       const_val = (s.name == :points_committed ? s[0] : 0)
    #       @available_series[s.name].display = (s.select{|v| v != const_val}.size != 0)
    #     }

    # decide whether you want burn-up or down
    #decide_burn_up_or_down burn_direction

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

  def load_from_cache(_series, sprint)
    day_index = to_h(days, (0..(days.size - 1)).to_a)
    BurndownDay.find(:all, :order=>'created_at', :conditions => ["version_id = ?", sprint.id]).each {|data|
      day = day_index[data.created_at.to_date]
      next if !day

      _series[day] = [data.points_committed.to_f, data.points_resolved.to_f, data.points_accepted.to_f, data.remaining_hours.to_f]
    }
  end

  def calculate_last_and_first_day(sprint, project, _series)
    backlog = sprint.stories(project) unless _series[0] && _series[-1]

    # calculate first day if not loaded from cache
    calculate_first_day(backlog, days[0], _series) unless _series[0]

    # calculate last day if not loaded from cache
    calculate_last_day(backlog, days[-1], _series) unless _series[-1]
  end

  def calculate_first_day(backlog, first_day, _series)
    assume = (first_day != Date.today)

    _series[0] = [
      backlog.inject(0) {|sum, story| sum + story.story_points.to_f }, # committed
      (assume ? 0 : backlog.select {|s| s.descendants.select{|t| !t.closed?}.size == 0 }.inject(0) {|sum, story| sum + story.story_points.to_f }),
      (assume ? 0 : backlog.select {|s| s.closed? }.inject(0) {|sum, story| sum + story.story_points.to_f }),
      backlog.inject(0) {|sum, story| sum + story.estimated_hours.to_f } # remaining
    ]
    cache(first_day, _series[0])
  end

  def calculate_last_day(backlog, last_day, _series)
    _series[-1] = [
      backlog.inject(0) {|sum, story| sum + story.story_points.to_f },
      backlog.select {|s| s.descendants.select{|t| !t.closed?}.size == 0}.inject(0) {|sum, story| sum + story.story_points.to_f },
      backlog.select {|s| s.closed? }.inject(0) {|sum, story| sum + story.story_points.to_f },
      backlog.select {|s| not s.closed? && s.descendants.select{|t| !t.closed?}.size != 0}.inject(0) {|sum, story| sum + story.remaining_hours.to_f }
    ]
    cache(last_day, _series[-1])
  end

  def cache(day, datapoint)
    BurndownDay.create! :points_committed => datapoint[0],
                        :points_resolved => datapoint[1],
                        :points_accepted => datapoint[2],
                        :remaining_hours => datapoint[3],
                        :created_at => day,
                        :version_id => @sprint_id
  end

  def calculate_series_burn_up_ideal(daycount, points_commited)
    if daycount == 1 # should never happen
      make_series :ideal, :points, [points_committed]
    else
      make_series :ideal, :points, points_committed.enum_for(:each_with_index).collect{|c, i| c * i * (1.0 / (daycount - 1)) }
    end
  end

  def make_series(name, units, data)
    @available_series ||= {}
    s = Burndown::Series.new(data, name, units)
    @available_series[name] = s
    instance_variable_set("@#{name}", s)
  end

  def decide_burn_up_or_down(burn_direction)
    if burn_direction == 'down'
      @ideal.each_with_index{|v, i| @ideal[i] = @points_committed[i] - v}
      @points_accepted.display = false
      @points_resolved.display = false
      @available_series.delete(:points_accepted)
      @available_series.delete(:points_resolved)
    else
      @points_to_accept.display = false
      @points_to_resolve.display = false
      @available_series.delete(:points_to_accept)
      @available_series.delete(:points_to_resolve)
    end
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
