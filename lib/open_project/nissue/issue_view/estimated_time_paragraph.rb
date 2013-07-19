class OpenProject::Nissue::IssueView::EstimatedTimeParagraph < OpenProject::Nissue::Paragraph
  def initialize(issue)
    @issue = issue
  end

  def label
    Issue.human_attribute_name(:estimated_hours)
  end

  def visible?
    @issue.estimated_hours
  end

  def render(t)
    t.l_hours(@issue.estimated_hours)
  end
end
