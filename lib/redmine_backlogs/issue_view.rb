class RedmineBacklogs::IssueView < ChiliProject::Nissue::IssueView
  def fields_paragraph
    @fields_paragraph ||= RedmineBacklogs::IssueView::FieldsParagraph.new(@issue)
  end
end
