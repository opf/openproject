class OpenProject::Backlogs::IssueView::Heading < ChiliProject::Nissue::IssueView::Heading
  def render_issue_subject_with_tree(t)
    content_tag('h3', h(@issue.subject))
  end
end
