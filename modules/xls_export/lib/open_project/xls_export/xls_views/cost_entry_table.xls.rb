require_relative './one_dimensional_table.xls'

class OpenProject::XlsExport::XlsViews::CostEntryTable < OpenProject::XlsExport::XlsViews::OneDimensionalTable
  def format_columns(spreadsheet)
    spreadsheet.add_format_option_to_column(headers.length - 3,
                                            number_format: number_format)
    spreadsheet.add_format_option_to_column(headers.length - 1,
                                            number_format: currency_format)
  end

  def cost_row(result)
    current_cost_type_id = result.fields['cost_type_id'].to_i

    cost_entry_attributes
      .map { |field| show_field field, result.fields[field.to_s] }
      .concat(
        [
          show_result(result, current_cost_type_id), # units
          cost_type_label(current_cost_type_id, @cost_type), # cost type
          show_result(result, 0) # costs/currency
        ]
      )
  end

  def build_footer(spreadsheet)
    footer = [''] * cost_entry_attributes.size
    footer += if show_result(query, 0) != show_result(query)
                [show_result(query), '', show_result(query, 0)]
              else
                ['', '', show_result(query)]
              end
    spreadsheet.add_row(footer) # footer
  end

  def headers
    cost_entry_attributes
      .map { |field| label_for(field) }
      .concat([CostEntry.human_attribute_name(:units), CostType.model_name.human, CostEntry.human_attribute_name(:costs)])
  end

  def cost_entry_attributes
    %i[spent_on user_id activity_id issue_id comments project_id]
  end
end
