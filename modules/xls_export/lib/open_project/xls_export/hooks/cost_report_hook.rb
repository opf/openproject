module OpenProject::XlsExport::Hooks
  class CostReportHook < OpenProject::Hook::ViewListener
    render_on :view_cost_report_toolbar, partial: 'hooks/xls_report/view_cost_report_toolbar'
  end
end
