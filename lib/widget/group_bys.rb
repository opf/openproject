class Widget::GroupBys < Widget::Base
  extend ProactiveAutoloader

  def render_row_1_with_columns
    content_tag :tr do
      tr = content_tag :td, " ", :colspan => "2"
      tr += content_tag :td, :align => "center", :valign => "right" do
        render_up_down_buttons("columns")
      end
      tr += content_tag :td, :valign => "middle" do
        content_tag(:h3, "Columns") + selected_group_bys("columns")
      end
    end
  end

  def render_row_2_with_up_down
    content_tag :tr do
      tr = content_tag :td, " "
      tr += content_tag :td, :valign => "bottom", :style => "padding-bottom: 0;" do
        content_tag :h3, "Rows"
      end
      tr += content_tag :td, " "
      tr += content_tag :td, :align => "left", :valign => "left" do
        render_move_buttons("columns", "Up", "Down")
      end
    end
  end

  def render_row_3_with_rows_and_group_bys
    content_tag :tr do
      tr = content_tag :td, :align => "center", :valign => "top" do
        render_up_down_buttons("rows")
      end
      tr += content_tag :td ,:style => "padding-left: 0pt;", :valign => "top" do
        selected_group_bys("rows")
      end
      tr += content_tag :td, :align => "center", :valign => "top" do
        render_move_buttons("rows", "Left", "Right", true)
      end
      tr += content_tag :td do
        render_grouped_group_bys
      end
    end
  end

  #TODO: replace me with a drag&drop group_by selector
  def render
    content_tag :table, :style => "border-collapse: collapse; border: 0pt none;",
                        :id => "group_by_table" do
      content_tag :tbody do
        render_row_1_with_columns +
          render_row_2_with_up_down +
          render_row_3_with_rows_and_group_bys
      end
    end
  end

  def selected_group_bys(axis)
    content_tag :select, "", :style => "width: 180px;", :size => "4",
        :name => "groups[#{axis}][]", :multiple => "multiple",
        :id => "group_by_#{axis}"
  end

  def render_up_down_buttons(axis)
    render_sort_button(axis, "Up") + tag(:br) + render_sort_button(axis, "Down")
  end

  def render_sort_button(axis, dir)
    tag :input, :type => "button", :class => "buttons group_by sort sort#{dir}",
        :onclick => "moveOption#{dir}(this.form.group_by_#{axis});"
  end

  def render_move_buttons(axis, to, from, br = false)
    canvas = render_move_option_button(axis, to)
    canvas += tag(:br) if br
    canvas + render_move_option_button(axis, from)
  end

  def render_move_option_button(axis, dir)
    tag :input, :type => "button", :class => "buttons group_by move move#{dir}",
        :onclick => "moveOptions(this.form.group_by_container, this.form.group_by_#{axis});"
  end

  def render_grouped_group_bys
    content_tag :select, :style => "width: 180px;", :size => "9", :multiple => "multiple", :id => "group_by_container" do
      engine::GroupBy.all_grouped.sort_by do |label, group_by_ary|
        l(label)
      end.collect do |label, group_by_ary|
        content_tag :optgroup, :label => l(label), :"data-category" => label.to_s do
          group_by_ary.sort_by do |g|
            l(g.label)
          end.collect do |group_by|
            next unless group_by.selectable?
            content_tag :option, :value => group_by.underscore_name, :"data-category" => label.to_s do
              l(group_by.label)
            end
          end.compact.join.html_safe
        end
      end.join.html_safe
    end
  end

end
