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
   
    def has_wiki_page
        return false if wiki_page_title.nil? || wiki_page_title.blank?

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

        if wiki_page_title.nil? || wiki_page_title.blank?
            self.update_attribute(:wiki_page_title, Wiki.titleize(self.name))
        end

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

        v = self.project.scrum_statistics
        return nil if ! v or ! v[:days_per_point]

        # assume 5 out of 7 are working days
        return self.start_date + Integer(self.points * v[:days_per_point] * 7.0/5)
    end

    def has_burndown
        return !!(self.effective_date and self.sprint_start_date)
    end

    def activity
        bd = self.burndown('up')
        return false if !bd || !bd[:remaining_hours]

        # assume a sprint is active if it's only 2 days old
        return true if bd[:remaining_hours].size <= 2

        return Issue.exists?(['fixed_version_id = ? and ((updated_on between ? and ?) or (created_on between ? and ?))', self.id, -2.days.from_now, Time.now, -2.days.from_now, Time.now])
    end

    def burndown(burn_direction = nil)
        return nil if not self.has_burndown

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
        remaining_days = self.days.length
        datapoints = []
        max_points = 0
        max_hours = 0

        if remaining_days > 1
            ideal_delta = (1.0 / (remaining_days - 1))
        else
            ideal_delta = 0
        end
        ideal_factor = 0

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
                    datapoint = (datapoints.length > 0 ? datapoints[-1].dup : {})
                end
            end

            if datapoint[:points_committed].class == NilClass or datapoint[:points_resolved].class == NilClass
                datapoint[:required_burn_rate_points] = nil
            else
                datapoint[:required_burn_rate_points] = (datapoint[:points_committed] - datapoint[:points_resolved]) / remaining_days
            end

            max_points = [max_points, datapoint[:points_committed]].compact.max
            max_hours = [max_hours, datapoint[:remaining_hours]].compact.max

            if datapoint[:remaining_hours].class == NilClass
                datapoint[:required_burn_rate_hours] = nil
            else
                datapoint[:required_burn_rate_hours] = datapoint[:remaining_hours] / remaining_days
            end

            datapoint[:ideal] = datapoint[:points_committed] * ideal_factor if datapoint[:points_committed]

            datapoints << datapoint

            remaining_days -= 1
            ideal_factor += ideal_delta
        }

        units = {
            :points_committed => :points,
            :points_resolved => :points,
            :points_accepted => :points,
            :points_to_accept => :points,
            :points_to_resolve => :points,
            :ideal => :points,
            :remaining_hours => :hours,
            :required_burn_rate_points => :points,
            :required_burn_rate_hours => :hours
        }
        datasets = {}
        [:points_committed, :points_resolved, :points_accepted, :ideal, :remaining_hours, :required_burn_rate_points, :required_burn_rate_hours].each {|series|
            data = datapoints.collect {|d| d[series]}
            if not data.select{|d| d != 0 and not d.class == NilClass }.empty?
                datasets[series] = data
            end
        }

        burn_direction ||= Setting.plugin_redmine_backlogs[:points_burn_direction]
        if burn_direction == 'down'
            if datasets[:points_committed]
                if datasets.include? :ideal
                    if datasets[:points_committed]
                        datasets[:ideal] = datasets[:ideal].zip(datasets[:points_committed]).collect{|d, c| c - d}
                    else
                        datasets.delete(:ideal)
                    end
                end

                [[:points_accepted, :points_to_accept], [:points_resolved, :points_to_resolve]].each{|src, tgt|
                    next if not datasets.include? src

                    datasets[tgt] = datasets[src].zip(datasets[:points_committed]).collect{|d, c| c - d} if datasets[:points_committed]
                }
            end

            # only show points committed if they're not constant
            datasets.delete(:points_committed) if datasets[:points_committed] and datasets[:points_committed].collect{|d| d != datasets[:points_committed][0]}.empty?
            datasets.delete(:points_resolved)
            datasets.delete(:points_accepted)
        end

        # clear overlap between accepted/resolved
        [[:points_resolved, :points_accepted], [:points_to_resolve, :points_to_accept]].each{|r, a|
            datasets.delete(r) if datasets.has_key? r and datasets.has_key? a and datasets[a] == datasets[r]
        }

        return { :dates => self.days, :series => datasets, :units => units, :max => {:points => max_points, :hours => max_hours} }
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
                        self.id]).sort {|a,b| a.closed? == b.closed? ?  a.updated_on <=> b.updated_on : (a.closed? ? 1 : -1) }
    end

end
