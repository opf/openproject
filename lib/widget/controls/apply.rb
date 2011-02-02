class Widget::Controls::Apply < Widget::Base
  def render
    link_to({}, {:href => "#",
          :onclick => "
            selectAllOptions('group_by_rows');
            selectAllOptions('group_by_columns');
            new Ajax.Updater('result-table',
            '#{url_for(:action => 'index', :set_filter => '1')}',
            { asynchronous:true,
                    evalScripts:true,
                    postBody: Form.serialize('query_form') + '\\n' + $('filters').innerHTML });
                    return false;".html_safe,
          :class => 'button apply'}) do
        content_tag(:span, content_tag(:em, l(:button_apply)))
    end
  end
end
