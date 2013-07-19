class OpenProject::Nissue::IssueView::Heading < OpenProject::Nissue::View
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def render(t)
    render_issue_subject_with_tree(t) + render_author(t)
  end

  def render_issue_subject_with_tree(t)
    content_tag(:div, t.render_issue_subject_with_tree(@issue), :class => 'subject')
  end

  def render_author(t)
    content_tag(:p, [
      t.authoring(@issue.created_at, @issue.author),
      '. ',
      @issue.created_at != @issue.updated_at ? l(:label_updated_time, t.time_tag(@issue.updated_at)) + '.' : ''
    ].join.html_safe, :class => 'author')
  end
end
