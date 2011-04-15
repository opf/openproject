class Burndown
  unloadable

  class Series < Array
    def initialize(*args)
      @unit = args.pop
      @name = args.pop.to_sym
      @display = true

      raise "Unsupported unit '#{@unit}'" unless [:points, :hours].include? @unit
      super(*args)
    end

    attr_reader :unit
    attr_reader :name
    attr_accessor :display
  end

  class SeriesRawData < Hash
    def initialize(*args)
      @collect = args.pop
      super(*args)
    end

    attr_reader :collect

    def collect_names
      @names ||= @collect.to_a.collect(&:last).flatten
    end

    def unit_for name
      return :hours if @collect[:hours].include? name.to_sym
      return :points if @collect[:points].include? name.to_sym
    end

    def collect(sprint, project)
      stories = sprint.stories(project) # TODO: also have to look for stories that have been moved between sprints

      days = sprint.days(nil)
      collected_days = days.sort.select{ |d| d <= Date.today }

      collect_names.each do |c|
        self[c] = {}

        collected_days.each do |day|
          self[c][day] = 0
        end
      end

      stories.each do |story|
        journals_a = story.journals.to_a.sort_by{ |j| j.created_on }

        prop_set_on = {}
        current_prop_value = {}

        collect_names.each do |c|
          prop_set_on[c] = story.created_on.to_date < collected_days.first ? collected_days.first : story.created_on.to_date
          current_prop_value[c] = story.send(c).to_f
        end

        journals_a.each do |journal|
          journal.details.select{|d| collect_names.include?(d.prop_key.to_sym) }.each do |detail|

            current_prop_value[detail.prop_key.to_sym] = detail.value.to_f

            next if prop_set_on[detail.prop_key.to_sym] == journal.created_on.to_date

            collected_days.select{|d| d < journal.created_on.to_date}.each do |date|
              self[detail.prop_key.to_sym][date] = 0.0 if self[detail.prop_key.to_sym][date].nil?
              self[detail.prop_key.to_sym][date] += detail.old_value.to_f
            end

            prop_set_on[detail.prop_key.to_sym] = journal.created_on.to_date
          end
        end

        collect_names.each do |c|
          collected_days.select{ |d| d >= prop_set_on[c] }.each do |date|
            self[c][date] = 0.0 if self[c][date].nil?
            self[c][date] += current_prop_value[c]
          end
        end
      end
    end
  end

  def initialize(sprint, project, burn_direction = nil)
    burn_direction ||= Setting.plugin_redmine_backlogs[:points_burn_direction]

    @sprint_id = sprint.id

    days = make_date_series sprint

    series_data = SeriesRawData.new({:hours => [:remaining_hours],
                                     :points => [:story_points]})

    series_data.collect(sprint, project)

    calculate_series series_data

    determine_max
  end

  attr_reader :days
  attr_reader :sprint_id
  attr_reader :max

  attr_reader :remaining_hours
  attr_reader :remaining_hours_ideal

  attr_reader :story_points
  attr_reader :story_points_ideal

  # attr_reader :points_committed
  #   attr_reader :points_resolved
  #   attr_reader :points_accepted
  #   attr_reader :points_to_resolve
  #   attr_reader :points_to_accept
  #   attr_reader :required_burn_rate_points
  #   attr_reader :required_burn_rate_hours

  def series(select = :active)
    @available_series.values.select{|s| (select == :all) || s.display }.sort{|x,y| "#{x.name}" <=> "#{y.name}"}
  end

  private

  def make_date_series sprint
    @days = sprint.days
  end

  def calculate_series series_data
    series_data.collect_names.each do |c|
      make_series c, series_data.unit_for(c), series_data[c].to_a.sort_by{ |a| a.first}.collect(&:last) #need to differentiate between hours and sp
    end

    calculate_ideals(series_data)
  end

  def calculate_ideals(data)
    ([:remaining_hours, :story_points] & data.collect_names).each do |ideal|
      calculate_ideal(ideal, data.unit_for(ideal))
    end
  end

  def calculate_ideal(name, unit)
    max = self.send(name).first
    delta = max / (self.days.size - 1)

    ideal = []
    days.each_with_index do |d, i|
      ideal[i] = max - delta * i
    end

    make_series name.to_s + "_ideal", unit, ideal
  end

  def make_series(name, units, data)
    @available_series ||= {}
    s = Burndown::Series.new(data, name, units)
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
    d = workday_before(d) unless (d.wday > 0 and d.wday < 6) #TODO: make wday configurable
    d
  end
end
