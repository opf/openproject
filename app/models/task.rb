class Task < Issue
    unloadable
    
    def self.tracker
        task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
        return nil if task_tracker.nil? or task_tracker == ''
        return Integer(task_tracker)
    end

    # assumes the task is already under the same story as 'id'
    def move_after(id)
      if id.nil? || id.empty?
        sib = self.siblings
        move_to_left_of sib[0].id if sib.any?
      else
        move_to_right_of id
      end
    end
end
