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

  # Return custom field html tag corresponding to its format
  def custom_field_tag(custom_value)	
    custom_field = custom_value.custom_field
    field_name = "custom_fields[#{custom_field.id}]"
    field_id = "custom_fields_#{custom_field.id}"
    
    case custom_field.field_format
    when "string", "int"
      text_field 'custom_value', 'value', :name => field_name, :id => field_id
    when "date"
      text_field('custom_value', 'value', :name => field_name, :id => field_id, :size => 10) + 
      calendar_for(field_id)
    when "text"
      text_area 'custom_value', 'value', :name => field_name, :id => field_id, :cols => 60, :rows => 3
    when "bool"
      check_box 'custom_value', 'value', :name => field_name, :id => field_id
    when "list"
      select 'custom_value', 'value', custom_field.possible_values.split('|'), { :include_blank => true }, :name => field_name, :id => field_id
    end
  end
  
  # Return custom field label tag
  def custom_field_label_tag(custom_value)
    content_tag "label", custom_value.custom_field.name +
	(custom_value.custom_field.is_required? ? " <span class=\"required\">*</span>" : ""),
	:for => "custom_fields_#{custom_value.custom_field.id}",
	:class => (custom_value.errors.empty? ? nil : "error" )
  end
  
  # Return custom field tag with its label tag
  def custom_field_tag_with_label(custom_value)
    custom_field_label_tag(custom_value) + custom_field_tag(custom_value)
  end

  # Return a string used to display a custom value
  def show_value(custom_value)
    return "" unless custom_value
    
    case custom_value.custom_field.field_format
    when "date"
      custom_value.value.empty? ? "" : l_date(custom_value.value.to_date)
    when "bool"
      l_YesNo(custom_value.value == "1")
    else
      custom_value.value
    end	
  end

  # Return an array of custom field formats which can be used in select_tag
  def custom_field_formats_for_select
    CustomField::FIELD_FORMATS.keys.collect { |k| [ l(CustomField::FIELD_FORMATS[k]), k ] }
  end
end
