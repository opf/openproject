require 'date'

class Burndown
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

  def initialize(sprint, burn_direction = nil)
    burn_direction = burn_direction || Setting.plugin_redmine_backlogs[:points_burn_direction]

    @days = sprint.days
    @sprint_id = sprint.id

    # end date for graph
    days = @days
    daycount = days.size
    days = sprint.days(Date.today) if sprint.effective_date > Date.today

    _series = ([nil] * days.size)

    # load cache
    day_index = to_h(days, (0..(days.size - 1)).to_a)
    starts = sprint.sprint_start_date
    BurndownDay.find(:all, :order=>'created_at', :conditions => ["version_id = ?", sprint.id]).each {|data|
      day = day_index[data.created_at.to_date]
      next if !day

      _series[day] = [data.points_committed.to_f, data.points_resolved.to_f, data.points_accepted.to_f, data.remaining_hours.to_f]
    }

    backlog = nil

    # calculate first day if not loaded from cache
    if !_series[0]
      assume = (days[0] != Date.today)

      backlog ||= sprint.stories
      _series[0] = [
        backlog.inject(0) {|sum, story| sum + story.story_points.to_f }, # committed
        (assume ? 0 : backlog.select {|s| s.done_ratio == 100 }.inject(0) {|sum, story| sum + story.story_points.to_f }),
        (assume ? 0 : backlog.select {|s| s.closed? }.inject(0) {|sum, story| sum + story.story_points.to_f }),
        backlog.inject(0) {|sum, story| sum + story.estimated_hours.to_f } # remaining
      ]
      cache(days[0], _series[0])
    end

    # calculate last day if not loaded from cache
    if !_series[-1]
      backlog ||= sprint.stories
      _series[-1] = [
        backlog.inject(0) {|sum, story| sum + story.story_points.to_f },
        backlog.select {|s| s.done_ratio == 100 }.inject(0) {|sum, story| sum + story.story_points.to_f },
        backlog.select {|s| s.closed? }.inject(0) {|sum, story| sum + story.story_points.to_f },
        backlog.select {|s| not s.closed? && s.done_ratio != 100 }.inject(0) {|sum, story| sum + story.remaining_hours.to_f } 
      ]
      cache(days[-1], _series[-1])
    end

    # fill out series
    last = nil
    _series = _series.enum_for(:each_with_index).collect{|v, i| v.nil? ? last : (last = v; v) }

    # make registered series
    points_committed, points_resolved, points_accepted, remaining_hours = _series.transpose
    make_series :points_committed, :points, points_committed
    make_series :points_resolved, :points, points_resolved
    make_series :points_accepted, :points, points_accepted
    make_series :remaining_hours, :hours, remaining_hours

    # calculate burn-up ideal
    if daycount == 1 # should never happen
      make_series :ideal, :points, [points_committed]
    else
      make_series :ideal, :points, points_committed.enum_for(:each_with_index).collect{|c, i| c * i * (1.0 / (daycount - 1)) }
    end

    # burn-down equivalents to the burn-up chart
    make_series :points_to_resolve, :points, points_committed.zip(points_resolved).collect{|c, r| c - r}
    make_series :points_to_accept, :points, points_committed.zip(points_accepted).collect{|c, a| c - a}

    # required burn-rate
    make_series :required_burn_rate_points, :points, @points_to_resolve.enum_for(:each_with_index).collect{|p, i| p / (daycount - i) }
    make_series :required_burn_rate_hours, :hours, remaining_hours.enum_for(:each_with_index).collect{|r, i| r / (daycount-i) }

    # mark series to be displayed if they're not constant-zero, or
    # just constant in case of points-committed
    @available_series.values.each{|s|
      const_val = (s.name == :points_committed ? s[0] : 0)
      @available_series[s.name].display = (s.select{|v| v != const_val}.size != 0)
    }

    # decide whether you want burn-up or down
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

    @max = {
      :points => @available_series.values.select{|s| s.units == :points}.flatten.compact.max,
      :hours => @available_series.values.select{|s| s.units == :hours}.flatten.compact.max
    }
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
    return @available_series.values.select{|s| (select == :all) || s.display }.sort{|x,y| "#{x.name}" <=> "#{y.name}"}
  end

  private

  def cache(day, datapoint)
    datapoint = {
      :points_committed => datapoint[0],
      :points_resolved => datapoint[1],
      :points_accepted => datapoint[2],
      :remaining_hours => datapoint[3],
      :created_at => day,
      :version_id => @sprint_id
    }
    bdd = BurndownDay.new datapoint
    bdd.save!
  end

  def make_series(name, units, data)
    @available_series ||= {}
    s = Burndown::Series.new(data, name, units)
    @available_series[name] = s
    instance_variable_set("@#{name}", s)
  end

  def to_h(keys, values)
    return Hash[*keys.zip(values).flatten]
  end

