class OpenProject::Backlogs::IssueForm::CustomFieldParagraph < OpenProject::Nissue::IssueView::CustomFieldParagraph
  def render(t)
    t.custom_field_tag :work_package, @custom_value
  end
end
