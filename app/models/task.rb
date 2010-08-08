class Task < Issue
  unloadable

  def self.create_with_relationships(params, user_id, project_id)
    attribs = params.clone.delete_if {|k,v| !Task::SAFE_ATTRIBUTES.include?(k) }
    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?
    attribs['author_id'] = user_id
    attribs['tracker_id'] = Task.tracker
    attribs['project_id'] = project_id

    task = new(attribs)

    if task.validate_blocks_list(params[:blocks]) && task.save
      task.move_after params[:prev]
      task.update_blocked_list params[:blocks].split(/\D+/)
    end

    task
  end

  def self.tracker
    task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
    return nil if task_tracker.nil? or task_tracker == ''
    return Integer(task_tracker)
  end

  def update_with_relationships(params)
    attribs = params.clone.delete_if {|k,v| !Task::SAFE_ATTRIBUTES.include?(k) }
    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    if validate_blocks_list(params[:blocks]) && result = journalized_update_attributes!(attribs)
      move_after params[:prev]
      update_blocked_list params[:blocks].split(/\D+/)
      result
    else
      false
    end
  end
  
  def update_blocked_list(for_blocking)
    # Existing relationships not in for_blocking should be removed from the 'blocks' list
    relations_from.find(:all, :conditions => "relation_type='blocks'").each{ |ir| 
      ir.destroy unless for_blocking.include?( ir[:issue_to_id] )
    }

    already_blocking = relations_from.find(:all, :conditions => "relation_type='blocks'").map{|ir| ir.issue_to_id}

    # Non-existing relationships that are in for_blocking should be added to the 'blocks' list
    for_blocking.select{ |id| !already_blocking.include?(id) }.each{ |id|
      ir = relations_from.new(:relation_type=>'blocks')
      ir[:issue_to_id] = id
      ir.save!
    }
    reload
  end
  
  def validate_blocks_list(list)
    if list.split(/\D+/).length==0
      errors.add "blocks", "must contain at least one valid id"
      false
    else
      true
    end
  end
  
end
