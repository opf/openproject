class OpenProject::XlsExport::XlsViews::CostEntryTable < OpenProject::XlsExport::XlsViews
  def generate
    @spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new(I18n.t(:label_money))
    default_query = serialize_query_without_hidden(@query)

    available_cost_type_tabs(options[:cost_types]).each_with_index do |(unit_id, name), idx|
      setup_query_for_tab(default_query, unit_id)

      spreadsheet.worksheet(idx, name)
      build_spreadsheet
    end

    spreadsheet
  end

  def setup_query_for_tab(query, unit_id)
    @query = CostQuery.deserialize(query)
    @cost_type = nil
    @unit_id = unit_id

    if @unit_id != 0
      @query.filter :cost_type_id, operator: '=', value: @unit_id.to_s
      @cost_type = CostType.find(unit_id) if unit_id.positive?
    end
  end

  def build_spreadsheet
    set_title

    build_header
    format_columns
    build_cost_rows
    build_footer

    spreadsheet
  end

  def build_header
    spreadsheet.add_headers(headers)
  end

  def build_cost_rows
    sorted_results.each do |result|
      spreadsheet.add_row(cost_row(result))
    end
  end

  def format_columns
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

  def build_footer
    footer = [''] * cost_entry_attributes.size
    footer += if show_result(query, 0) != show_result(query)
                one_unit_type_footer
              else
                multiple_unit_types_footer
              end
    spreadsheet.add_sums(footer) # footer
  end

  def one_unit_type_footer
    [show_result(query), '', show_result(query, 0)]
  end

  def multiple_unit_types_footer
    ['', '', show_result(query)]
  end

  def headers
    cost_entry_attributes
      .map { |field| label_for(field) }
      .concat([CostEntry.human_attribute_name(:units), CostType.model_name.human, CostEntry.human_attribute_name(:costs)])
  end

  def cost_entry_attributes
    %i[spent_on user_id activity_id work_package_id comments project_id]
  end

  # Returns the results of the query sorted by date the time was spent on and by id
  def sorted_results
    query
      .each_direct_result
      .map(&:itself)
      .group_by { |r| DateTime.parse(r.fields['spent_on']) }
      .sort
      .flat_map { |_, date_results| date_results.sort_by { |r| r.fields['id'] } }
  end
end
