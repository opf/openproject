class OpenProject::Nissue::IssueView::SpentTimeParagraph < OpenProject::Nissue::Paragraph
  def initialize(issue)
    @issue = issue
  end

  def label
    l(:label_spent_time)
  end

  def visible?
    User.current.allowed_to?(:view_time_entries, @issue.project)
  end

  def render(t)
    if @issue.spent_hours > 0
      t.link_to(t.l_hours(@issue.spent_hours), {:controller => 'timelog', :action => 'index', :project_id => @issue.project, :issue_id => @issue})
    else
      "-"
    end
  end
end
