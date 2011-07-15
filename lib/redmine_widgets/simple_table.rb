require 'sortable_init'

class Widget::Table::SimpleTable < Widget::Table
  simple_table self

  def render
    @list = @subject.collect {|r| r.important_fields }.flatten.uniq
    @show_units = @list.include? "cost_type_id"

    content = ""
    content = content_tag :table, { :class => "report", :id => "sortable-table" } do
      content << head + foot + body
    end
    # FIXME do that js-only, like a man's man
    render_widget Widget::Table::SortableInit, @subject, :to => content
    write content.html_safe
  end

  def head
    content_tag :thead do
      content_tag :tr do
        tr_tag = "".html_safe
        @list.each do |field|
          tr_tag << content_tag(:th, :class => "right") { label_for(field) }
        end
        tr_tag << content_tag(:th, :class => "right") { label_for(:field_units) } if @show_units
        tr_tag << content_tag(:th, :class => "right") { label_for(:label_sum) }
      end
    end.html_safe
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        tr_tag = content_tag(:th, :class => "result inner", :colspan => @list.size) {""}
        tr_tag << (content_tag(:th, @show_units ? {:class => "result right", :collspan => "2"} : {:class => "result right"}) do
          show_result @subject
        end)
      end
    end.html_safe
  end

  def body
    content_tag :tbody do
      body_content = "".html_safe
      @subject.each do |result|
        body_content << (content_tag :tr, :class => cycle("odd", "even") do
          tr_tag = content_tag :td, :'raw-data' => raw_field(*result.fields.first) do
            show_row result
          end
          if @show_units
            tr_tag << (content_tag :td, :'raw-data' => result.units do
              show_result result, result.fields[:cost_type_id].to_i
            end)
          end
          tr_tag << (content_tag :td, :'raw-data' => result.real_costs do
            show_result result
          end)
        end)
        body_content << (content_tag :tr do
          content_tag :td, :colspan => @list.size + 3 do
            result.fields.reject {|k,v| @list.include? k.to_sym }.inspect
          end
        end) if params[:debug]
      end
      body_content
    end.html_safe
  end
end
