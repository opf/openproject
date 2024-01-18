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

class Project::CustomValueForm::MultiUserSelectList < Project::CustomValueForm::Base::Autocomplete::MultiValueInput
  form do |custom_value_form|
    custom_value_form.autocompleter(**base_config)
  end

  private

  def decorated
    false
  end

  def autocomplete_options
    super.merge({
                  placeholder: "Search for users",
                  resource: 'principals',
                  filters:,
                  searchKey: 'any_name_attribute',
                  inputValue: input_value
                })
  end

  def name
    "project[multi_user_custom_field_values_attributes][#{@custom_field.id}][comma_seperated_values][]"
  end

  def filters
    [
      { name: 'type', operator: '=', values: ['User', 'Group', 'PlaceholderUser'] },
      { name: 'member', operator: '=', values: [@project.id.to_s] },
      { name: 'status', operator: '!', values: [User.statuses["locked"].to_s] }
    ]
  end

  def input_value
    "?#{input_values_filter}"
  end

  def input_values_filter
    user_filter = { "type" => { "operator" => "=", "values" => ["User"] } }
    id_filter = { "id" => { "operator" => "=", "values" => @custom_field_values.map(&:value) } }

    filters = [user_filter, id_filter]
    URI.encode_www_form("filters" => filters.to_json)
  end
end
