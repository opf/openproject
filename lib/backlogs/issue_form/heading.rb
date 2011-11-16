class Backlogs::IssueForm::Heading < Backlogs::IssueView::Heading
  def render_issue_subject_with_tree(t)
    t.text_field_tag("issue[subject]", issue.subject.to_s, {:class => 'subject-input'}) + t.tag(:hr)
  end
end
