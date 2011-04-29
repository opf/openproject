class Widget::Table::Progressbar < Widget::Base
  dont_cache!

  def render
    if Widget::Table::ReportTable.new(@query).cached? || @query.size <= THRESHHOLD
      render_widget Widget::Table::ReportTable, @query, :to => (@output ||= "".html_safe)
    else
      write(content_tag :label, :style => "display:none" do
              content_tag(:div, l(:label_progress_bar_explanation).html_safe) +
                render_progress_bar
            end)
    end
  end

  def render_progress_bar
    content_tag(:div, "",
                :id => "progressbar",
                :class => "form_controls",
                :"data-query-size" => @query.size,
                :"data-translation" => ::I18n.translate(:label_load_query_question, :size => @query.size),
                :"data-target" => url_for(:action => 'index', :set_filter => '1', :immediately => true))
  end
end
