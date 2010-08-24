class Story < Issue
    unloadable

    def self.product_backlog(project, limit=nil)
      return Story.find(:all,
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and project_id = ? and tracker_id in (?) and fixed_version_id is NULL", #and status_id in (?)",
                project.id, Story.trackers #, IssueStatus.find(:all, :conditions => ["is_closed = ?", false]).collect {|s| "#{s.id}" }
                ],
            :limit => limit)
    end

    named_scope :sprint_backlog, lambda { |sprint|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and tracker_id in (?) and fixed_version_id = ?",
                Story.trackers, sprint.id
                ]
        }
    }

    def self.create_and_position(params)
      attribs = params.select{|k,v| k != 'prev_id' and k != 'id' and Story.column_names.include? k }
      attribs = Hash[*attribs.flatten]
      position = (params['prev_id']=='' or params['prev_id'].nil?) ? 1 : (Story.find(params['prev_id']).position + 1)
      s = Story.new(attribs)
      s.move_after(params['prev_id']) if s.save!
      return s
    end

    def self.trackers
        trackers = Setting.plugin_redmine_backlogs[:story_trackers]
        return [] if trackers == '' or trackers.nil?

        return trackers.map { |tracker| Integer(tracker) }
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
      if prev.nil?
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
        # For reasons I have yet to uncover, activerecord will
        # sometimes return numbers as Fixnums that lack the nil?
        # method. Comparing to nil should be safe.
        return notsized if story_points == nil
        return 'S' if story_points == 0
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

    def update_and_position!(params)
      attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
      attribs = Hash[*attribs.flatten]
      result = journalized_update_attributes! attribs
      if result and params[:prev]
        move_after(params[:prev])
      end
      result
    end
end
