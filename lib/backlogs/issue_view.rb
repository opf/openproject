class Backlogs::IssueView < ChiliProject::Nissue::IssueView; end
require_dependency 'backlogs/issue_view/fields_paragraph'
require_dependency 'backlogs/issue_view/heading'
require_dependency 'backlogs/issue_view/issue_hierarchy_paragraph'

class Backlogs::IssueView < ChiliProject::Nissue::IssueView
  def fields_paragraph
    @fields_paragraph ||= Backlogs::IssueView::FieldsParagraph.new(@issue)
  end

  def heading
    @heading ||= Backlogs::IssueView::Heading.new(@issue)
  end

  def sub_issues_paragraph
    @sub_issues_paragraph ||= Backlogs::IssueView::IssueHierarchyParagraph.new(@issue)
  end
end