end

class Sprint < Version
    unloadable

    validate :start_and_end_dates

    def start_and_end_dates
        errors.add_to_base("Sprint cannot end before it starts") if self.effective_date && self.sprint_start_date && self.sprint_start_date >= self.effective_date
    end

    named_scope :open_sprints, lambda { |project|
        {
            :order => 'sprint_start_date ASC, effective_date ASC',
            :conditions => [ "status = 'open' and project_id = ?", project.id ]
        }
    }

    def stories
        return Story.sprint_backlog(self)
    end

    def points
        return stories.inject(0){|sum, story| sum + story.story_points.to_i}
    end
   
    def has_wiki_page
        return false if wiki_page_title.blank?

        page = project.wiki.find_page(self.wiki_page_title)
        return false if !page

        template = project.wiki.find_page(Setting.plugin_redmine_backlogs[:wiki_template])
        return false if template && page.text == template.text

        return true
    end

    def wiki_page
        if ! project.wiki
            return ''
        end

        self.update_attribute(:wiki_page_title, Wiki.titleize(self.name)) if wiki_page_title.blank?

        page = project.wiki.find_page(self.wiki_page_title)
        template = project.wiki.find_page(Setting.plugin_redmine_backlogs[:wiki_template])

        if template and not page
            page = WikiPage.new(:wiki => project.wiki, :title => self.wiki_page_title)
            page.content = WikiContent.new
            page.content.text = "h1. #{self.name}\n\n#{template.text}"
            page.save!
        end

        return wiki_page_title
    end

    def days(cutoff = nil)
        # assumes mon-fri are working days, sat-sun are not. this
        # assumption is not globally right, we need to make this configurable.
        cutoff = self.effective_date if cutoff.nil?
        return (self.sprint_start_date .. cutoff).select {|d| (d.wday > 0 and d.wday < 6) }
    end

    def eta
        return nil if ! self.start_date

        dpp = self.project.scrum_statistics.info[:average_days_per_point]
        return nil if !dpp

        # assume 5 out of 7 are working days
        return self.start_date + Integer(self.points * dpp * 7.0/5)
    end

    def has_burndown
        return !!(self.effective_date and self.sprint_start_date)
    end

    def activity
        bd = self.burndown('up')
        return false if !bd

        # assume a sprint is active if it's only 2 days old
        return true if bd.remaining_hours.size <= 2

        return Issue.exists?(['fixed_version_id = ? and ((updated_on between ? and ?) or (created_on between ? and ?))', self.id, -2.days.from_now, Time.now, -2.days.from_now, Time.now])
    end

    def burndown(burn_direction = nil)
        return nil if not self.has_burndown
        @cached_burndown ||= Burndown.new(self, burn_direction)
        return @cached_burndown
    end

    def self.generate_burndown(only_current = true)
        if only_current
            conditions = ["? between sprint_start_date and effective_date", Date.today]
        else
            conditions = "1 = 1"
        end

        Version.find(:all, :conditions => conditions).each { |sprint|
            sprint.burndown
        }
    end

    def impediments
        return Issue.find(:all, 
            :conditions => ["id in (
                            select issue_from_id
                            from issue_relations ir
                            join issues blocked
                                on blocked.id = ir.issue_to_id
                                and blocked.tracker_id in (?)
                                and blocked.fixed_version_id = (?)
                            where ir.relation_type = 'blocks'
                            )",
                        Story.trackers + [Task.tracker],
                        self.id]
            ) #.sort {|a,b| a.closed? == b.closed? ?  a.updated_on <=> b.updated_on : (a.closed? ? 1 : -1) }
    end

end
