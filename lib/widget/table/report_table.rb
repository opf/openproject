class Widget::Table::ReportTable < Widget::Table
  attr_accessor :walker

  def configure_query
    if @subject.depth_of(:row) == 0
      @subject.row(:singleton_value)
    elsif @subject.depth_of(:column) == 0
      @subject.column(:singleton_value)
    end
  end

  def configure_walker
    @walker ||= @subject.walker
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
      write(' '.html_safe) # XXX: This keeps the Apache from timing out on us. Keep-Alive byte!
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

  def render_tbody
    write "<tbody>"
    first = true
    odd = true
    walker.body do |line|
      if first
        line.gsub!("class='normal", "class='top")
        first = false
      end
      mark_penultimate_column! line
      write "<tr class='#{odd ? "odd" : "even"}'>#{line}</tr>"
      odd = !odd
    end
    write "</tbody>"
  end

  def mark_penultimate_column!(line)
    line.gsub! /(<td class='([^']+)'[^<]+<\/td>)[^<]*<th .+/ do |m|
      m.sub /class='([^']+)'/, 'class=\'\1 penultimate\''
    end
  end

  def render_thead
    return if (walker.headers || true) and walker.headers_empty?
    write "<thead>"
    walker.headers do |list, first, first_in_col, last_in_col|
      write '<tr>' if first_in_col
      if first
        write (content_tag :th, :rowspan => @subject.depth_of(:column), :colspan => @subject.depth_of(:row) do
          ""
        end)
      end
      list.each do |column|
        opts = { :colspan => column.final_number(:column) }
        opts.merge!(:class => "inner") if column.final?(:column)
        write (content_tag :th, opts do
          show_row column
        end)
      end
      if first
        write (content_tag :th, :rowspan => @subject.depth_of(:column), :colspan => @subject.depth_of(:row) do
          ""
        end)
      end
      write '</tr>' if last_in_col
    end
    write "</thead>"
  end

  def render_tfoot
    return if walker.headers_empty?
    write "<tfoot>"
    walker.reverse_headers do |list, first, first_in_col, last_in_col|
      if first_in_col
        write '<tr>'
        if first
          write (content_tag :th, :rowspan => @subject.depth_of(:column), :colspan => @subject.depth_of(:row), :class => 'top' do
            " "
          end)
        end
      end

      list.each do |column|
        opts = { :colspan => column.final_number(:column) }
        opts.merge!(:class => "inner") if first
        write (content_tag :th, opts do
          "#{show_result(column)}" #{debug_fields(column)}
        end)
      end
      if last_in_col
        if first
          write (content_tag :th,
          :rowspan => @subject.depth_of(:column),
          :colspan => @subject.depth_of(:row),
          :class => 'top result' do
            show_result @subject
          end)
        end
        write '</tr>'
      end
    end
    write "</tfoot>"
  end

  def debug_content
    content_tag :pre do
      debug_pre_content = "[ Query ]" +
      @subject.chain.each do |child|
        "#{h child.class.inspect}, #{h child.type}"
      end

      debug_pre_content += "[ RESULT ]"
      @subject.result.recursive_each_with_level do |level, result|
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

