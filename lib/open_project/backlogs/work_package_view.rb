#class OpenProject::Backlogs::IssueView < OpenProject::Nissue::IssueView; end
#require_dependency 'open_project/backlogs/issue_view/fields_paragraph'
#require_dependency 'open_project/backlogs/issue_view/heading'
#require_dependency 'open_project/backlogs/issue_view/issue_hierarchy_paragraph'
#
#class OpenProject::Backlogs::IssueView < OpenProject::Nissue::IssueView
# def fields_paragraph
#   @fields_paragraph ||= OpenProject::Backlogs::IssueView::FieldsParagraph.new(@issue)
# end
#
# def heading
#   @heading ||= OpenProject::Backlogs::IssueView::Heading.new(@issue)
# end
#
# def sub_issues_paragraph
#   @sub_issues_paragraph ||= OpenProject::Backlogs::IssueView::IssueHierarchyParagraph.new(@issue)
# end
#end
