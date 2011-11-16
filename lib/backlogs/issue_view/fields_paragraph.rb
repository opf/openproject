class Backlogs::IssueView::FieldsParagraph < ChiliProject::Nissue::IssueView::FieldsParagraph
  def hook_context(t)
    super.merge(:from => self.class.name)
  end

  def default_fields
    base_fields = super

    fields = ActiveSupport::OrderedHash.new

    fields[:status]          = base_fields[:status]
    fields[:assigned_to]     = base_fields[:assigned_to]
    fields[:fixed_version]   = base_fields[:fixed_version]
    fields[:empty]           = ChiliProject::Nissue::EmptyParagraph.new

    fields[:category]        = base_fields[:category]
    fields[:story_points]    = story_points
    fields[:remaining_hours] = remaining_hours
    fields[:spent_time]      = base_fields[:spent_time]

    unless @issue.is_story?
      fields.delete(:empty)
      fields.delete(:story_points)
    end
    fields[:fixed_version].label = l('label_backlog')

    fields
  end

  def story_points
    ChiliProject::Nissue::SimpleParagraph.new(:story_points) { |t| @issue.story_points || '-' }
  end

  def remaining_hours
    ChiliProject::Nissue::SimpleParagraph.new(:remaining_hours) { |t| t.l_hours(@issue.remaining_hours) }
  end
end
