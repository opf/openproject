class Backlogs::IssueActions < ChiliProject::Nissue::View
  def initialize(issue)
    @issue = issue
  end

  def render(t)
    css_class = "watcher_link_#{@issue.id}"
    content_tag(:div, [
        t.watcher_link(@issue, User.current, :class => css_class, :replace => ".#{css_class}"),
        (t.modal_link_to(l(:button_update), {:controller => 'issue_boxes', :action => 'edit', :id => @issue }, :class => 'icon icon-edit') if t.authorize_for('issue_boxes', 'edit'))
      ].join, :class => 'contextual')
  end
end
