class Widget::Controls::Reset < Widget::Base
  def render
    link_to_function l(:button_reset), "restore_query_inputs();", :class => 'icon icon-reload'
  end
end
