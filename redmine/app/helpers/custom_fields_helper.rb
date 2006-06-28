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
		
		case custom_field.typ
		when 0 .. 2
			text_field_tag field_name, custom_value.value
		when 3
			check_box field_name
		when 4
			select_tag field_name, 
					options_for_select(custom_field.possible_values.split('|'),
					custom_value.value)
		end
	end
end
