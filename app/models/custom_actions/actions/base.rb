# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class CustomActions::Actions::Base
  attr_reader :values

  DEFAULT_PRIORITY = 100

  def initialize(values = [])
    self.values = values
  end

  def values=(values)
    @values = Array(values)
  end

  def allowed_values
    raise SubclassResponsibilityError
  end

  def value_objects
    values.filter_map do |value|
      allowed_values.find { |v| v[:value] == value }
    end
  end

  def type
    raise SubclassResponsibilityError
  end

  def apply(_work_package)
    raise SubclassResponsibilityError
  end

  def human_name
    WorkPackage.human_attribute_name(self.class.key)
  end

  def self.key
    raise SubclassResponsibilityError
  end

  def self.all
    [self]
  end

  def self.for(key)
    if key == self.key
      self
    end
  end

  delegate :key, to: :class

  def required?
    false
  end

  def multi_value?
    false
  end

  def validate(errors)
    validate_value_required(errors)
    validate_only_one_value(errors)
  end

  def priority
    DEFAULT_PRIORITY
  end

  private

  def deconstruct_keys(*)
    { type:, custom_field_based: respond_to?(:custom_field) }
  end

  def validate_value_required(errors)
    if required? && values.empty?
      errors.add :actions,
                 :empty,
                 name: human_name
    end
  end

  def validate_only_one_value(errors)
    if !multi_value? && values.length > 1
      errors.add :actions,
                 :only_one_allowed,
                 name: human_name
    end
  end
end
