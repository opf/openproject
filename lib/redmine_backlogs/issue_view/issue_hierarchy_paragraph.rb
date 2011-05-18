class RedmineBacklogs::IssueView::IssueHierarchyParagraph < ChiliProject::Nissue::IssueView::SubIssuesParagraph
  include IssuesHelper # mainly interested in issue_list helper method

  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def visible?
    !@issue.leaf? or @issue.parent.present?
  end

  def label
    l(:label_issue_hierarchy)
  end

  def render_actions(t)
    # currently no actions from within an ajax form supported
  end

  def render_descendants(t)
    indent = 0

    s = '<form action="#"><table class="list issues">'

    # render parent issues
    @issue.ancestors.each do |issue|
      s << render_row(t, issue, indent)
      indent += 1
    end

    # render current element
    s << render_row(t, @issue, indent)
    indent += 1

    # render children
    issue_list(@issue.descendants.sort_by(&:lft)) do |issue, level|
      s << render_row(t, issue, level + indent)
    end

    s << '</table></form>'
    s
  end

  def render_row(t, issue, level)
    css_classes = ["issue"]
    css_classes << "issue-#{issue.id}"
    css_classes << "idnt" << "idnt-#{level}" if level > 0

    if @issue == issue
      issue_text = t.link_to("#{issue.tracker.name} ##{issue.id}",
                             'javascript:void(0)',
                             :style => "color:inherit; font-weight: bold")
    else
      issue_text = t.link_to_issue_box("#{issue.tracker.name} ##{issue.id}", issue)
    end
    issue_text << ": "
    issue_text << t.truncate(issue.subject, :length => 60)

    content_tag('tr', [
        content_tag('td', t.check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox'),
        content_tag('td', issue_text, :class => 'subject'),
        content_tag('td', h(issue.status)),
        content_tag('td', t.link_to_user(issue.assigned_to)),
        content_tag('td', t.link_to_version(issue.fixed_version))
      ],
      :class => css_classes.join(' '))
  end
end
