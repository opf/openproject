#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CustomValue < ApplicationRecord
  belongs_to :custom_field
  belongs_to :customized, polymorphic: true

  validate :validate_presence_of_required_value
  validate :validate_format_of_value
  validate :validate_type_of_value
  validate :validate_length_of_value

  delegate :typed_value,
           :formatted_value,
           to: :strategy

  delegate :editable?,
           :visible?,
           :required?,
           :max_length,
           :min_length,
           to: :custom_field

  def to_s
    value.to_s
  end

  def value=(val)
    parsed_value = strategy.parse_value(val)

    super(parsed_value)
  end

  protected

  def validate_presence_of_required_value
    errors.add(:value, :blank) if custom_field.required? && !strategy.value_present?
  end

  def validate_format_of_value
    if value.present? && custom_field.has_regexp?
      errors.add(:value, :invalid) unless value =~ Regexp.new(custom_field.regexp)
    end
  rescue RegexpError => e
    errors.add(:base, :regex_invalid)
    Rails.logger.error "Custom Field ID#{custom_field_id} has an invalid regex: #{e.message}"
  end

  def validate_type_of_value
    if value.present?
      validation_error = strategy.validate_type_of_value
      if validation_error
        errors.add(:value, validation_error)
      end
    end
  end

  def validate_length_of_value
    if value.present? && (min_length.present? || max_length.present?)
      validate_min_length_of_value
      validate_max_length_of_value
    end
  end

  private

  def validate_min_length_of_value
    errors.add(:value, :too_short, count: min_length) if min_length > 0 && value.length < min_length
  end

  def validate_max_length_of_value
    errors.add(:value, :too_long, count: max_length) if max_length > 0 && value.length > max_length
  end

  def strategy
    @strategy ||= OpenProject::CustomFieldFormat.find_by_name(custom_field.field_format).formatter.new(self)
  end
end
