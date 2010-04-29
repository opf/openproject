# Hooks to attach to the Redmine Issues.
module XlsReport
  class IssueHook  < Redmine::Hook::ViewListener
    # Renders the Cost Object subject and basic costs information
    render_on :view_issues_sidebar_issues_bottom, :partial => 'hooks/xls_report/view_issues_sidebar_issues_bottom'
  end
end