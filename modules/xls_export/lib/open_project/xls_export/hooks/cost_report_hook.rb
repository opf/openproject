module OpenProject::XlsExport::Hooks
  class CostReportHook < Redmine::Hook::ViewListener
    render_on :view_cost_report_toolbar, partial: 'hooks/xls_report/view_cost_report_toolbar'
  end
end
