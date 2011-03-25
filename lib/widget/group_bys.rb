class Widget::GroupBys < Widget::Base
  extend ProactiveAutoloader

  def render_group(type)
    content_tag :div, :id => "group_by_#{type}", :class => 'drag_target drag_container' do
      out = ''
      #TODO render existing group_bys of type <type>
      out += content_tag :select, :id => "add_group_by_#{type}", :name => "groups[#{type}][]", :class => 'select-small' do
        options  = tag :option, :value => ''
        engine::GroupBy.all.each do |group_by_class|
          options += content_tag :option, :value => group_by_class.underscore_name, :'data-label' => "#{l(group_by_class.label)}" do
            l(group_by_class.label)
          end
        end
        options
      end
      out.html_safe
    end
  end

  def render
    content_tag :div, :id => 'group_by_area' do
      out  = l(:label_columns)
      out += render_group 'columns'
      out += l(:label_rows)
      out += render_group 'rows'
      out.html_safe
    end
  end
end
