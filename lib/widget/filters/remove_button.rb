class Widget::Filters::RemoveButton < Widget::Filters::Base
  def render
    content_tag :td, :width => "25px" do
      tag :input, :id => "rm_#{filter_class.underscore_name}",
        :name => "fields[]", :type => "button", :value => "",
        :class => "icon filter_rem icon-filter-rem",
        :onclick => "remove_filter('#{filter_class.underscore_name}');"
    end
  end
end
