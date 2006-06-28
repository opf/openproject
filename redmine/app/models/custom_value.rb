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

class CustomValue < ActiveRecord::Base
	belongs_to :issue
	belongs_to :custom_field
	
protected
  def validate
		errors.add(custom_field.name, "can't be blank") if custom_field.is_required? and value.empty?
		errors.add(custom_field.name, "is not valid") unless custom_field.regexp.empty? or value =~ Regexp.new(custom_field.regexp)
		
		case custom_field.typ
		when 0
			errors.add(custom_field.name, "must be an integer") unless value =~ /^[0-9]*$/	
		when 1
			errors.add(custom_field.name, "is too short") if custom_field.min_length > 0 and value.length < custom_field.min_length and value.length > 0
			errors.add(custom_field.name, "is too long") if custom_field.max_length > 0 and value.length > custom_field.max_length
		when 2
			errors.add(custom_field.name, "must be a valid date") unless value =~ /^(\d+)\/(\d+)\/(\d+)$/ or value.empty?
		when 3
			
		when 4
			errors.add(custom_field.name, "is not a valid value") unless custom_field.possible_values.split('|').include? value or value.empty?
		end
  end
end
