class OpenProject::Nissue::IssueView::RelatedIssuesParagraph < OpenProject::Nissue::Paragraph
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def visible?
    User.current.allowed_to?({:controller => 'issue_relations', :action => 'new'}, @issue.project) or @issue.relations.present?
  end

  def render(t)
    return unless visible?

    content_tag(:div, t.render(:partial => 'issues/relations'), :id => 'relations')
  end
end
