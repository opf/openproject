class Story < Issue
    unloadable

    named_scope :product_backlog, lambda { |project|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and project_id = ? and tracker_id in (?) and fixed_version_id is NULL", #and status_id in (?)",
                project.id, Story.trackers #, IssueStatus.find(:all, :conditions => ["is_closed = ?", false]).collect {|s| "#{s.id}" }
                ]
        }
    }

    named_scope :sprint_backlog, lambda { |sprint|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and tracker_id in (?) and fixed_version_id = ?",
                Story.trackers, sprint.id
                ]
        }
    }
    
    def self.trackers
        trackers = Setting.plugin_redmine_backlogs[:story_trackers]
        return [] if trackers == '' or trackers.nil?

        return trackers.map { |tracker| Integer(tracker) }
    end

    def set_points(p)
        self.init_journal(User.current)

        if p.nil? || p == '' || p == '-'
            self.update_attribute(:story_points, nil)
            return
        end

        if p.downcase == 's'
            self.update_attribute(:story_points, 0)
            return
        end

        p = Integer(p)
        if p >= 0
            self.update_attribute(:story_points, p)
            return
        end
    end

    def points_display(notsized='-')
        if story_points.nil?
            return notsized
        end

        if story_points == 0
            return 'S'
        end

        return story_points.to_s
    end

    def task_status
        closed = 0
        open = 0
        self.descendants.each {|task|
            if task.closed?
                closed += 1
            else
                open += 1
            end
        }
        return {:open => open, :closed => closed}
    end
end
