require "active_storage/filename"

class CostQuery::ExportJob < Exports::ExportJob
  self.model = ::CostQuery

  def title
    I18n.t("export.cost_reports.title")
  end

  def project
    options[:project]
  end

  def cost_types
    options[:cost_types]
  end

  private

  def prepare!
    CostQuery::Cache.check
    self.query = build_query(query)
  end

  def export!
    # Build an xls file from a cost report.
    # We only support extracting a simple xls table, so grouping is ignored.
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

  # rubocop:disable Metrics/AbcSize
  def build_query(filters, groups = {})
    query = CostQuery.new(project:)
    query.tap do |q|
      filters[:operators].each do |filter, operator|
        unless filters[:values][filter] == ["<<inactive>>"]
          values = Array(filters[:values][filter]).map { |v| v == "<<null>>" ? nil : v }
          q.filter(filter.to_sym,
                   operator:,
                   values:)
        end
      end
    end
    groups[:columns].try(:reverse_each) { |c| query.column(c) }
    groups[:rows].try(:reverse_each) { |r| query.row(r) }
    query
  end

  # rubocop:enable Metrics/AbcSize
end
