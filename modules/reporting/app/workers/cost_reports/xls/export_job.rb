require "active_storage/filename"

class CostReports::XLS::ExportJob < Exports::ExportJob
  self.model = ::CostReport

  def project
    options[:project]
  end

  def cost_types
    options[:cost_types]
  end

  def title
    I18n.t("export.cost_reports.title")
  end

  private

  def prepare!
    CostQuery::Cache.check
    self.query = ::CostReports::ParamsToReport.new(query, project:, user: current_user).call
    # The export is a flat list of entries, so the report's grouping is dropped:
    # a grouped query aggregates in SQL and no longer yields the single entries.
    query.apply_pivot_configuration(rows: [], columns: [])
  end

  def export!
    handle_export_result(export, xls_report_result)
  end

  def xls_report_result
    params = { query:, project:, cost_types: }
    content = ::OpenProject::Reporting::CostEntryXlsTable.generate(params).xls
    time = Time.current.strftime("%Y-%m-%d-T-%H-%M-%S")
    export_title = "cost-report-#{time}.xls"

    ::Exports::Result.new(format: :xls,
                          title: export_title,
                          mime_type: "application/vnd.ms-excel",
                          content:)
  end
end
