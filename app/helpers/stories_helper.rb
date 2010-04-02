module StoriesHelper
  unloadable
  
  def assigned_to_id_or_empty(story)
    story.new_record? ? "" : story.assigned_to_id
  end

  def assignee_name_or_empty(story)
    story.nil? || story.assigned_to.nil? ? "" : "#{story.assigned_to.firstname} #{story.assigned_to.lastname}"
  end

  def description_or_empty(story)
    story.new_record? ? "" : textilizable(story, :description)
  end

  def element_id_or_empty(story)
    story.new_record? ? "" : "story_#{story.id}"
  end

  def mark_if_closed(story)
    !story.new_record? && story.issue.status.is_closed? ? "closed" : ""
  end

  def mark_if_task(story)
    story.parent_id == 0 ? "" : "task"
  end

  def one_or_two_line_height(story)
    if story.backlog_id.nil? || story.backlog_id == 0
      maxLength = 50
    else
      maxLength = 65
    end
    story.subject.length > maxLength ? "story_double" : ""
  end

  def points_or_empty(story)
    story.story_points.nil? ? 0 : story.story_points
  end

  def record_id_or_empty(story)
    story.new_record? ? "" : story.id
  end

  def status_id_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").id : story.status.id
  end

  def status_label_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").name : story.status.name
  end

  def textile_description_or_empty(story)
    story.new_record? ? "" : h(story.description).gsub(/&lt;(\/?pre)&gt;/, '<\1>')
  end

  def tracker_id_or_empty(story)
    story.new_record? ? "" : story.tracker_id
  end

  def tracker_name_or_empty(story)
    story.new_record? ? "" : story.tracker.name
  end
end