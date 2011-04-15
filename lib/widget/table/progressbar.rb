class Widget::Table::Progressbar < Widget::Base
  THRESHHOLD = 500

  dont_cache!

  def render
    if Widget::Table::ReportTable.new(@query).cached? || (size = @query.size) <= THRESHHOLD
      render_widget Widget::Table::ReportTable, @query, :to => (@output ||= "".html_safe)
    else
      write(content_tag :div,
        :id => "progressbar",
        :class => "form_controls",
        :"data-query-size" => size,
        :"data-translation" => ::I18n.translate(:label_load_query_question, :size => size),
        :"data-target" => url_for(:action => 'index', :set_filter => '1', :immediately => true) do
      end)
    end
  end
end
