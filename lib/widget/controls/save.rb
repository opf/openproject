class Widget::Controls::Save < Widget::Base
  def render
    unless @query.new_record?
      link_to content_tag(:span, content_tag(:em, l(:button_save))), {},
        :href => "#", :id => "query-breadcrumb-save",
        :class => "breadcrumb_icon icon-save",
        :title => l(:button_save),
        :"data-target" => url_for(:action => 'update', :id => @query.id, :set_filter => '1')
    else
      ""
    end
  end
end
