class Widget::Table::Progressbar < Widget::Base
  attr_accessor :threshhold

  def render
    @threshhold ||= 5
    size = @query.size
    content_tag :div, :class => "progressbar", :style => "display:none",
                :"data-query-size" => size do
      if size > @threshhold
        content_tag :div, :id => "progressbar-load-table-question" do
          tag(:span, ::I18n.t(:load_query_question, size), :id => "progressbar-text")
          tag(:span, ::I18n.t(:label_yes), :id => "progressbar-yes")
          tag(:span, ::I18n.t(:label_no), :id => "progressbar-no")
        end
      else
        tag :span, :id => "progressbar-load-table-directly"
      end
    end
  end
end
