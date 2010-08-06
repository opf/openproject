module StoriesHelper
  unloadable
  
  def assignee_id_or_empty(story)
    story.new_record? ? "" : story.assigned_to_id
  end

  def assignee_name_or_empty(story)
    story.nil? || story.assigned_to.nil? ? "" : "#{story.assigned_to.firstname} #{story.assigned_to.lastname}"
  end

  def description_or_empty(story)
    story.new_record? ? "" : textilizable(story, :description)
  end

  def mark_if_closed(story)
    !story.new_record? && story.status.is_closed? ? "closed" : ""
  end

  def story_points_or_empty(story)
    story.story_points.nil? ? "" : story.story_points
  end

  def record_id_or_empty(story)
    story.new_record? ? "" : story.id
  end

  def issue_link_or_empty(story)
    story.new_record? ? "" : link_to(story.id, {:controller => "issues", :action => "show", :id => story}, {:target => "_blank", :class => "prevent_edit"})
  end

  def status_id_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").id : story.status.id
  end

  def status_label_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").name : story.status.name
  end

  def story_html_id_or_empty(story)
    story.new_record? ? "" : "story_#{story.id}"
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
  
  def updated_on_with_milliseconds(story)
    date_string_with_milliseconds(story.updated_on, 0.001);
  end

  def date_string_with_milliseconds(d, add=0)
    d.strftime("%B %d, %Y %H:%M:%S") + '.' + (d.to_f % 1 + add).to_s.split('.')[1]
  end
end