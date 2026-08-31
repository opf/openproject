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

class Filters::Inputs::ListForm < Filters::Inputs::BaseFilterForm
  def add_operand(group)
    filter_name = @filter.name
    filter_values = @filter.values || []
    items = @filter.allowed_values.map { |name, id| { name:, id: } }

    group.autocompleter(
      name: operand_name,
      label: :value,
      visually_hide_label: true,
      wrapper_classes: ["advanced-filters--filter-value"],
      wrapper_data_attributes: {
        "filter--filters-form-target": "filterValueContainer",
        "filter-name": filter_name,
        "filter-autocomplete": "true"
      },
      autocomplete_options: {
        component: "opce-autocompleter",
        id: operand_name,
        multiple: true,
        multipleAsSeparateInputs: false,
        inputName: "value",
        inputValue: filter_values,
        items:,
        model: items.select { |item| filter_values.include?(item[:id]) },
        bindLabel: "name",
        bindValue: "id",
        hideSelected: true,
        defaultData: false,
        hiddenFieldAction: "change->filter--filters-form#autocompleteSendForm"
      }.merge(@additional_attributes[:autocomplete_options] || {})
    )
  end
end
