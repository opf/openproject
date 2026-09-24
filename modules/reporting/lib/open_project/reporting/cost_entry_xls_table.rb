class OpenProject::Reporting::CostEntryXlsTable < OpenProject::XlsExport::XlsViews
  def generate
    @spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new(I18n.t(:label_money))
    # The unit is view state rather than a stored filter, so the configuration
    # can be rebuilt per tab with a different one.
    default_query = @query.to_query_params

    available_cost_type_tabs(options[:cost_types]).each_with_index do |(unit_id, name), idx|
      setup_query_for_tab(default_query, unit_id)

      spreadsheet.worksheet(idx, name)
      build_spreadsheet
    end

    spreadsheet
  end

  def setup_query_for_tab(report_params, unit_id)
    @cost_type = nil
    @unit_id = unit_id
    params = @unit_id == 0 ? report_params.except(:unit) : report_params.merge(unit: @unit_id)

    @query = ::CostReports::ParamsToReport.new(params, project: @project, user: User.current).call
    @cost_type = CostType.find(unit_id) if unit_id.positive?
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
      row = spreadsheet.add_row(cost_row(result))
      row.set_format 0, date_format
    end
  end

  def format_columns
    spreadsheet.add_format_option_to_column(headers.length - 3,
                                            number_format:)
    spreadsheet.add_format_option_to_column(headers.length - 1,
                                            number_format: currency_format)
  end

  def cost_fields_columns(result)
    cost_entry_attributes
      .map { |field| show_field field, result.fields[field.to_s] }
  end

  def cost_main_times_columns(result)
    [
      format_time(result.start_timestamp, include_date: false),
      cost_main_end_time_column(result.start_timestamp, result.end_timestamp)
    ]
  end

  def cost_main_end_time_column(start_timestamp, end_timestamp)
    return "" if start_timestamp.nil? || end_timestamp.nil?

    days_between = (end_timestamp.to_date - start_timestamp.to_date).to_i
    day_prefix = days_between >= 1 ? "#{end_timestamp.to_date.iso8601} " : ""
    "#{day_prefix}#{format_time(end_timestamp, include_date: false)}"
  end

  def cost_main_columns(result)
    main_cols = [result.fields["spent_on"].to_date]
    main_cols.concat cost_main_times_columns(result) if with_times_column?
    main_cols
  end

  def cost_row(result)
    current_cost_type_id = result.fields["cost_type_id"].to_i
    # TODO: What would be the correct way here?
    result.fields["entity_gid"] = result.entity_gid

    cost_main_columns(result)
      .concat(cost_fields_columns(result))
      .push(

        show_result(result, current_cost_type_id), # units
        cost_type_label(current_cost_type_id, @cost_type), # cost type
        show_result(result, 0) # costs/currency

      )
  end

  def build_footer
    footer = [""] * (cost_entry_attributes.size + main_headers.size)
    footer += if show_result(query, 0) == show_result(query)
                multiple_unit_types_footer
              else
                one_unit_type_footer
              end
    spreadsheet.add_sums(footer) # footer
  end

  def one_unit_type_footer
    [show_result(query), "", show_result(query, 0)]
  end

  def multiple_unit_types_footer
    ["", "", show_result(query)]
  end

  def main_headers
    main = [label_for(:spent_on)]
    if with_times_column?
      main.push I18n.t(:"export.cost_reports.start_time"), I18n.t(:"export.cost_reports.end_time")
    end
    main
  end

  def headers
    main_headers
      .concat(cost_entry_attributes.map { |field| label_for(field) })
      .push(CostEntry.human_attribute_name(:units), CostType.model_name.human, CostEntry.human_attribute_name(:costs))
  end

  def cost_entry_attributes
    %i[user_id activity_id entity_gid comments project_id]
  end

  # Returns the results of the query sorted by date the time was spent on and name
  def sorted_results
    results = query.each_direct_result.map(&:itself)
    users_by_id = load_users_for_results(results)

    results
      .group_by { |r| r.fields["spent_on"] }
      .sort
      .flat_map do |_, date_results|
      date_results.sort_by { |r| user_name_for_sorting(r, users_by_id) }
    end
  end

  def labour_query?
    @unit_id == -1
  end

  def with_times_column?
    Setting.allow_tracking_start_and_end_times && labour_query?
  end

  def load_users_for_results(results)
    user_ids = results.map { |r| r.fields["user_id"] }.uniq
    User.where(id: user_ids).index_by(&:id)
  end

  def user_name_for_sorting(result, users_by_id)
    users_by_id[result.fields["user_id"]]&.name&.downcase || ""
  end
end
