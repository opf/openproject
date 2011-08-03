class Widget::Controls::QueryName < Widget::Controls
  dont_cache! # The name might change, but the query stays the same...

  def render
    options = { :id => "query_saved_name", "data-translations" => translations }
    if @subject.new_record?
      name = l(:label_new_report)
      icon = ""
    else
      name = @subject.name
      if @options[:can_rename]
        icon = content_tag :a, :href => "#", :class => 'breadcrumb_icon icon-edit',
        :id => "query-name-edit-button", :title => "#{l(:button_rename)}" do
          l(:button_rename)
        end
        options["data-update-url"] = url_for(:action => "rename", :id => @subject.id)
      end
      options["data-is_public"] = @subject.public?
      options["data-is_new"] = @subject.new_record?
    end
    write(content_tag(:span, name, options) + icon.to_s)
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
