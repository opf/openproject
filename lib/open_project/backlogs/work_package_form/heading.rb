class OpenProject::Backlogs::IssueForm::Heading < OpenProject::Backlogs::IssueView::Heading
  def render_work_package_subject_with_tree(t)
    t.text_field_tag("work_package[subject]", work_package.subject.to_s, {:class => 'subject-input'}) + t.tag(:hr)
  end
end
