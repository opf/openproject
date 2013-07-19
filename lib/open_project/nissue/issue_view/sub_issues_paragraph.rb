class OpenProject::Nissue::IssueView::SubIssuesParagraph < OpenProject::Nissue::Paragraph
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def visible?
    !@issue.leaf? or User.current.allowed_to?(:manage_subtasks, @issue.project)
  end

  def label
    l(:label_subtask_plural)
  end

  def render(t)
    return unless visible?

    content_tag(:div, [
      render_actions(t),
      render_label(t),
      render_descendants(t)
    ].join.html_safe, :id => 'issue_tree')
  end

  def render_actions(t)
    if User.current.allowed_to?(:manage_subtasks, @issue.project)
      content_tag(:div,
                  t.link_to(l(:button_add), {:controller => 'issues',
                                             :action => 'new',
                                             :project_id => @issue.project,
                                             :issue => {:parent_issue_id => @issue}}),
                  :class => 'contextual')
    end
  end

  def render_label(t)
    content_tag(:p, content_tag(:strong, label))
  end

  def render_descendants(t)
    t.render_descendants_tree(@issue) unless @issue.leaf?
  end
end
