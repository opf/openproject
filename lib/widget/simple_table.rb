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

class Widget::Table::SimpleTable < Widget::Table
  simple_table self

  def render
    @list = @subject.collect {|r| r.important_fields }.flatten.uniq
    @show_units = @list.include? "cost_type_id"

    content = content_tag :table, { class: "report", id: "sortable-table" } do
      concat head
      concat foot
      concat body
    end
    # FIXME do that js-only, like a man's man
    render_widget Widget::Table::SortableInit, @subject, to: content
    write content.html_safe
  end

  def head
    content_tag :thead do
      content_tag :tr do
        @list.each do |field|
          concat content_tag(:th, class: "right") { label_for(field) }
        end
        concat content_tag(:th, class: "right") { label_for(:units) } if @show_units
        concat content_tag(:th, class: "right") { label_for(:label_sum) }
      end
    end
  end

  def foot
    content_tag :tfoot do
      content_tag :tr do
        concat content_tag(:th, '', class: "result inner", colspan: @list.size)
        concat content_tag(:th, show_result(@subject), (@show_units ? {class: "result right", colspan: "2"} : {class: "result right"}))
      end
    end
  end

  def body
    content_tag :tbody do
      @subject.each do |result|
        concat (content_tag :tr, class: cycle("odd", "even") do
          concat (content_tag :td, :'raw-data' => raw_field(*result.fields.first) do
            show_row result
          end)
          if @show_units
            concat (content_tag :td, :'raw-data' => result.units do
              show_result result, result.fields[:cost_type_id].to_i
            end)
          end
          concat (content_tag :td, :'raw-data' => result.real_costs do
            show_result result
          end)
        end)
      end
    end
  end
end
