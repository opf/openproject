class Widget::Settings < Widget::Base
  def render
    form_for @query, :url => "#", :html => {:id => 'query_form', :method => :post} do |query_form|
      content_tag :div, :id => "query_form_content" do

        fieldsets = render_widget Widget::Settings::Fieldset, :type => "filter" do
          render_widget Widget::Filters, @query
        end

        fieldsets += render_widget Widget::Settings::Fieldset, :type => "group_by" do
          render_widget Widget::GroupBys, @query
        end

        buttons = content_tag :p, :class => "buttons form_controls" do
          p = link_to({}, {:href => "#",
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
          p += link_to_function l(:button_reset), "restore_query_inputs();", :class => 'icon icon-reload'
        end

        fieldsets + buttons
      end
    end
  end
end
