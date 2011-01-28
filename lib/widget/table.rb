class Widget::Table < Widget::Base
  def render
    if @query.group_bys.empty?
      widget = Widget::Table::DetailedTable
    else
      if @query.depth_of(:column) == 0
        @query.column(:singleton_value)
      elsif @query.depth_of(:row) == 0
        @query.row(:singleton_value)
      end
      widget = Widget::Table::ReportTable
    end

    content_tag :div, :id => "result-table" do
      if @query.result.count > 0
        render_widget widget, @query
      else
        content_tag :p, l(:label_no_data), :class => "nodata"
      end
    end
  end
end
