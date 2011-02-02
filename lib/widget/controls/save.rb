class Widget::Controls::Save < Widget::Base
  def render
    unless @query.new_record?
      link_to({}, {:href => "#",
          :onclick => "
            selectAllOptions('group_by_rows');
            selectAllOptions('group_by_columns');
            new Ajax.Updater('result-table',
            '#{url_for(:action => 'update', :id => @query.id, :set_filter => '1')}',
            { asynchronous: true,
              evalScripts: true,
              postBody: Form.serialize('query_form') });
            return false;",
          :class => 'breadcrumb_icon icon-save',
          :title => l(:button_save)}) do
        content_tag(:span, content_tag(:em, l(:button_save)))
      end
    else
      ""
    end
  end
end
