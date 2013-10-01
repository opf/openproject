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
    task.blank? || task.assigned_to.blank? ? '' : "style=\"background-color:#{task.assigned_to.backlogs_preference(:task_color)};\"".html_safe
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

  def shortened_id(record)
    id = record.id.to_s
    (id.length > 8 ? "#{id[0..1]}...#{id[-4..-1]}" : id)
  end

  def work_package_link_or_empty(work_package)
    modal_link_to_work_package(work_package.id, work_package, :class => 'prevent_edit') unless work_package.new_record?
  end

  def modal_link_to_work_package(title, work_package, options = {})
    modal_link_to(title, work_package_path(work_package), options)
  end

  def modal_link_to(title, path, options = {})
    html_id = "modal_work_package_#{SecureRandom.hex(10)}"
    link_to(title, path, options.merge(:id => html_id, :'data-modal' => ''))
  end

  def sprint_link_or_empty(item)
    item_id = item.id.to_s
    text = (item_id.length > 8 ? "#{item_id[0..1]}...#{item_id[-4..-1]}" : item_id)
    item.new_record? ? "" : link_to(text, {:controller => '/sprint', :action => "show", :id => item}, {:class => "prevent_edit"})
  end

  def mark_if_closed(story)
    !story.new_record? && work_package_status_for_id(story.status_id).is_closed? ? "closed" : ""
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
    story.new_record? ? new_record_status.id : story.status_id
  end

  def status_label_or_default(story)
    story.new_record? ? new_record_status.name : h(work_package_status_for_id(story.status_id).name)
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

  def type_id_or_empty(story)
    story.new_record? ? "" : story.type_id
  end

  def type_name_or_empty(story)
    story.new_record? ? "" : h(backlogs_types_by_id[story.type_id].name)
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

  def available_story_types
    @available_story_types ||= begin
      types = story_types & @project.types if @project

      types
    end
  end

  def available_statuses_by_type
    @available_statuses_by_type ||= begin
      available_statuses_by_type = Hash.new do |type_hash, type|
        type_hash[type] = Hash.new do |status_hash, status|
          status_hash[status] = [status]
        end
      end

      workflows = all_workflows

      workflows.each do |w|
        type_status = available_statuses_by_type[story_types_by_id[w.type_id]][w.old_status]

        type_status << w.new_status unless type_status.include?(w.new_status)
      end

      available_statuses_by_type
    end
  end

  def show_burndown_link(sprint)
    ret = ""

    ret += link_to(l('backlogs.show_burndown_chart'),
                   {},
                   :class => 'show_burndown_chart')


    ret += javascript_tag "
            jQuery(document).ready(function(){
              var burndown = RB.Factory.initialize(RB.Burndown, jQuery('.show_burndown_chart'));
              burndown.setSprintId(#{sprint.id});
            });"
    ret.html_safe
  end

  private

  def new_record_status
    @new_record_status ||= all_work_package_status.first
  end

  def default_work_package_status
    @default_work_package_status ||= all_work_package_status.detect(&:is_default)
  end

  def work_package_status_for_id(id)
    @all_work_package_status_by_id ||= begin
      all_work_package_status.inject({}) do |mem, status|
        mem[status.id] = status
        mem
      end
    end

    @all_work_package_status_by_id[id]
  end

  def all_workflows
    @all_workflows ||= Workflow.all(:include => [:new_status, :old_status],
                                    :conditions => { :role_id => User.current.roles_for_project(@project).collect(&:id),
                                                     :type_id => story_types.collect(&:id) })
  end

  def all_work_package_status
    @all_work_package_status ||= IssueStatus.all(:order => 'position ASC')
  end

  def backlogs_types
    @backlogs_types ||= begin
      backlogs_ids = Setting.plugin_openproject_backlogs["story_types"]
      backlogs_ids << Setting.plugin_openproject_backlogs["task_type"]

      Type.find(:all,
                   :conditions => { :id => backlogs_ids },
                   :order => 'position ASC')
    end
  end

  def backlogs_types_by_id
    @backlogs_types_by_id ||= begin
      backlogs_types.inject({}) do |mem, type|
        mem[type.id] = type
        mem
      end
    end
  end

  def story_types
    @story_types ||= begin
      backlogs_type_ids = Setting.plugin_openproject_backlogs["story_types"].map(&:to_i)

      backlogs_types.select{ |t| backlogs_type_ids.include?(t.id) }
    end
  end

  def story_types_by_id
    @story_types_by_id ||= begin
      story_types.inject({}) do |mem, type|
        mem[type.id] = type
        mem
      end
    end
  end
end
