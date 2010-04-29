# Hooks to attach to the Redmine Issues.
module XlsReport
  class CostReportHook  < Redmine::Hook::ViewListener
    # Renders the Cost Object subject and basic costs information
    render_on :view_cost_report_other_formats, :partial => 'hooks/xls_report/view_cost_report_other_formats'
  end
end