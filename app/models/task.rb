class Task < Issue
  unloadable

  def self.tracker
    task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
    return nil if task_tracker.nil? or task_tracker == ''
    return Integer(task_tracker)
  end

  def update_with_relationships(params)
    attribs = params.clone.delete_if {|k,v| !Task::SAFE_ATTRIBUTES.include?(k) }
    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    if result = journalized_update_attributes!(attribs)
      move_after params[:prev]
      update_blocked_list! params[:blocks].split(/\D+/)
    end
    
    result
  end
  
  def update_blocked_list!(for_blocking)    
    # Existing relationships not in for_blocking should be removed from the 'blocks' list
    relations_from.find(:all, :conditions => "relation_type='blocks'").each{ |ir| 
      ir.destroy unless for_blocking.include?( ir[:issue_to_id] )
    }

    already_blocking = relations_from.find(:all, :conditions => "relation_type='blocks'").map{|ir| ir.issue_to_id}
        
    # Non-existing relationships that are in for_blocking should be added to the 'blocks' list
    for_blocking.select{ |id| !already_blocking.include?(id) }.each{ |id|
      ir = relations_from.new(:relation_type=>'blocks')
      ir['issue_to_id'] = id
      ir.save!
    }
    reload
  end
  
  
end
