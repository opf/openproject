require 'date'

class Task < Issue
  unloadable

  def self.tracker
    task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]
    return nil if task_tracker.blank?
    return Integer(task_tracker)
  end

  def self.create_with_relationships(params, user_id, project_id, is_impediment = false)
    task = new

    task.author_id  = user_id
    task.project_id = project_id
    task.tracker_id = Task.tracker

    task.safe_attributes = params
    task.remaining_hours = 0 if IssueStatus.find(params[:status_id]).is_closed?

    valid_relationships = if is_impediment
                            task.validate_blocks_list(params[:blocks])
                          else
                            true
                          end

    if valid_relationships && task.save
      task.move_after params[:prev]
      task.update_blocked_list params[:blocks].split(/\D+/) if params[:blocks]
    end

    return task
  end

  # TODO: there's an assumption here that impediments always have the
  # task-tracker as their tracker.
  def self.find_all_updated_since(since, project_id, find_impediments = false)
    find(:all,
         :conditions => ["project_id = ? AND updated_on > ? AND tracker_id in (?) and parent_id IS #{ find_impediments ? '' : 'NOT' } NULL", project_id, Time.parse(since), tracker],
         :order => "updated_on ASC")
  end

  def self.tasks_for(story_id)
    tasks = []
    Task.find(:all,
              :conditions => ['tracker_id = ? and not parent_id is NULL and root_id = ?', Task.tracker, story_id],
              :order => :lft
              ).each_with_index {|task, i|
      task.rank = i + 1
      tasks << task
    }
    return tasks
  end

  def update_with_relationships(params, is_impediment = false)
    attribs = params.clone.delete_if { |k, v| !safe_attribute_names.include?(k) }

    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    valid_relationships = if is_impediment && params[:blocks] #if blocks param was not sent, that means the impediment was just dragged
                            validate_blocks_list(params[:blocks])
                          else
                            true
                          end

    if valid_relationships && result = journalized_update_attributes!(attribs)
      move_after params[:prev]
      update_blocked_list params[:blocks].split(/\D+/) if params[:blocks]
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
      errors.add :blocks, :must_have_comma_delimited_list
      false
    else
      true
    end
  end

  # assumes the task is already under the same story as 'id'
  def move_after(id)
    id = nil if id.respond_to?('blank?') && id.blank?
    if id.nil?
      sib = self.siblings
      move_to_left_of sib[0].id if sib.any?
    else
      move_to_right_of id
    end
  end

  def rank=(r)
    @rank = r
  end

  def rank
    @rank ||= Issue.count(:conditions => ['tracker_id = ? and not parent_id is NULL and root_id = ? and lft <= ?', Task.tracker, story_id, self.lft])
    return @rank
  end
end
