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

module CustomFieldsHelper

  def custom_fields_tabs
    tabs = [{:name => 'IssueCustomField', :label => :label_issue_plural},
            {:name => 'TimeEntryCustomField', :label => :label_spent_time},
            {:name => 'ProjectCustomField', :label => :label_project_plural},
            {:name => 'UserCustomField', :label => :label_user_plural}
            ]
  end
  
  # Return custom field html tag corresponding to its format
  def custom_field_tag(name, custom_value)	
    custom_field = custom_value.custom_field
    field_name = "#{name}[custom_field_values][#{custom_field.id}]"
    field_id = "#{name}_custom_field_values_#{custom_field.id}"
    
    case custom_field.field_format
    when "date"
      text_field_tag(field_name, custom_value.value, :id => field_id, :size => 10) + 
      calendar_for(field_id)
    when "text"
      text_area_tag(field_name, custom_value.value, :id => field_id, :rows => 3, :style => 'width:90%')
    when "bool"
      check_box_tag(field_name, '1', custom_value.true?, :id => field_id) + hidden_field_tag(field_name, '0')
    when "list"
      blank_option = custom_field.is_required? ?
                       (custom_field.default_value.blank? ? "<option value=\"\">--- #{l(:actionview_instancetag_blank_option)} ---</option>" : '') : 
                       '<option></option>'
      select_tag(field_name, blank_option + options_for_select(custom_field.possible_values, custom_value.value), :id => field_id)
    else
      text_field_tag(field_name, custom_value.value, :id => field_id)
    end
  end
  
  # Return custom field label tag
  def custom_field_label_tag(name, custom_value)
    content_tag "label", custom_value.custom_field.name +
	(custom_value.custom_field.is_required? ? " <span class=\"required\">*</span>" : ""),
	:for => "#{name}_custom_field_values_#{custom_value.custom_field.id}",
	:class => (custom_value.errors.empty? ? nil : "error" )
  end
  
  # Return custom field tag with its label tag
  def custom_field_tag_with_label(name, custom_value)
    custom_field_label_tag(name, custom_value) + custom_field_tag(name, custom_value)
  end

  # Return a string used to display a custom value
  def show_value(custom_value)
    return "" unless custom_value
    format_value(custom_value.value, custom_value.custom_field.field_format)
  end
  
  # Return a string used to display a custom value
  def format_value(value, field_format)
    return "" unless value && !value.empty?
    case field_format
    when "date"
      begin; format_date(value.to_date); rescue; value end
    when "bool"
      l(value == "1" ? :general_text_Yes : :general_text_No)
    else
      value
    end
  end

  # Return an array of custom field formats which can be used in select_tag
  def custom_field_formats_for_select
    CustomField::FIELD_FORMATS.sort {|a,b| a[1][:order]<=>b[1][:order]}.collect { |k| [ l(k[1][:name]), k[0] ] }
  end
end
