#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CustomValue < ActiveRecord::Base
  belongs_to :custom_field
  belongs_to :customized, :polymorphic => true

  validate :validate_presence_of_required_value
  validate :validate_format_of_value
  validate :validate_type_of_value
  validate :validate_length_of_value

  after_initialize :set_default_value

  def set_default_value
    if new_record? && custom_field && (customized_type.blank? || (customized && customized.new_record?))
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

  def visible?
    custom_field.visible?
  end

  def required?
    custom_field.is_required?
  end

  def to_s
    value.to_s
  end

  protected

  def validate_presence_of_required_value
    errors.add(:value, :blank) if custom_field.is_required? && value.blank?
  end

  def validate_format_of_value
    if value.present?
      errors.add(:value, :invalid) unless custom_field.regexp.blank? or value =~ Regexp.new(custom_field.regexp)
    end
  end

  def validate_type_of_value
    if value.present?
      # Format specific validations
      case custom_field.field_format
      when 'int'
        errors.add(:value, :not_a_number) unless value =~ /\A[+-]?\d+\z/
      when 'float'
        begin; Kernel.Float(value); rescue; errors.add(:value, :invalid) end
      when 'date'
        errors.add(:value, :not_a_date) unless value =~ /\A\d{4}-\d{2}-\d{2}\z/
      when 'list'
        errors.add(:value, :inclusion) unless custom_field.possible_values.include?(value)
      end
    end
  end

  def validate_length_of_value
    if value.present? && custom_field.min_length.present? && custom_field.max_length.present?
      errors.add(:value, :too_short, :count => custom_field.min_length) if custom_field.min_length > 0 and value.length < custom_field.min_length
      errors.add(:value, :too_long, :count => custom_field.max_length) if custom_field.max_length > 0 and value.length > custom_field.max_length
    end
  end
end
