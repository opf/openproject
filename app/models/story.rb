class Story < Issue
    unloadable

    acts_as_list :scope => :project

    def self.condition(project_id, sprint_id, extras=[])
      if sprint_id.nil?  
        c = ["
          project_id = ?
          and tracker_id in (?)
          and fixed_version_id is NULL
          and is_closed = ?", project_id, Story.trackers, false]
      else
        c = ["
          project_id = ?
          and tracker_id in (?)
          and fixed_version_id = ?",
          project_id, Story.trackers, sprint_id]
      end

      if extras.size > 0
        c[0] += ' ' + extras.shift
        c += extras
      end

      return c
    end

    # this forces NULLS-LAST ordering
    ORDER = 'case when issues.position is null then 1 else 0 end ASC, case when issues.position is NULL then issues.id else issues.position end ASC'

    def self.backlog(project_id, sprint_id, options={})
      stories = []


      Story.find(:all,
            :order => Story::ORDER,
            :conditions => Story.condition(project_id, sprint_id),
            :joins => :status,
            :limit => options[:limit]).each_with_index {|story, i|
        story.rank = i + 1
        stories << story
      }

      return stories
    end

    def self.product_backlog(project, limit=nil)
      return Story.backlog(project.id, nil, :limit => limit)
    end

    def self.sprint_backlog(sprint, options={})
      return Story.backlog(sprint.project.id, sprint.id, options)
    end

    def self.create_and_position(params)
      attribs = params.select{|k,v| k != 'prev_id' and k != 'id' and Story.column_names.include? k }
      attribs = Hash[*attribs.flatten]
      s = Story.new(attribs)
      s.move_after(params['prev_id']) if s.save!
      return s
    end

    def self.find_all_updated_since(since, project_id)
      find(:all,
           :conditions => ["project_id = ? AND updated_on > ? AND tracker_id in (?)", project_id, Time.parse(since), trackers],
           :order => "updated_on ASC")
    end

    def self.trackers
        trackers = Setting.plugin_redmine_backlogs[:story_trackers]
        return [] if trackers.blank?

        return trackers.map { |tracker| Integer(tracker) }
    end

    def tasks
      return Task.tasks_for(self.id)
    end

    def move_after(prev_id)
      # remove so the potential 'prev' has a correct position
      remove_from_list

      begin
        prev = self.class.find(prev_id)
      rescue ActiveRecord::RecordNotFound
        prev = nil
      end

      # if it's the first story, move it to the 1st position
      if prev.blank?
        insert_at
        move_to_top

      # if its predecessor has no position (shouldn't happen), make it
      # the last story
      elsif !prev.in_list?
        insert_at
        move_to_bottom

      # there's a valid predecessor
      else
        insert_at(prev.position + 1)
      end
    end

    def set_points(p)
        self.init_journal(User.current)

        if p.blank? || p == '-'
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
        # For reasons I have yet to uncover, activerecord will
        # sometimes return numbers as Fixnums that lack the nil?
        # method. Comparing to nil should be safe.
        return notsized if story_points == nil || story_points.blank?
        return 'S' if story_points == 0
        return story_points.to_s
    end

    def task_status
        closed = 0
        open = 0
        self.tasks.each {|task|
            if task.closed?
                closed += 1
            else
                open += 1
            end
        }
        return {:open => open, :closed => closed}
    end

    def update_and_position!(params)
      attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
      attribs = Hash[*attribs.flatten]
      result = journalized_update_attributes attribs
      if result and params[:prev]
        move_after(params[:prev])
      end
      result
    end

  def rank=(r)
    @rank = r
  end

  def rank
    if self.position.blank?
      extras = ['and ((issues.position is NULL and issues.id <= ?) or not issues.position is NULL)', self.id]
    else
      extras = ['and not issues.position is NULL and issues.position <= ?', self.position]
    end

    @rank ||= Issue.count(:conditions => Story.condition(self.project.id, self.fixed_version_id, extras), :joins => :status)

    return @rank
  end

  def self.at_rank(project_id, sprint_id, rank)
    return Story.find(:first,
                      :order => Story::ORDER,
                      :conditions => Story.condition(project_id, sprint_id),
                      :joins => :status,
                      :limit => 1,
                      :offset => rank - 1)
  end
end
