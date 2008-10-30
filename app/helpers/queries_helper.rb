# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module QueriesHelper
  
  def operators_for_select(filter_type)
    Query.operators_by_filter_type[filter_type].collect {|o| [l(Query.operators[o]), o]}
  end
  
  def column_header(column)
    column.sortable ? sort_header_tag(column.sortable, :caption => column.caption,
                                                       :default_order => column.default_order) : 
                      content_tag('th', column.caption)
  end
  
  def column_content(column, issue)
    if column.is_a?(QueryCustomFieldColumn)
      cv = issue.custom_values.detect {|v| v.custom_field_id == column.custom_field.id}
      show_value(cv)
    else
      value = issue.send(column.name)
      if value.is_a?(Date)
        format_date(value)
      elsif value.is_a?(Time)
        format_time(value)
      else
        case column.name
        when :subject
        h((@project.nil? || @project != issue.project) ? "#{issue.project.name} - " : '') +
          link_to(h(value), :controller => 'issues', :action => 'show', :id => issue)
        when :done_ratio
          progress_bar(value, :width => '80px')
        when :fixed_version
          link_to(h(value), { :controller => 'versions', :action => 'show', :id => issue.fixed_version_id })
        else
          h(value)
        end
      end
    end
  end
end
