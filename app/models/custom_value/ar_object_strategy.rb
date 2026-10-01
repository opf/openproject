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

class CustomValue::ARObjectStrategy < CustomValue::FormatStrategy
  def typed_value
    cached_ar_object
  end

  def formatted_value
    cached_ar_object.to_s
  end

  def parse_value(val)
    if val.is_a?(ar_class)
      @cached_ar_object = val

      val.id.to_s
    else
      @cached_ar_object = nil

      val.presence
    end
  end

  def validate_type_of_value
    unless custom_field.possible_values(custom_value.customized).include?(value)
      :inclusion
    end
  end

  private

  # This method is not inlined in typed_value to allow separate changes to typed_value and formatted_value
  def cached_ar_object
    return @cached_ar_object if @cached_ar_object

    if value.present?
      RequestStore.fetch(:"#{ar_class.name.underscore}_custom_value_#{value}") do
        @cached_ar_object = ar_object(value)
      end
    end
  end

  def ar_class
    raise SubclassResponsibilityError
  end

  def ar_object(value)
    ar_class.find_by(id: value)
  end
end
