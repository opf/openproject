#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class Widget::Table::EntryTable < Widget::Table
  Fields = [:spent_on, :user_id, :activity_id, :work_package_id, :comments, :project_id]

  detailed_table self

  def render
    content = content_tag :table, { class: "report detail-report", id: "sortable-table" } do
      concat head
      concat foot
      concat body
    end
    # FIXME do that js-only, like a man's man
    render_widget Widget::Table::SortableInit, @subject, to: content, sort_first_row: true
    write content
  end

  def head
    content_tag :thead do
      content_tag :tr do
        Fields.collect { |field| concat content_tag(:th) { label_for(field) } }
        concat content_tag(:th, class: 'right') { cost_type.try(:unit_plural) || l(:units) }
        concat content_tag(:th, class: 'right') { CostEntry.human_attribute_name(:costs) }
        hit = false
        @subject.each_direct_result do |result|
          next if hit
          if entry_for(result).editable_by? User.current
            concat content_tag(:th, class: "unsortable") { "&nbsp;".html_safe }
            hit = true
          end
        end
      end
    end
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        if show_result(@subject, 0) != show_result(@subject)
          concat content_tag(:th, show_result(@subject), class: "inner right", colspan: Fields.size + 1)
          concat content_tag(:th, show_result(@subject, 0), class: "result right")
        else
          concat content_tag(:th, show_result(@subject), class: "result right", colspan: Fields.size + 2)
        end
        concat content_tag(:th, "", class: "unsortable")
      end
    end
  end

  def body
    content_tag :tbody do
      rows = "".html_safe
      @subject.each_direct_result do |result|
        odd = !odd
        rows << (content_tag(:tr, class: (odd ? "odd" : "even")) do
          "".html_safe
          Fields.each do |field|
            concat content_tag(:td, show_field(field, result.fields[field.to_s]).html_safe,
                               :"raw-data" => raw_field(field, result.fields[field.to_s]),
                               class: "left")
          end
          concat content_tag :td, show_result(result, result.fields['cost_type_id'].to_i).html_safe,
            class: "units right", :"raw-data" => result.units
          concat content_tag :td, (show_result(result, 0)).html_safe,
            class: "currency right", :"raw-data" => result.real_costs
          concat content_tag :td, icons(result), style: "width: 40px"
        end)
      end
      rows
    end
  end

  def icons(result)
    icons = ""
    with_project(result.fields['project_id']) do
      if entry_for(result).editable_by? User.current
        icons = link_to(icon_wrapper('icon-context icon-edit', l(:button_edit)),
                        action_for(result, action: 'edit'),
                        class: 'no-decoration-on-hover',
                        title: l(:button_edit))
        icons << link_to(icon_wrapper('icon-context icon-delete', l(:button_delete)),
                        (action_for(result, action: 'destroy').reverse_merge(authenticity_token: form_authenticity_token)),
                        title:  l(:button_edit),
                        confirm:  l(:text_are_you_sure),
                        method: :delete,
                        class: 'no-decoration-on-hover',
                        title:    l(:button_delete))
      end
    end
    icons
  end
end
