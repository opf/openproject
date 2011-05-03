
class Widget::Controls::Clear < Widget::Base
  def render
    html = link_to(content_tag(:span, content_tag(:em, l(:"button_clear"), :class => "button-icon icon-clear")),
                  '#', :id => 'query-link-clear', :class => 'button secondary')
    write html
    maybe_with_help
  end
end
