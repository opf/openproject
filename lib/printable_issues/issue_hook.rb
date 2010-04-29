# Hooks to attach to the Redmine Issues.
module PrintableIssues
  class IssueHook  < Redmine::Hook::ViewListener
    # Renders the Cost Object subject and basic costs information
    render_on :view_issues_sidebar_issues_bottom, :partial => 'hooks/printable_issues/view_issues_sidebar_issues_bottom'
  end
end