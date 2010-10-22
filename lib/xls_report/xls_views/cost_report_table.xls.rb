require_dependency 'xls_report/xls_views'

class CostReportTable < XlsViews
  def final_row(final_row, cells)
    row = [show_row final_row]
    row += cells
    row << show_result(final_row)
  end

  def row(row, subrows)
    unless row.fields.empty?
      # Here we get the border setting, vertically. The rowspan #{subrows.size} need be
      # converted to a proper Excel bordering
      subrows = subrows.inject([]) do |array, subrow|
        if subrow.flatten == subrow
          array << subrow
        else
          array += subrow.collect(&:flatten)
        end
      end
      subrows.each_with_index do |subrow, idx|
        if idx == 0
          subrow.insert(0, show_row(row))
          subrow << show_result(row)
        else
          subrow.unshift("")
          subrow << ""
        end
      end
    end
    subrows
  end

  def cell(result)
    show_result result
  end

  def headers(list, first, first_in_col, last_in_col)
    if first_in_col # Open a new header row
      @header = [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
    end

    list.each do |column|
      @header << show_row(column)
      @header += [""] * (column.final_number(:column) - 1).abs
    end

    if last_in_col # Finish this header row
      @header += [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
      @headers << @header
    end
  end

  def footers(list, first, first_in_col, last_in_col)
    if first_in_col # Open a new footer row
      @footer = [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
    end

    list.each do |column|
      @footer << show_result(column)
      @footer += [""] * (column.final_number(:column) - 1).abs
    end

    if last_in_col # Finish this footer row
      if first
        @footer << show_result(query)
        @footer += [""] * (query.depth_of(:row) - 1).abs # TODO: add rowspan=query.depth_of(:column)
      else
        @footer += [""] * query.depth_of(:row) # TODO: add rowspan=query.depth_of(:column)
      end
      @footers << @footer
    end
  end

  def body(*line)
    @rows += line.flatten
  end

  def generate
    @spreadsheet ||= SpreadsheetBuilder.new(l(:label_money))

    available_cost_type_tabs(options[:cost_types]).each_with_index do |ary, idx|
      qry = CostQuery.deserialize(query.serialize)
      @unit_id = ary.first
      name = ary.last


      if @unit_id != 0
        qry.filter :cost_type_id, :operator => '=', :value => @unit_id.to_s, :display => false
        @cost_type = CostType.find(unit_id) if unit_id > 0
      end

      spreadsheet.worksheet(idx, name)
      run_walker
      build_spreadsheet
    end
    spreadsheet
  end

  def run_walker
    walker = query.walker

    walker.for_final_row &method(:final_row)
    walker.for_row &method(:row)
    walker.for_empty_cell { "" }
    walker.for_cell &method(:cell)

    @headers = []
    @header  = []
    walker.headers &method(:headers)

    @footers = []
    @footer  = []
    walker.reverse_headers &method(:footers)

    @rows = []
    walker.body &method(:body)
  end

  def build_spreadsheet
    spreadsheet.add_title("#{@project.name + " >> " if @project}#{l(:cost_reports_title)} (#{format_date(Date.today)})")
    spreadsheet.add_headers [label]
    row_length = @headers.first.length
    @headers.each {|head| spreadsheet.add_headers(head, spreadsheet.current_row) }
    @rows.in_groups_of(row_length).each {|body| spreadsheet.add_row(body) }
    @footers.each {|foot| spreadsheet.add_headers(foot, spreadsheet.current_row) }
    spreadsheet
  end

  def label
    "#{l(:caption_cost_type)}: " + case unit_id
    when -1 then l(:field_hours)
    when 0  then "EUR"
    else cost_type.unit_plural
    end
  end
end