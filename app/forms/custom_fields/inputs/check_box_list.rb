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

class CustomFields::Inputs::CheckBoxList < CustomFields::Inputs::Base::Input
  form do |custom_value_form|
    custom_value_form.check_box_group(include_hidden: true, **group_attributes) do |group|
      @custom_field.custom_options.each do |custom_option|
        group.check_box(value: custom_option.id,
                        label: custom_option.value,
                        checked: selected?(custom_option))
      end
    end
  end

  def invalid?
    custom_values.any? { |custom_value| custom_value.errors.any? }
  end

  def validation_message
    custom_values.map { |custom_value| custom_value.errors.full_messages }.join(", ") if invalid?
  end

  private

  def group_attributes
    base_input_attributes
      .except(:value)
      .merge(data: { "custom-field-id": @custom_field.id, "test-selector": test_selector })
  end

  def custom_values
    @custom_values ||= @object.custom_values_for_custom_field(@custom_field)
  end

  def selected?(custom_option)
    selected_values = custom_values.filter_map { |custom_value| custom_value.value&.to_i }

    if selected_values.any?
      selected_values.include?(custom_option.id)
    else
      custom_option.default_value?
    end
  end
end
