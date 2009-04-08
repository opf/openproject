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
  belongs_to :custom_field
  belongs_to :customized, :polymorphic => true

  def after_initialize
    if custom_field && new_record? && (customized_type.blank? || (customized && customized.new_record?))
      self.value ||= custom_field.default_value
    end
  end
  
  # Returns true if the boolean custom value is true
  def true?
    self.value == '1'
  end
  
  def editable?
    custom_field.editable?
  end
  
  def required?
    custom_field.is_required?
  end
  
  def to_s
    value.to_s
  end
  
protected
  def validate
    if value.blank?
      errors.add(:value, :blank) if custom_field.is_required? and value.blank?    
    else
      errors.add(:value, :invalid) unless custom_field.regexp.blank? or value =~ Regexp.new(custom_field.regexp)
      errors.add(:value, :too_short, :count => custom_field.min_length) if custom_field.min_length > 0 and value.length < custom_field.min_length
      errors.add(:value, :too_long, :count => custom_field.max_length) if custom_field.max_length > 0 and value.length > custom_field.max_length
    
      # Format specific validations
      case custom_field.field_format
      when 'int'
        errors.add(:value, :not_a_number) unless value =~ /^[+-]?\d+$/	
      when 'float'
        begin; Kernel.Float(value); rescue; errors.add(:value, :invalid) end
      when 'date'
        errors.add(:value, :not_a_date) unless value =~ /^\d{4}-\d{2}-\d{2}$/
      when 'list'
        errors.add(:value, :inclusion) unless custom_field.possible_values.include?(value)
      end
    end
  end
end
