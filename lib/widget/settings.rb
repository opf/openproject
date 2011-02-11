class Widget::Settings < Widget::Base
  def render
    form_tag("#", {:id => 'query_form', :method => :post}) do |query_form|
      content_tag :div, :id => "query_form_content" do

        fieldsets = render_widget Widget::Settings::Fieldset, @query, { :type => "filter" } do
          render_widget Widget::Filters, @query
        end

        fieldsets += render_widget Widget::Settings::Fieldset, @query, { :type => "group_by" } do
          render_widget Widget::GroupBys, @query
        end

        controls = content_tag :div, :class => "buttons form_controls" do
          widgets = render_widget(Widget::Controls::Apply, @query)
          render_widget(Widget::Controls::Save, @query, :to => widgets)
          render_widget(Widget::Controls::SaveAs, @query, :to => widgets)
          render_widget(Widget::Controls::Clear, @query, :to => widgets)
          render_widget(Widget::Controls::Delete, @query, :to => widgets)
        end

        fieldsets + controls
      end
    end
  end
end
