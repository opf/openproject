class OpenProject::Backlogs::IssueView::Heading < OpenProject::Nissue::IssueView::Heading
  def render_issue_subject_with_tree(t)
    content_tag('h3', @issue.subject)
  end
end
