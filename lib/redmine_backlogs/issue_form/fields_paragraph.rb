class RedmineBacklogs::IssueForm::FieldsParagraph < RedmineBacklogs::IssueView::FieldsParagraph
  def default_fields
    base_fields = super

    fields = ActiveSupport::OrderedHash.new

    # fields[:subject]         = subject
    fields[:status]          = status_field || base_fields[:status]
    fields[:assigned_to]     = assigned_to_field || base_fields[:assigned_to]
    fields[:fixed_version]   = fixed_version_field || base_fields[:fixed_version]
    fields[:empty_bottom]    = empty

    # fields[:empty_head]      = empty
    fields[:category]        = category_field || base_fields[:category]
    fields[:story_points]    = story_points || base_fields[:story_points]
    fields[:remaining_hours] = remaining_hours || base_fields[:remaining_hours]
    fields[:spent_time]      = base_fields[:spent_time]

    unless @issue.is_story?
      fields.delete(:empty)
      fields.delete(:story_points)
    end
    fields[:fixed_version].label = l('label_backlog')
    
    fields
  end
  
  def call_hook(t)
  end
  
  private
  
  def subject
    field_class.new(:subject) { |t| t.text_field_tag "issue[subject]", issue.subject.to_s }
  end
  
  def story_points
    field_class.new(:story_points) { |t| t.text_field_tag "issue[story_points]", issue.story_points.to_s }
  end

  def remaining_hours
    field_class.new(:remaining_hours) { |t| t.text_field_tag "issue[remaining_hours]", issue.remaining_hours.to_s, :disabled => !issue.is_task? }
  end
  
  def allowed_statuses
    issue.new_statuses_allowed_to(User.current)
  end
  
  def status_field
    field_class.new(:status) { |t| t.select_tag "issue[status_id]", options_for_select((allowed_statuses | [issue.status]).collect {|p| [p.name, p.id]}, :selected => issue.status.id), {:required => true, :disabled => !(issue.new_record? || allowed_statuses.any?)} }
  end
  
  def assigned_to_field
    field_class.new(:assigned_to) { |t| t.select_tag "issue[assigned_to_id]", "<option></option>" + options_for_select(issue.assignable_users.collect {|m| [m.name, m.id]}, issue.assigned_to_id)}
  end
  
  def fixed_version_field
    unless issue.assignable_versions.empty?
      field_class.new(:fixed_version) do |t|
        str = t.select_tag "issue[fixed_version_id]", "<option></option>" + t.version_options_for_select(issue.assignable_versions, issue.fixed_version), { :disabled => issue.is_task? }
        if t.authorize_for('versions', 'new') and not issue.is_task?
          str += t.prompt_to_remote(t.image_tag('add.png', :style => 'vertical-align: middle;'),
                       l(:label_version_new),
                       'version[name]',
                       {:controller => 'versions', :action => 'create', :project_id => issue.project},
                       :title => l(:label_version_new),
                       :tabindex => 200)
        end
        str
      end
    else
      nil
    end
  end
  
  def category_field
    unless issue.project.issue_categories.empty?
      field_class.new(:category) do |t|
        str = t.select_tag "issue[category_id]", "<option></option>" + options_for_select(issue.project.issue_categories.collect {|c| [c.name, c.id]}, issue.category_id)
        str += t.prompt_to_remote(t.image_tag('add.png', :style => 'vertical-align: middle;'),
                             l(:label_issue_category_new),
                             'category[name]',
                             {:controller => 'issue_categories', :action => 'new', :project_id => issue.project},
                             :title => l(:label_issue_category_new),
                             :tabindex => 199) if t.authorize_for('issue_categories', 'new')
        str
      end
    else
      nil
    end
  end
  
  def custom_fields
    fields = ActiveSupport::OrderedHash.new

    return fields if @issue.custom_field_values.empty?

    @issue.custom_field_values.each do |custom_value|
      fields[custom_value.custom_field.name] = RedmineBacklogs::IssueForm::CustomFieldParagraph.new(custom_value)
    end

    fields
  end
  
  def empty; ChiliProject::Nissue::EmptyParagraph.new; end

  def field_class; ChiliProject::Nissue::SimpleParagraph; end
end
