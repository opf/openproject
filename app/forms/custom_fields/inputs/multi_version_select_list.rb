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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class CustomFields::Inputs::MultiVersionSelectList < CustomFields::Inputs::Base::Autocomplete::MultiValueInput
  include AssignableCustomFieldValues
  include CustomFields::Inputs::VersionSelect

  form do |custom_value_form|
    # autocompleter does not set key with blank value if nothing is selected or input is cleared
    # in order to let acts_as_customizable handle the clearing of the value, we need to set the value to blank via a hidden field
    # which sends blank if autocompleter is cleared
    custom_value_form.hidden(
      **input_attributes,
      scope_name_to_model: false,
      name: "#{@object.model_name.element}[custom_field_values][#{input_attributes[:name]}][]",
      value: nil
    )

    custom_value_form.autocompleter(**version_input_attributes) do |list|
      assignable_custom_field_values(@custom_field).each do |version|
        list.option(
          label: version.name,
          value: version.id,
          group_by: group_key(version.project),
          selected: selected?(version)
        )
      end
    end
  end

  private

  def decorated?
    true
  end

  def selected?(version)
    custom_values.pluck(:value).map { |value| value&.to_i }.include?(version.id)
  end

  def group_key(project)
    project.visible?(User.current) ? project.name : I18n.t(:"project.not_available")
  end
end
