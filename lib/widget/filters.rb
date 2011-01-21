class Widget::Filters < Widget::Base
  extend ProactiveAutoloader

  def render
    table = content_tag :table, :width => "100%" do
      content_tag :tr do
        content_tag :td do
          content_tag :table, :id => "filter_table" do
            active_filters = @query.filters.select {|f| f.class.display? }
            engine::Filter.all.collect do |filter|
              content_tag :tr, :id => "tr_#{filter.underscore_name}",
                  :class => filter, :style => "display:none" do
                render_filter filter, active_filters.detect {|f| f.class == filter }
              end
            end.join("\n")
          end
        end
      end
    end
    select = content_tag :div, :id => "add_filter_block" do
      select_tag 'add_filter_select',
          options_for_select([["-- #{l(:label_filter_add)} --",'']] + selectables),
          :onchange => "add_filter(this);",
          :class => "select-small",
          :name => nil
    end
    (table + "\n" + select)
  end

  def selectables
    filters = engine::Filter.all
    filters.sort_by do |filter|
      l(filter.label)
    end.select do |filter|
      filter.selectable?
    end.collect do |filter|
      [ l(filter.label), filter.underscore_name ]
    end
  end

  def render_filter(f_cls, f_inst)
    html = ""
    f = f_inst || f_cls
    render_widget Filters::Label, f, :to => html
    render_widget Filters::Operators, f, :to => html
    if engine::Operator.string_operators.all? { |o| f_cls.available_operators.include? o }
      render_widget Filters::TextBox, f, :to => html
    elsif engine::Operator.time_operators.all? { |o| f_cls.available_operators.include? o }
      render_widget Filters::Date, f, :to => html
    elsif engine::Operator.integer_operators.all? {|o| f_cls.available_operators.include? o }
      if f_cls.available_values.empty?
        render_widget Filters::TextBox, f, :to => html
      else
        render_widget Filters::MultiValues, f, :to => html
      end
    else
      render_widget Filters::MultiValues, f, :to => html
    end
    html
  end
end
