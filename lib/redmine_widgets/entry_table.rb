require 'sortable_init'

class Widget::Table::EntryTable < Widget::Table
  Fields = [:spent_on, :user_id, :activity_id, :issue_id, :comments, :project_id]

  detailed_table self

  def render
    content = ""
    content = content_tag :table, { :class => "report detail-report", :id => "sortable-table" } do
      content << head + foot + body
    end
    # FIXME do that js-only, like a man's man
    render_widget Widget::Table::SortableInit, @subject, :to => content, :sort_first_row => true
    write content.html_safe
  end

  def head
    content_tag :thead do
      content_tag :tr do
        Fields.collect { |field| content_tag(:th) { label_for(field) } }.join +
          content_tag(:th, :class => 'right') { cost_type.try(:unit_plural) || l(:units) } +
          content_tag(:th, :class => 'right') { l(:field_costs) }
      end
    end
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        if show_result(@subject, 0) != show_result(@subject)
          content_tag(:th, show_result(@subject), :class => "inner right", :colspan => Fields.size + 1) +
            content_tag(:th, show_result(@subject, 0), :class => "result right")
        else
          content_tag(:th, show_result(@subject), :class => "result right", :colspan => Fields.size + 2)
        end + content_tag(:th, "", :class => "unsortable")
      end
    end
  end

  def body
    content_tag :tbody do
      rows = "".html_safe
      @subject.each_direct_result do |result|
        odd = !odd
        rows << (content_tag(:tr, :class => (odd ? "odd" : "even")) do
                   cells = "".html_safe
                   Fields.each do |field|
                     cells << content_tag(:td, show_field(field, result.fields[field.to_s]),
                                          :"raw-data" => raw_field(field, result.fields[field.to_s]),
                                          :class => "left")
                   end
                   cells << (content_tag(:td, show_result(result, result.fields['cost_type_id'].to_i),
                                         :class => "units right", :"raw-data" => result.units))
                   cells << (content_tag(:td, (show_result(result, 0)),
                                         :class => "currency right", :"raw-data" => result.real_costs))
                   cells << (content_tag :td, :style => "width: 40px" do
                               icons = ""
                               with_project(result.fields['project_id']) do
                                 if entry_for(result).editable_by? User.current
                                   icons = link_to(image_tag('edit_png'), action_for(result, :action => 'edit'),
                                                   :title => l(:button_edit))
                                   icons << link_to(image_tag('delete.png'), action_for(result, :action => 'destroy'),
                                                    :title  => l(:button_edit), :confirm  => l(:text_are_you_sure),
                                                    :method => :post,           :title    => l(:button_delete))
                                   icons
                                 end
                               end
                               icons
                             end)
                   cells
                 end)
        if params[:debug]
          rows << (content_tag :tr do
                     content_tag :td, :colspan => Fields.size + 3 do
                       result.fields.reject {|k,v| Fields.include? k.to_sym }.inspect
                     end
                   end)
        end
      end
      rows
    end
  end
end
