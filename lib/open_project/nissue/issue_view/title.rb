class OpenProject::Nissue::IssueView::Title < OpenProject::Nissue::View
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def render(t)
    content_tag(:h2, [
      @issue.tracker.name,
      "##{@issue.id}",
      t.call_hook(:view_issues_show_identifier, :issue => @issue)
    ].join(" ").html_safe)
  end
end

