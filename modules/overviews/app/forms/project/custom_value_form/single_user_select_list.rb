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

class Project::CustomValueForm::SingleUserSelectList < Project::CustomValueForm::Base
  form do |custom_value_form|
    custom_value_form.autocompleter(**base_config)
  end

  def base_config
    super.merge({
                  autocomplete_options: {
                    inputId: id,
                    placeholder: "Search for a user",
                    resource: 'principals',
                    filters: [{ name: 'type', operator: '=', values: ['User'] },
                              { name: 'member', operator: '=', values: ['1'] }],
                    searchKey: 'any_name_attribute',
                    inputName: name,
                    inputValue: input_value
                    # focusDirectly: true,
                    # appendTo: 'body',
                    # disabled: @disabled
                  },
                  invalid: invalid?,
                  validation_message:
                })
  end

  def input_value
    "?#{input_values_filter}"
  end

  def input_values_filter
    user_filter = { "type" => { "operator" => "=", "values" => ["User"] } }
    id_filter = { "id" => { "operator" => "=", "values" => @custom_field_value.value } }

    filters = [user_filter, id_filter]
    URI.encode_www_form("filters" => filters.to_json)
  end

  def invalid?
    @custom_field_value.errors.any?
  end

  def validation_message
    @custom_field_value.errors.full_messages.join(', ') if invalid?
  end
end
