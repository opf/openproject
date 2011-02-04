class Widget::Controls::Reset < Widget::Base
  def render
    link_to_function l(:button_reset), "alert('Broken')", :class => 'icon icon-reload'
  end
end
