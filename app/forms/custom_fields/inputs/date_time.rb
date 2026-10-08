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

class CustomFields::Inputs::DateTime < CustomFields::Inputs::Base::Input
  include Redmine::I18n

  # datetime-local inputs cannot carry an offset, so the submitted value lives in a hidden
  # field that the Stimulus controller fills with the local value plus the user's offset.
  form do |custom_value_form|
    custom_value_form.text_field(**input_attributes)
    custom_value_form.hidden(name:, value: custom_value.value.to_s, id: submitted_value_id)
  end

  def input_attributes
    attributes = super
    attributes[:data] = attributes[:data].merge(
      controller: "custom-fields--datetime-input",
      action: "input->custom-fields--datetime-input#sync",
      "custom-fields--datetime-input-submitted-value-id-value": submitted_value_id
    )

    attributes.merge(
      name: "#{attribute_name}_local",
      scope_name_to_model: false,
      type: "datetime-local",
      input_width: :small
    )
  end

  def value
    time = custom_value.typed_value
    return custom_value.value.to_s if time.nil?

    in_user_zone(time).strftime("%Y-%m-%dT%H:%M")
  end

  private

  def submitted_value_id
    "#{attribute_name}_submitted_value"
  end
end
