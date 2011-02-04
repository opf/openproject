class Widget::Controls::SaveAs < Widget::Base
  def render
    content_tag :span do
      button = link_to l(:button_save_as), {}, :class => 'breadcrumb_icon icon-save-as',
          :id => 'query-icon-save-as', :title => l(:button_save_as)
      button_form + render_popup
    end
  end

  def render_popup_form
    content_tag :form, :id => "query_save_as_form", :method => "post", :action => "#" do
      content_tag :p do
        label :query_name, l(:field_name)
        text_field_tag :query_name, @query.name || l(:label_default)
      end
      content_tag :p do
        label :query_is_public, l(:field_is_public)
        check_box_tag :query_is_public
      end
    end
  end

  def render_popup_buttons
    content_tag(:p) do
      save = link_to content_tag(:span, content_tag(:em, l(:button_save))), {},
        :id => "query-icon-save-button",
        :class => "button save",
        :href => "#",
        :"data-target" => url_for(:action => 'create', :set_filter => '1')
      cancel = link_to l(:button_cancel), {},
        :id => "query-icon-save-as-cancel",
        :class => 'icon icon-cancel'
      save + cancel
    end
  end

  def render_popup
    content_tag :div, :id => 'save_as_form', :class => "button_form" do
      render_popup_form + render_popup_buttons
    end
  end
end
