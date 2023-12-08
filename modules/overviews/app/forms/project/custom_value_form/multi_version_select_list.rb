#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Project::CustomValueForm::MultiVersionSelectList < Project::CustomValueForm::Base
  def initialize(custom_field:, custom_field_values:, project:)
    @custom_field = custom_field
    @custom_field_values = custom_field_values
    @project = project
  end

  form do |custom_value_form|
    custom_value_form.autocompleter(**base_config) do |list|
      @project.versions.each do |version|
        list.option(
          label: version.name, value: version.id,
          selected: @custom_field_values.pluck(:value).map { |value| value&.to_i }.include?(version.id)
        )
      end
    end
  end

  private

  def base_config
    {
      name:,
      scope_name_to_model: false,
      scope_id_to_model: false, # autocompleter does not respect scope_id_to_model = false
      placeholder: @custom_field.name,
      label: @custom_field.name,
      required: @custom_field.is_required?,
      include_blank: @custom_field.is_required? ? false : '_blank', # autocompleter does not send '_blank' as value when no option is selected
      autocomplete_options: {
        multiple: true,
        decorated: true,
        inputId: id,
        inputName: name
      },
      invalid: invalid?,
      validation_message:
    }
  end

  def name
    "project[multi_custom_field_values_attributes][#{@custom_field.id}][values]"
  end

  def invalid?
    @custom_field_values.any? { |custom_field_value| custom_field_value.errors.any? }
  end

  def validation_message
    @custom_field_values.map { |custom_field_value| custom_field_value.errors.full_messages }.join(', ') if invalid?
  end
end
