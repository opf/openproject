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
      @sprint = args.pop
      @project = args.pop
      super(*args)
    end

    attr_reader :collect
    attr_reader :sprint
    attr_reader :project

    def collect_names
      @names ||= @collect.to_a.collect(&:last).flatten
    end

    def out_names
      @out_names ||= ["project_id", "fixed_version_id", "tracker_id"]
    end

    def unit_for name
      return :hours if @collect[:hours].include? name
      return :points if @collect[:points].include? name
    end

    def collect()
      stories = Story.find(:all, :include => {:journals => :details},
                           :conditions => ["(issues.fixed_version_id = ? OR (journal_details.prop_key = 'fixed_version_id' AND (journal_details.old_value = ? OR journal_details.value = ?))) " +
                                           " AND (issues.project_id = ? OR (journal_details.prop_key = 'project_id' AND (journal_details.old_value = ? OR journal_details.value = ?))) " +
                                           " AND (issues.tracker_id in (?) OR (journal_details.prop_key = 'tracker_id' AND (journal_details.old_value in (?) OR journal_details.value in (?))))",
                                           sprint.id, sprint.id, sprint.id, project.id, project.id, project.id, Story.trackers, Story.trackers, Story.trackers])

      days = sprint.days(nil)
      collected_days = days.sort.select{ |d| d <= Date.today }

      date_hash = {}
      collected_days.each do |date|
        date_hash[date] = 0.0
      end

      collect_names.each do |c|
        self[c] = date_hash.dup
      end

      stories.each do |story|
        collect_for_story story, collected_days
      end
    end

    def collect_for_story story, collected_days

      details = story.journals.collect(&:details).flatten.select{ |d| collect_names.include?(d.prop_key) || out_names.include?(d.prop_key)}
      details_by_prop = details.group_by{ |d| d.prop_key }

      details_by_prop.each {|key_value| key_value.last.sort_by{ |d| d.journal.created_on } }

      current_prop_index = Hash.new{ |hash, key| hash[key] = details_by_prop[key] ? 0 : nil }

      collected_days.each do |date|
        (out_names + collect_names).each do |key|

          current_prop_index[key] = determine_prop_index(key, date, current_prop_index, details_by_prop)

          unless not_to_be_collected?(key, date, details_by_prop, current_prop_index, story)
            self[key][date] += value_for_prop(date, details_by_prop[key], current_prop_index[key], story.send(key)).to_f
          end
        end
      end
    end

    private

    def determine_prop_index(key, date, current_prop_index, details_by_prop)
      prop_index = current_prop_index[key]

      until prop_index.nil? ||
            details_by_prop[key][prop_index].journal.created_on.to_date > date ||
            prop_index == details_by_prop[key].size - 1

          prop_index += 1
      end

      prop_index
    end

    def not_to_be_collected?(key, date, details_by_prop, current_prop_index, story)
      ((collect_names.include?(key) &&
        (project.id != value_for_prop(date, details_by_prop["project_id"], current_prop_index["project_id"], story.send("project_id")).to_i ||
        sprint.id != value_for_prop(date, details_by_prop["fixed_version_id"], current_prop_index["fixed_version_id"], story.send("fixed_version_id")).to_i ||
        !Story.trackers.include?(value_for_prop(date, details_by_prop["tracker_id"], current_prop_index["tracker_id"], story.send("tracker_id")).to_i))) ||
      ((key == "story_points") && IssueStatus.find(value_for_prop(date, details_by_prop["status_id"], current_prop_index["status_id"], story.send("status_id"))).is_closed) ||
      out_names.include?(key))
    end

    def value_for_prop(date, details, index, default)
      if details.nil?
        value = default
      elsif date < details[index].journal.created_on.to_date
        value = details[index].old_value
      else
        #debugger
        value = details[index].value
      end

      value
    end
  end

  def initialize(sprint, project, burn_direction = nil)
    burn_direction ||= Setting.plugin_redmine_backlogs[:points_burn_direction]

    @sprint_id = sprint.id

    days = make_date_series sprint

    series_data = SeriesRawData.new(project, sprint,
                                   {:hours => ["remaining_hours"], :points => ["story_points"]})
    #
    series_data.collect

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
      make_series c.to_sym, series_data.unit_for(c), series_data[c].to_a.sort_by{ |a| a.first}.collect(&:last) #need to differentiate between hours and sp
    end

    calculate_ideals(series_data)
  end

  def calculate_ideals(data)
    (["remaining_hours", "story_points"] & data.collect_names).each do |ideal|
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
