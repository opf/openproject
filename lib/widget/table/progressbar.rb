class Widget::Table::Progressbar < Widget::Base
  THRESHHOLD = 500

  def render
    if cached? || size = @query.size >= THRESHHOLD
      write(content_tag :div, :id => "progressbar", :class => "form_controls",
      :"data-query-size" => size do
        content_tag :div, :id => "progressbar-load-table-question", :class => "form_controls" do
          content = content_tag :span, :id => "progressbar-text", :class => "form_controls" do
            ::I18n.translate(:label_load_query_question, :size => size)
          end

          content += content_tag :p, :class => "buttons" do
            p_content = content_tag :a, :class => "reporting_button button" do
              content_tag :span,
              :id => "progressbar-yes",
              :'data-load' => 'true',
              :class => "form_controls",
              :'data-target' => url_for(:action => 'index', :set_filter => '1', :immediately => true) do
                content_tag :em do
                  ::I18n.t(:label_yes)
                end
              end
            end

            p_content += content_tag :a, :class => "reporting_button button" do
              content_tag :span,
              :id => "progressbar-no",
              :'data-load' => 'false',
              :class => "form_controls" do
                content_tag :em do
                  ::I18n.t(:label_no)
                end
              end
            end
          end
          content
        end
      end)
    else
      render_widget Widget::Table::ReportTable, @query, :to => (@output ||= "".html_safe)
    end
  end
end
