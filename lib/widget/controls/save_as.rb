class Widget::Controls::SaveAs < Widget::Base
  def render
    if @query.new_record?
      link_name = l(:button_save)
      icon = "icon-save"
    else
      link_name = l(:button_save_as)
      icon = "icon-save-as"
    end
    button = link_to content_tag(:span, content_tag(:em, link_name, :class => "button-icon icon-save-as")), "#",
        :class => "button secondary",
        :id => 'query-icon-save-as', :title => link_name
    button + render_popup
  end

  def render_popup_form
    name = content_tag :p do
      label_tag(:query_name, l(:field_name)) +
      text_field_tag(:query_name, @query.name)
    end
    box = content_tag :p do
      label_tag(:query_is_public, l(:field_is_public)) +
      check_box_tag(:query_is_public)
    end
    name + box
  end

  def render_popup_buttons
    content_tag(:p) do
      save = link_to content_tag(:span, content_tag(:em, l(:button_save))), "#",
        :id => "query-icon-save-button",
        :class => "button reporting_button save",
        :"data-target" => url_for(:action => 'create', :set_filter => '1')
      cancel = link_to l(:button_cancel), "#",
        :id => "query-icon-save-as-cancel",
        :class => 'icon icon-cancel'
      save + cancel
    end
  end

  def render_popup
    content_tag :div, :id => 'save_as_form', :class => "button_form", :style => "display:none" do
      render_popup_form + render_popup_buttons
    end
  end
end
