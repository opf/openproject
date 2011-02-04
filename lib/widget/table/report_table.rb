class Widget::Table::ReportTable < Widget::Table

  attr_accessor :walker

  def initialize(report, options = {})
    super
    @walker = @query.walker
  end

  def render
    configure_walker
    content = content_tag :table, :class => 'list report' do
      header + footer + body
    end
    content += (debug_content if debug?)
  end

  def configure_walker
    walker.for_final_row do |row, cells|
      final_row_html = content_tag :th, :class => 'normal inner left' do
        "#{show_row(row)}#{debug_fields(row)}"
      end
      final_row_html += cells.join.html_safe
      final_row_html += content_tag :th, :class => 'normal inner right' do
        "#{show_result(row)}#{debug_fields(row)}"
      end
      final_row_html
    end

    walker.for_row do |row, subrows|
      subrows.flatten!
      unless row.fields.empty?
        subrows[0] = ''
        subrows[0] += content_tag(:th, :class => 'top left', :rowspan => subrows.size) do
          "#{show_row(row)}#{debug_fields(row)}"
        end
        subrows[0].gsub("class='normal'", "class='top'")
        subrows[0] += content_tag(:th, :class => 'top right', :rowspan => subrows.size) do
          "#{show_result(row)}#{debug_fields(row)}"
        end
      end
      subrows.last.gsub!("class='normal", "class='bottom")
      subrows.last.gsub!("class='top", "class='bottom top")
      subrows
    end

    walker.for_empty_cell do
      content_tag(:td, :class =>'normal empty') do
        " "
      end
    end

    walker.for_cell do |result|
      content_tag :td, :class => 'normal right' do
        "#{show_result(result)}#{debug_fields(result)}"
      end
    end
  end

  def header
    header_content = ""
    walker.headers do |list, first, first_in_col, last_in_col|
      header_content += '<tr>' if first_in_col
      if first
        header_content += content_tag :th, :rowspan => @query.depth_of(:column), :colspan => @query.depth_of(:row) do
          ""
        end
      end
      list.each do |column|
        header_content += content_tag :th, :colspan => column.final_number(:column), :class => column.final?(:column) ? "inner" : "" do
          show_row column
        end
      end
      if first
        header_content += content_tag :th, :rowspan => @query.depth_of(:column), :colspan => @query.depth_of(:row) do
          ""
        end
      end
      header_content += '</tr>' if last_in_col
    end
    content_tag :thead, header_content.html_safe
  end

  def footer
    reverse_headers = ""
    walker.reverse_headers do |list, first, first_in_col, last_in_col|
      if first_in_col
        reverse_headers += '<tr>'
        if first
          reverse_headers += content_tag :th, :rowspan => @query.depth_of(:column), :colspan => @query.depth_of(:row), :class => 'top' do
            " "
          end
        end
      end

      list.each do |column|
        reverse_headers += content_tag :th, :colspan => column.final_number(:column), :class => (first ? "inner" : "") do
          "#{show_result(column)}#{debug_fields(column)}"
        end
      end
      if last_in_col
        if first
          reverse_headers += content_tag :th,
            :rowspan => @query.depth_of(:column),
            :colspan => @query.depth_of(:row),
            :class => 'top result' do
              show_result @query
          end
        end
        reverse_headers += '</tr>'
      end
    end
    content_tag :tfoot, reverse_headers.html_safe
  end

  def body
    first = true
    walker_body = ""
    walker.body do |line|
      if first
        line.gsub!("class='normal", "class='top")
        first = false
      end
      walker_body += content_tag :tr, :class => cycle("odd", "even") do
        line
      end
    end
    content_tag :tbody, walker_body.html_safe
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

