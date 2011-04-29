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

  def render_group_caption(type)
    content_tag :span do
      out = content_tag :span, :class => 'in_row group_by_caption' do
        l("label_#{type}".to_sym) # :label_rows, :label_columns
      end
      out += content_tag :span, :class => 'arrow in_row arrow_group_by_caption' do
        '' #cannot use tag here as it would generate <span ... /> which leads to wrong interpretation in most browsers
      end
      out.html_safe
    end
  end

  def render_group(type, initially_selected, show_help = false)
    initially_selected = initially_selected.map do |group_by|
      [group_by.class.underscore_name, l(group_by.class.label)]
    end
    content_tag :div,
        :id => "group_by_#{type}",
        :class => 'drag_target drag_container',
        :'data-initially-selected' => initially_selected.to_json.gsub('"', "'") do
      out = render_group_caption type
      out += content_tag :select, :id => "add_group_by_#{type}", :class => 'select-small' do
        content = content_tag :option, :value => '' do
          "-- #{l(:label_group_by_add)} --"
        end
        content += engine::GroupBy.all_grouped.sort_by do |label, group_by_ary|
          l(label)
        end.collect do |label, group_by_ary|
          content_tag :optgroup, :label => l(label) do
            render_options group_by_ary
          end
        end.join.html_safe
        content
      end
      if show_help
        maybe_with_help out.html_safe, {
          :icon => {
            :class => 'group-by-icon'
          },
          :tooltip => {
            :class => 'group-by-tip'
          }
        }
      else
        out.html_safe
      end
    end
  end

  def render
    write(content_tag :div, :id => 'group_by_area' do
      out =  render_group 'columns', @query.group_bys(:column), true
      out += render_group 'rows', @query.group_bys(:row)
      out.html_safe
    end)
  end
end
