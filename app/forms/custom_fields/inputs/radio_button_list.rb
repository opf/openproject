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

class CustomFields::Inputs::RadioButtonList < CustomFields::Inputs::Base::Input
  form do |custom_value_form|
    custom_value_form.radio_button_group(**group_attributes) do |group|
      unless required?
        group.radio_button(value: "", label: I18n.t(:label_none), checked: selected_id.nil?)
      end

      @custom_field.custom_options.each do |custom_option|
        group.radio_button(value: custom_option.id,
                           label: custom_option.value,
                           checked: custom_option.id == selected_id)
      end
    end
  end

  private

  def group_attributes
    base_input_attributes
      .except(:value)
      .merge(data: { "custom-field-id": @custom_field.id, "test-selector": test_selector })
  end

  def selected_id
    if custom_value.value.present?
      custom_value.value.to_i
    else
      @custom_field.default_value&.to_i
    end
  end
end
