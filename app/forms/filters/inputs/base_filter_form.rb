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

class Filters::Inputs::BaseFilterForm < ApplicationForm
  def initialize(filter:, additional_attributes:, active:)
    super()
    @filter = filter
    @additional_attributes = additional_attributes
    @active = active
  end

  def self.inherited(subclass)
    super
    subclass.form do |form|
      form.group(**filter_row_arguments) do |group|
        add_label(group)
        add_operator(group)
        add_operand(group)
        add_delete_button(group)
      end
    end
  end

  protected

  def add_label(group)
    filter_human_name = @filter.human_name
    for_id = operator_hidden? ? operand_input_id : "operator_#{@filter.name}"
    group.html_content do
      content_tag(:label, filter_human_name, class: "advanced-filters--filter-name", for: for_id)
    end
  end

  def operator_hidden?
    @filter.is_a?(Queries::Filters::Shared::BooleanFilter)
  end

  def operand_input_id
    nil
  end

  def add_operand(_group)
    raise SubclassResponsibilityError
  end

  def filter_row_arguments
    args = {
      layout: :horizontal,
      classes: "advanced-filters--filter",
      data: {
        "filter--filters-form-target": "filter",
        "filter-name": @filter.name,
        "filter-type": @filter.type
      }
    }
    args[:hidden] = "hidden" unless @active
    args
  end

  def operand_name
    "#{@filter.name}_value"
  end

  private

  def add_operator(group)
    selected_operator = @filter.operator || @filter.default_operator.symbol

    group.select_list(
      name: :"operator_#{@filter.name}",
      label: @filter.human_name,
      visually_hide_label: true,
      scope_name_to_model: false,
      hidden: @filter.is_a?(Queries::Filters::Shared::BooleanFilter),
      data: {
        action: "change->filter--filters-form#setValueVisibility",
        "filter--filters-form-filter-name-param": @filter.name,
        "filter--filters-form-target": "operator",
        "filter-name": @filter.name
      }
    ) do |select|
      @filter.available_operators.each do |operator|
        select.option(
          label: operator.human_name,
          value: operator.symbol,
          selected: operator.symbol == selected_operator,
          **(operator.requires_value? ? {} : { "data-no-value": true })
        )
      end
    end
  end

  def add_delete_button(group)
    filter_name = @filter.name
    group.html_content do
      render(Primer::Beta::IconButton.new(
               icon: :x,
               scheme: :invisible,
               classes: "advanced-filters--remove-filter",
               aria: { label: I18n.t("button_delete") },
               data: {
                 action: "click->filter--filters-form#removeFilter",
                 "filter--filters-form-filter-name-param": filter_name
               }
             ))
    end
  end
end
