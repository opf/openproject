class Widget::Controls::Clear < Widget::Base
  def render
    link_to l(:button_clear), '#', :id => 'query-link-clear', :class => 'icon icon-clear'
  end
end
