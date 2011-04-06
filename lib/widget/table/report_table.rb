class Widget::Table::ReportTable < Widget::Table

  attr_accessor :walker

  def initialize(query)
    super
    @walker = query.walker
  end

  def configure_query
    if @query.depth_of(:row) == 0
      @query.row(:singleton_value)
    elsif @query.depth_of(:column) == 0
      @query.column(:singleton_value)
    end
  end

  def configure_walker
    @walker.for_final_row do |row, cells|
      html = "<th class='normal inner left'>#{show_row row}#{debug_fields(row)}</th>"
      html << cells.join
      html << "<th class='normal inner right'>#{show_result(row)}#{debug_fields(row)}</th>"
      html.html_safe
    end

    @walker.for_row do |row, subrows|
      subrows.flatten!
      unless row.fields.empty?
        subrows[0] = %Q{
            <th class='top left' rowspan='#{subrows.size}'>#{show_row row}#{debug_fields(row)}</th>
              #{subrows[0].gsub("class='normal", "class='top")}
            <th class='top right' rowspan='#{subrows.size}'>#{show_result(row)}#{debug_fields(row )}</th>
          }.html_safe
      end
      subrows.last.gsub!("class='normal", "class='bottom")
      subrows.last.gsub!("class='top", "class='bottom top")
      subrows
    end

    @walker.for_empty_cell { "<td class='normal empty'>&nbsp;</td>".html_safe }

    @walker.for_cell do |result|
      "<td class='normal right'>#{show_result result}#{debug_fields(result)}</td>".html_safe
    end
  end

  def render
    configure_query
    configure_walker
    write "<table class='list report'>"
    render_thead
    render_tfoot
    render_tbody
    write "</table>"
  end

  def render_thead
    write "<thead>"
    walker.headers do |list, first, first_in_col, last_in_col|
      write '<tr>' if first_in_col
      write "<th rowspan='#{@query.depth_of(:column)}' colspan='#{@query.depth_of(:row)}'></th>" if first
      list.each do |column|
        write "<th colspan=#{column.final_number(:column)}"
        write ' class="inner"' if column.final?(:column)
        write ">"
        write show_row(column)
        write "</th>"
      end
      write "<th rowspan='#{@query.depth_of(:column)}' colspan='#{@query.depth_of(:row)}'></th>" if first
      write '</tr>' if last_in_col
    end
    write "</thead>"
  end

  def render_tfoot
    write "<tfoot>"
    walker.reverse_headers do |list, first, first_in_col, last_in_col|
      write "<tr>" if first_in_col
      if first
        write "<th rowspan='#{@query.depth_of(:column)}'
                              colspan='#{@query.depth_of(:row)}' class='top'>&nbsp;</th>"
      end
      list.each do |column|
        write "<th colspan='#{column.final_number(:column)}'"
        write ' class="inner"' if first
        write '>'
        write show_result(column)
        # FIXME: write debug_fields(column)
        write "</th>"
      end
      if last_in_col
        if first
          write "<th rowspan='#{@query.depth_of(:column)}'
                              colspan='#{@query.depth_of(:row)}' class='top result'>"
          write show_result(@query)
          write "</th>"
        end
        write "</tr>"
      end
    end
    write "</tfoot>"
  end

  def render_tbody
    write "<tbody>"
    first = true
    odd = true
    walker.body do |line|
      if first
        line.gsub!("class='normal", "class='top")
        first = false
      end
      write "<tr class='#{odd ? "odd" : "even"}'>#{line}</tr>"
      odd = !odd
    end
    write "</tbody>"
  end

  def debug_content
    content_tag :pre do
      debug_pre_content = "[ Query ]" +
      @query.chain.each do |child|
        "#{h child.class.inspect}, #{h child.type}"
      end

      debug_pre_content += "[ RESULT ]"
      @query.result.recursive_each_with_level do |level, result|
        debug_pre_content += ">>> " * (level+1)
        debug_pre_content += h(result.inspect)
        debug_pre_content += "   " * (level+1)
        debug_pre_content += h(result.type.inspect)
        debug_pre_content += "   " * (level+1)
        debug_pre_content += h(result.fields.inspect)
      end
      debug_pre_content += "[ HEADER STACK ]"
      debug_pre_content += walker.header_stack.each do |l|
        ">>> #{l.inspect}"
      end
    end
  end
end

