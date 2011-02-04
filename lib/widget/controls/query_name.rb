class Widget::Controls::QueryName < Widget::Base
  def render
    options = { :id => "query_saved_name", "data-translations" => translations }
    if @query.new_record?
      name = l(:label_save_this_query)
      icon = ""
    else
      name = @query.name
      icon = content_tag :a, :href => "#", :class => 'breadcrumb_icon icon-edit',
      :id => "query-name-edit-button", :title => "#{l(:button_rename)}" do
        l(:button_rename)
      end
      options["data-is_public"] = @query.is_public
      options["data-update-url"] = url_for(:action => "update", :id => @query.id)
    end
    content_tag(:span, name, options) + icon
  end

  def translations
    { :rename => l(:button_rename),
      :cancel => l(:button_cancel),
      :loading => l(:label_loading),
      :clickToEdit => l(:label_click_to_edit),
      :isPublic => l(:field_is_public),
      :saving => l(:label_saving) }.to_json
  end
end
