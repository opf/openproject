class Widget::GroupBys < Widget::Base
  extend ProactiveAutoloader

  def render_options(group_by_ary)
    group_by_ary.sort_by do |group_by|
      l(group_by.label)
    end.collect do |group_by|
      next unless group_by.selectable?
      content_tag :option, :value => group_by.underscore_name, :'data-label' => "#{l(group_by.label)}" do
        l(group_by.label)
      end
    end.join.html_safe
  end

  def render_group(type, initially_selected)
    initially_selected = initially_selected.map { |group_by| group_by.class.underscore_name }
    content_tag :div,
        :id => "group_by_#{type}",
        :class => 'drag_target drag_container',
        :'data-initially-selected' => initially_selected.to_json.gsub('"', "'") do
      content_tag :select, :id => "add_group_by_#{type}", :class => 'select-small' do
        content = tag :option, :value => ''
        content += engine::GroupBy.all_grouped.sort_by do |label, group_by_ary|
          l(label)
        end.collect do |label, group_by_ary|
          content_tag :optgroup, :label => l(label) do
            render_options group_by_ary
          end
        end.join.html_safe
        content
      end.html_safe
    end
  end

  def render
    content_tag :div, :id => 'group_by_area' do
      out  = l(:label_columns)
      out += render_group 'columns', @query.group_bys(:column)
      out += l(:label_rows)
      out += render_group 'rows', @query.group_bys(:row)
      out.html_safe
    end
  end
end
