class OpenProject::Backlogs::IssueForm::FieldsParagraph < OpenProject::Backlogs::IssueView::FieldsParagraph
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

    unless @work_package.is_story?
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
    field_class.new(:subject) { |t| t.text_field_tag "work_package[subject]", work_package.subject.to_s }
  end

  def story_points
    field_class.new(:story_points) { |t| t.text_field_tag "work_package[story_points]", work_package.story_points.to_s }
  end

  def remaining_hours
    return super unless work_package.is_task?
    field_class.new(:remaining_hours) { |t| t.text_field_tag "work_package[remaining_hours]", work_package.remaining_hours.to_s, :disabled => !work_package.is_task? }
  end

  def allowed_statuses
    work_package.new_statuses_allowed_to(User.current)
  end

  def status_field
    field_class.new(:status) { |t| t.select_tag "work_package[status_id]", options_for_select((allowed_statuses | [work_package.status]).collect {|p| [p.name, p.id]}, :selected => work_package.status.id), {:required => true, :disabled => !(work_package.new_record? || allowed_statuses.any?)} }
  end

  def assigned_to_field
    field_class.new(:assigned_to) { |t| t.select_tag "work_package[assigned_to_id]", "<option></option>".html_safe + options_for_select(work_package.assignable_users.collect {|m| [m.name, m.id]}, work_package.assigned_to_id)}
  end

  def fixed_version_field
    return nil if work_package.assignable_versions.empty?
    field_class.new(:fixed_version) do |t|
      t.select_tag "work_package[fixed_version_id]", "<option></option>".html_safe + t.version_options_for_select(work_package.assignable_versions, work_package.fixed_version), { :disabled => work_package.is_task? }
    end
  end

  def category_field
    return nil if work_package.project.issue_categories.empty?
    field_class.new(:category) do |t|
      t.select_tag "work_package[category_id]", "<option></option>".html_safe + options_for_select(work_package.project.issue_categories.collect {|c| [c.name, c.id]}, work_package.category_id)
    end
  end

  def custom_fields
    fields = ActiveSupport::OrderedHash.new

    return fields if @work_package.custom_field_values.empty?

    @work_package.custom_field_values.each do |custom_value|
      fields[custom_value.custom_field.name] = OpenProject::Backlogs::IssueForm::CustomFieldParagraph.new(custom_value)
    end

    fields
  end

  def empty; OpenProject::Nissue::EmptyParagraph.new; end

  def field_class; OpenProject::Nissue::SimpleParagraph; end
end
