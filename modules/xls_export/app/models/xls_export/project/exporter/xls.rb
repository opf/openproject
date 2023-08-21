module XlsExport::Project::Exporter
  class XLS < Projects::Exports::QueryExporter
    include ::XlsExport::Concerns::SpreadsheetBuilder

    alias :records :projects

    def spreadsheet_title
      I18n.t(:label_project_plural)
    end
  end
end
