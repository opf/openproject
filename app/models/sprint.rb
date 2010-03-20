class Sprint < Version
    unloadable

    named_scope :open_sprints, lambda { |project|
        {
            :order => 'start_date ASC, effective_date ASC',
            :conditions => [ "status = 'open' and project_id = ?", project.id ]
        }
    }

    def stories
        return Story.sprint_backlog(self)
    end
   
end
