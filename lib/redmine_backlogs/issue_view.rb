class RedmineBacklogs::IssueView < ChiliProject::Nissue::IssueView; end
require_dependency 'redmine_backlogs/issue_view/fields_paragraph'
require_dependency 'redmine_backlogs/issue_view/heading'
require_dependency 'redmine_backlogs/issue_view/issue_hierarchy_paragraph'

class RedmineBacklogs::IssueView < ChiliProject::Nissue::IssueView
  def fields_paragraph
    @fields_paragraph ||= RedmineBacklogs::IssueView::FieldsParagraph.new(@issue)
  end

  def heading
    @heading ||= RedmineBacklogs::IssueView::Heading.new(@issue)
  end

  def sub_issues_paragraph
    @sub_issues_paragraph ||= RedmineBacklogs::IssueView::IssueHierarchyParagraph.new(@issue)
  end
end
