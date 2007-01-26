# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

module IssuesHelper

  def show_detail(detail, no_html=false)
    case detail.property
    when 'attr'
      label = l(("field_" + detail.prop_key.to_s.gsub(/\_id$/, "")).to_sym)   
      case detail.prop_key
      when 'due_date', 'start_date'
        value = format_date(detail.value.to_date) if detail.value
        old_value = format_date(detail.old_value.to_date) if detail.old_value
      when 'status_id'
        s = IssueStatus.find_by_id(detail.value) and value = s.name if detail.value
        s = IssueStatus.find_by_id(detail.old_value) and old_value = s.name if detail.old_value
      when 'assigned_to_id'
        u = User.find_by_id(detail.value) and value = u.name if detail.value
        u = User.find_by_id(detail.old_value) and old_value = u.name if detail.old_value
      when 'priority_id'
        e = Enumeration.find_by_id(detail.value) and value = e.name if detail.value
        e = Enumeration.find_by_id(detail.old_value) and old_value = e.name if detail.old_value
      when 'category_id'
        c = IssueCategory.find_by_id(detail.value) and value = c.name if detail.value
        c = IssueCategory.find_by_id(detail.old_value) and old_value = c.name if detail.old_value
      when 'fixed_version_id'
        v = Version.find_by_id(detail.value) and value = v.name if detail.value
        v = Version.find_by_id(detail.old_value) and old_value = v.name if detail.old_value
      end
    when 'cf'
      custom_field = CustomField.find_by_id(detail.prop_key)
      if custom_field
        label = custom_field.name
        value = format_value(detail.value, custom_field.field_format) if detail.value
        old_value = format_value(detail.old_value, custom_field.field_format) if detail.old_value
      end
    end
       
    label ||= detail.prop_key
    value ||= detail.value
    old_value ||= detail.old_value
    
    unless no_html
      label = content_tag('strong', label)
      old_value = content_tag("i", h(old_value)) if detail.old_value
      old_value = content_tag("strike", old_value) if detail.old_value and (!detail.value or detail.value.empty?)
      value = content_tag("i", h(value)) if value
    end
    
    if detail.value and !detail.value.to_s.empty?
      if old_value
        label + " " + l(:text_journal_changed, old_value, value)
      else
        label + " " + l(:text_journal_set_to, value)
      end
    else
      label + " " + l(:text_journal_deleted) + " (#{old_value})"
    end
  end
end
