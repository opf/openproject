class Task < Issue
    unloadable
    acts_as_list :scope => 'parent_id=#{parent_issue_id} AND status_id=#{status_id}'
    
    def self.tracker
        task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
        return nil if task_tracker.nil? or task_tracker == ''
        return Integer(task_tracker)
    end
end
