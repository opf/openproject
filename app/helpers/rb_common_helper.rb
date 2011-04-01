module RbCommonHelper
  unloadable

  def assignee_id_or_empty(story)
    story.new_record? ? "" : story.assigned_to_id
  end

  def assignee_name_or_empty(story)
    story.blank? || story.assigned_to.blank? ? "" : "#{story.assigned_to.firstname} #{story.assigned_to.lastname}"
  end

  def blocks_ids(ids)
    ids.sort.join(',')
  end

  def build_inline_style(task)
    task.blank? || task.assigned_to.blank? ? '' : "style='background-color:#{task.assigned_to.backlogs_preference(:task_color)}'"
  end

  def breadcrumb_separator
    "<span class='separator'>&gt;</span>"
  end

  def description_or_empty(story)
    story.new_record? ? "" : textilizable(story, :description)
  end

  def id_or_empty(item)
    item.new_record? ? "" : item.id
  end

  def issue_link_or_empty(item)
    item_id = item.id.to_s
    text = (item_id.length > 8 ? "#{item_id[0..1]}...#{item_id[-4..-1]}" : item_id)
    item.new_record? ? "" : link_to(text, {:controller => "issues", :action => "show", :id => item}, {:class => "prevent_edit"})
  end

  def sprint_link_or_empty(item)
    item_id = item.id.to_s
    text = (item_id.length > 8 ? "#{item_id[0..1]}...#{item_id[-4..-1]}" : item_id)
    item.new_record? ? "" : link_to(text, {:controller => "sprint", :action => "show", :id => item}, {:class => "prevent_edit"})
  end

  def mark_if_closed(story)
    !story.new_record? && story.status.is_closed? ? "closed" : ""
  end

  def story_points_or_empty(story)
    story.story_points.blank? ? "" : story.story_points
  end

  def record_id_or_empty(story)
    story.new_record? ? "" : story.id
  end

  def sprint_status_id_or_default(sprint)
    sprint.new_record? ? Version::VERSION_STATUSES.first : sprint.status
  end

  def sprint_status_label_or_default(sprint)
    sprint.new_record? ? l("version_status_#{Version::VERSION_STATUSES.first}") : l("version_status_#{sprint.status}")
  end

  def status_id_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").id : story.status.id
  end

  def status_label_or_default(story)
    story.new_record? ? IssueStatus.find(:first, :order => "position ASC").name : story.status.name
  end

  def sprint_html_id_or_empty(sprint)
    sprint.new_record? ? "" : "sprint_#{sprint.id}"
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
    date_string_with_milliseconds(story.updated_on, 0.001) unless story.blank?
  end

  def date_string_with_milliseconds(d, add=0)
    return '' if d.blank?
    d.strftime("%B %d, %Y %H:%M:%S") + '.' + (d.to_f % 1 + add).to_s.split('.')[1]
  end

  def remaining_hours(item)
    item.remaining_hours.blank? || item.remaining_hours==0 ? "" : item.remaining_hours
  end

  def javascript_include_tag_backlogs(*args)
    min = RAILS_ENV == 'development' ? "" : ".min"

    args.each do |jsfile|
      jsfile.gsub!('jquery.js', "jquery-1.5.1#{min}.js")
      jsfile.gsub!('jquery-ui.js', "jquery-ui-1.8.11.custom.min.js")
      jsfile.gsub!('jquery.jeditable.js', "jquery.jeditable.mini.js")
      jsfile.gsub!('excanvas.js', "excanvas#{min}.js")
      jsfile.gsub!('jquery.jqplot.js', "jquery.jqplot#{min}.js")
    end

    args.push(:plugin => 'redmine_backlogs')
    javascript_include_tag *args
  end
end
