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

  def custom_field_tag(custom_value)	
    custom_field = custom_value.custom_field
    field_name = "custom_fields[#{custom_field.id}]"
    case custom_field.field_format
    when "string", "int", "date"
      text_field_tag field_name, custom_value.value
    when "text"
      text_area_tag field_name, custom_value.value, :cols => 60, :rows => 3
    when "bool"
      check_box_tag(field_name, "1", custom_value.value == "1") + 
      hidden_field_tag(field_name, "0")
    when "list"
      select_tag field_name, 
                  "<option></option>" + options_for_select(custom_field.possible_values.split('|'),
                  custom_value.value)
    end
  end
  
  def custom_field_label_tag(custom_value)
    content_tag "label", custom_value.custom_field.name +
	(custom_value.custom_field.is_required? ? " <span class=\"required\">*</span>" : "")
  end
  
  def custom_field_tag_with_label(custom_value)
    case custom_value.custom_field.field_format
    when "bool"
      custom_field_tag(custom_value) + " " + custom_field_label_tag(custom_value)
    else
      custom_field_label_tag(custom_value) + "<br />" + custom_field_tag(custom_value)
    end	  
  end

  def show_value(custom_value)
    case custom_value.custom_field.field_format
    when "bool"
      l_YesNo(custom_value.value == "1")
    else
      custom_value.value
    end	
  end

  def custom_field_formats_for_select
    CustomField::FIELD_FORMATS.keys.collect { |k| [ l(CustomField::FIELD_FORMATS[k]), k ] }
  end
end
