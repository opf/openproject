class OpenProject::XlsExport::XlsViews::OneDimensionalTable < OpenProject::XlsExport::XlsViews
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

  def format_columns
    raise NotImplementedError
  end

  def build_cost_rows
    query.each_direct_result do |result|
      spreadsheet.add_row(cost_row(result))
    end
  end

  def cost_row(result)
    raise NotImplementedError
  end

  def build_footer
    raise NotImplementedError
  end

  def headers
    raise NotImplementedError
  end
end
