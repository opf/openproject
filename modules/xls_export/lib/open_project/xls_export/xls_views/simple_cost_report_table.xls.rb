require_relative './one_dimensional_table.xls'

class OpenProject::XlsExport::XlsViews::SimpleCostReportTable < OpenProject::XlsExport::XlsViews::OneDimensionalTable
  def format_columns
    column_count = headers.size

    if column_count - exported_fields.size == 1
      spreadsheet.add_format_option_to_column(column_count - 1, number_format: currency_format)
    elsif column_count - exported_fields.size == 2
      spreadsheet.add_format_option_to_column(column_count - 2, number_format: number_format)
    else
      spreadsheet.add_format_option_to_column(column_count - 2, number_format: number_format)
      spreadsheet.add_format_option_to_column(column_count - 4, number_format: currency_format)
    end
  end

  def build_cost_rows
    query.each do |result|
      spreadsheet.add_row(cost_row(result))
    end
  end

  def cost_row(result)
    current_cost_type_id = result.fields[:cost_type_id].to_i
    row = [show_row(result)]
    row << show_result(result, current_cost_type_id) if show_units?
    row << cost_type_unit_label(current_cost_type_id, cost_type) if show_units?
    row << show_result(result)
    row << cost_type_unit_label(unit_id, cost_type) if show_unit_label?

    row
  end

  def build_footer
    footer = [''] * exported_fields.size
    footer += ['', ''] if show_units?
    footer << show_result(query)
    footer << cost_type_unit_label(unit_id, cost_type) if show_unit_label?

    spreadsheet.add_sums(footer)
  end

  def headers
    headers = exported_fields.collect { |field| label_for(field) }
    headers << CostEntry.human_attribute_name(:costs) << "" if show_units?
    headers << label_for(:label_sum)
    headers << "" if show_unit_label?

    headers
  end

  def exported_fields
    @query.collect(&:important_fields).flatten.uniq
  end

  def show_units?
    cost_type.present?
  end

  def show_unit_label?
    unit_id != 0
  end
end
