class Task < Issue
    unloadable
    
    def self.tracker
        task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
        return nil if task_tracker.nil? or task_tracker == ''
        return Integer(task_tracker)
    end
end
