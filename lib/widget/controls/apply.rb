
class Widget::Controls::Apply < Widget::Controls
  def render
    write link_to content_tag(:span, content_tag(:em, l(:button_apply))), {},
      :href => "#", :id => "query-icon-apply-button",
      :class => "button apply reporting_button",
      :"data-target" => url_for(:action => 'index', :set_filter => '1')
  end
end
