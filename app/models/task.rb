require 'date'

class Task < WorkPackage
  unloadable

  extend OpenProject::Backlogs::Mixins::PreventIssueSti

  def self.type
    task_type = Setting.plugin_openproject_backlogs["task_type"]
    task_type.blank? ? nil : task_type.to_i
  end

  # This method is used by Backlogs::List.
  # It ensures, that tasks and stories follow a similar interface
  def self.types
    [self.type]
  end

  def self.create_with_relationships(params, project_id)
    task = new

    task.author = User.current
    task.project_id = project_id
    task.type_id = Task.type

    task.safe_attributes = params

    if task.save
      task.move_after params[:prev]
    end

    return task
  end

  def self.tasks_for(story_id)
    Task.find_all_by_parent_id(story_id, :order => :lft).each_with_index do |task, i|
      task.rank = i + 1
    end
  end

  def status_id=(id)
    super
    self.remaining_hours = 0 if IssueStatus.find(id).is_closed?
  end

  def update_with_relationships(params, is_impediment = false)
    self.safe_attributes = params

    save.tap do |result|
      move_after(params[:prev]) if result
    end
  end

  # assumes the task is already under the same story as 'prev_id'
  def move_after(prev_id)
    if prev_id.blank?
      sib = self.siblings
      move_to_left_of(sib[0].id) if sib.any?
    else
      move_to_right_of(prev_id)
    end
  end

  def rank=(r)
    @rank = r
  end

  def rank
    @rank ||= WorkPackage.count(:conditions => ['type_id = ? and not parent_id is NULL and root_id = ? and lft <= ?', Task.type, story_id, self.lft])
    return @rank
  end
end
