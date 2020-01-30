require_relative './one_dimensional_table.xls'

class OpenProject::XlsExport::XlsViews::SimpleCostReportTable < OpenProject::XlsExport::XlsViews::OneDimensionalTable
  def format_columns(spreadsheet)
    spreadsheet.add_format_option_to_column(headers.length - 1, number_format: currency_format)
    spreadsheet.add_format_option_to_column(headers.length - 2, number_format: number_format) if show_units?
  end

  def cost_row(result)
    current_cost_type_id = result.fields[:cost_type_id].to_i
    row = [show_row(result)]
    row << show_result(result, current_cost_type_id) if show_units?
    row << cost_type_unit_label(current_cost_type_id, @cost_type) if show_units?
    row << show_result(result)
    row << cost_type_unit_label(@unit_id, @cost_type)

    row
  end

  def build_footer(spreadsheet)
    footer = [''] * exported_fields.size
    footer += ['', ''] if show_units?
    spreadsheet.add_row(footer + [show_result(query), cost_type_unit_label(@unit_id, @cost_type)]) # footer
  end

  def headers
    headers = exported_fields.collect { |field| label_for(field) }
    headers << label_for(:field_units) << "" if show_units?
    headers << label_for(:label_sum) << ""

    headers
  end

  def exported_fields
    @query.collect(&:important_fields).flatten.uniq
  end

  def show_units?
    @query.collect(&:important_fields).flatten.uniq.include? "cost_type_id"
  end
end
