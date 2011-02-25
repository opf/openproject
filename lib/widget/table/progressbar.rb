class Widget::Table::Progressbar < Widget::Base
  attr_accessor :threshhold

  def render
    @threshhold ||= 5
    size = @query.size
    content_tag :div, :id => "progressbar", :class => "form_controls",
                :"data-query-size" => size do
      if size > @threshhold
        content_tag :div, :id => "progressbar-load-table-question", :class => "form_controls" do
          content = content_tag :span, :id => "progressbar-text", :class => "form_controls" do
            ::I18n.translate(:load_query_question, :size => size)
          end
          content += content_tag :span,
            :id => "progressbar-yes",
            :'data-load' => 'true',
            :class => "form_controls",
            :'data-target' => url_for(:action => 'index', :set_filter => '1', :immediately => true) do
            ::I18n.t(:label_yes)
          end
          content += content_tag :span, :id => "progressbar-no", :'data-load' => 'false', :class => "form_controls" do
            ::I18n.t(:label_no)
          end
        end
      else
        render :partial => 'table'
      end
    end
  end
end
