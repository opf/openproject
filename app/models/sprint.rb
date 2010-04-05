require 'date'

class Sprint < Version
    unloadable

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
        return stories.sum('story_points')
    end
   
    def wiki_page
        if ! project.wiki
            return ''
        end

        if wiki_page_title.nil? || wiki_page_title.blank?
            self.update_attribute(:wiki_page_title, name.gsub(/\s+/, '_').gsub(/[^_a-zA-Z0-9]/, ''))
        end

        return wiki_page_title
    end

    def days(cutoff = nil)
        # assumes mon-fri are working days, sat-sun are not. this
        # assumption is not globally right, we need to make this configurable.
        cutoff = self.effective_date if cutoff.nil?
        return (self.sprint_start_date .. self.effective_date).select {|d| (d.wday > 0 and d.wday < 6) }
    end

    def burndown
        return nil if self.effective_date.nil? or self.sprint_start_date.nil?

        end_date = self.effective_date > Date.today ? Date.today : self.effective_date

        so_far = self.days(end_date)

        cached = {}

        BurndownDay.find(:all, :order=>'created_at', :conditions => ["version_id = ?", self.id]).each {|data|
            day = data.created_at.to_date

            next if day > end_date or day < self.sprint_start_date

            cached[day] = {
                            :points_committed => data.points_committed,
                            :points_resolved => data.points_resolved,
                            :points_accepted => data.points_accepted,
                            :remaining_hours => data.remaining_hours
                         }
        }

        backlog = nil
        remaining_days = so_far.length
        datapoints = []
        max_points = 0
        max_hours = 0

        so_far.each { |day|
            if cached.has_key?(day)
                datapoint = cached[day]
            else
                if day == self.sprint_start_date or day == end_date
                    backlog = backlog.nil? ? self.stories : backlog

                    # no stories, nothing to do
                    break if backlog.length == 0

                    datapoint = {
                        :points_committed => backlog.inject(0) {|sum, story| sum + story.story_points.to_f } ,
                        :points_resolved => backlog.select {|s| s.done_ratio == 100 }.inject(0) {|sum, story| sum + story.story_points.to_f },
                        :points_accepted => backlog.select {|s| s.closed? }.inject(0) {|sum, story| sum + story.story_points.to_f },
                    }
                    # start of sprint
                    if day == self.sprint_start_date
                        datapoint[:remaining_hours] = backlog.inject(0) {|sum, story| sum + story.estimated_hours.to_f } 
                    else
                        datapoint[:remaining_hours] = backlog.select {|s| not s.closed? && s.done_ratio != 100 }.inject(0) {|sum, story| sum + story.remaining_hours.to_f } 
                    end

                    bdd = BurndownDay.new datapoint.merge(:created_at => day, :updated_at => day, :version_id => self.id)
                    bdd.save!
                else
                    # we should never get here.
                    # for some reason the burndown wasn't generated on
                    # the specified day, return the last known values
                    # I don't save these because they're a) cheap to
                    # regenerate, and b) not actual measurements
                    datapoint = datapoints[-1].dup
                end
            end

            if datapoint[:points_committed].class == NilClass or datapoint[:points_resolved].class == NilClass
                datapoint[:required_burn_rate_points] = nil
            else
                datapoint[:required_burn_rate_points] = (datapoint[:points_committed] - datapoint[:points_resolved]) / remaining_days
            end

            max_points = [max_points, datapoint[:points_committed]].max
            max_hours = [max_hours, datapoint[:remaining_hours]].max

            if datapoint[:remaining_hours].class == NilClass
                datapoint[:required_burn_rate_hours] = nil
            else
                datapoint[:required_burn_rate_hours] = datapoint[:remaining_hours] / remaining_days
            end

            datapoints << datapoint
            remaining_days -= 1
        }

        datasets = {}
        [       [:points_committed, :points],
                [:points_resolved, :points],
                [:points_accepted, :points],
                [:remaining_hours, :hours],
                [:required_burn_rate_points, :points],
                [:required_burn_rate_hours, :hours]].each { |series, units|
            data = datapoints.collect {|d| d[series]}
            if not data.select{|d| d != 0}.empty?
                datasets[series] = { :units => units, :series => data }
            end
        }

        return { :dates => self.days, :series => datasets, :max => {:points => max_points, :hours => max_hours} }
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

end
