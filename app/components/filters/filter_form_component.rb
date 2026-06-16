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

# Renders the list of filter input fields (one row per available filter plus an
# "add filter" select) for a given query as part of a Primer form.
#
# The set of inputs depends on the query's available and active filters and is
# built dynamically at render time. The component receives the builder of the
# surrounding `primer_form_with` so that the emitted field names match what the
# controller expects (top-level `operator_<filter>` and `<filter>_value` fields).
#
# Embed it in any primer form:
#
#   <%= primer_form_with(url: ...) do |f| %>
#     <%= f.text_field(name: :title) %>
#     <%= render(Filters::FilterFormComponent.new(builder: f, query: @query)) %>
#   <% end %>
#
# Customise the set of advertised filters by passing `allowed_filters:` (used
# by `Filter::FilterComponent` subclasses that restrict or reorder the list).
#
# By default the component does *not* attach the `filter--filters-form` Stimulus
# controller, because in the standard layout (e.g. `Projects::IndexSubHeaderComponent`)
# the controller has to sit on a common ancestor of the advanced filter form
# *and* the inline quick filter input so that `sendForm()` can collect values
# from both. For standalone embeds with no co-located quick filter, pass
# `wrap_with_controller: true` and the component will emit its own controller
# wrapper.
#
# Pass `hidden_input_name:` (e.g. `"filters"`) to also emit a hidden input
# bound to the Stimulus controller's `filtersInput` target. The controller
# keeps the field value in sync with the serialized filter selections so
# that a normal form submit carries the canonical filter string in
# `params[:<hidden_input_name>]` — no `sendForm` redirect needed.
#
# `output_format:` selects how the filter selection is serialized into the
# hidden field (and into the URL when `sendForm` redirects). Supported values:
#   * `:params` (default) — URL-style string: `name ~ "foo"&login ! "bar"`.
#   * `:json`             — JSON array: `[{"name":{"operator":"~","values":["foo"]}}, ...]`.
# Only meaningful when this component owns the controller
# (`wrap_with_controller: true`); otherwise the host's controller wrapper
# decides.
#
# `autocomplete_append_to:` forwards an `appendTo` selector (or DOM reference
# string ng-select understands, e.g. `"#my-dialog"` or `"body"`) to every
# autocompleter the component renders. Use this when the component is embedded
# in a Primer dialog or another container that clips overflow, so the dropdown
# portal renders outside that container instead of being clipped.
class Filters::FilterFormComponent < ApplicationComponent
  include OpPrimer::AttributesHelper
  include Primer::FetchOrFallbackHelper

  OUTPUT_FORMATS = %i[params json].freeze

  def initialize(builder:,
                 query:,
                 allowed_filters: nil,
                 wrap_with_controller: false,
                 hidden_input_name: nil,
                 output_format: nil,
                 autocomplete_append_to: nil,
                 **wrapper_arguments)
    super()
    @builder = builder
    @query = query
    @allowed_filters = allowed_filters || query.available_advanced_filters
    @wrap_with_controller = wrap_with_controller
    @hidden_input_name = hidden_input_name
    @output_format = fetch_or_fallback(OUTPUT_FORMATS, output_format.to_sym) if output_format
    @autocomplete_append_to = autocomplete_append_to
    @wrapper_arguments = wrapper_arguments
    @wrapper_arguments[:tag] ||= :div
    @wrapper_arguments[:classes] = class_names(
      "op-filters-form -expanded",
      @wrapper_arguments[:classes]
    )
    @wrapper_arguments[:data] = merge_data(
      @wrapper_arguments,
      {
        data: {
          controller: "filter--filters-form",
          filter__filters_form_output_format_value: @output_format&.to_s
        }
      }
    )
  end

  private

  attr_reader :query, :allowed_filters

  def form_list
    Primer::Forms::FormList.new(*sub_forms)
  end

  def hidden_filters_input
    hidden_field_tag(
      @hidden_input_name,
      "",
      data: { filter__filters_form_target: "filtersInput" }
    )
  end

  def sub_forms
    forms = map_filter do |filter, active, additional_attributes|
      filter_form_class(filter)
        .new(@builder, filter:, additional_attributes:, active:)
    end

    forms << Filters::Inputs::AddFilterForm.new(
      @builder,
      allowed_filters:,
      active_filter_names: query.filters.map(&:name)
    )
  end

  def map_filter
    allowed_filters.map do |allowed_filter|
      active_filter = query.find_active_filter(allowed_filter.name)
      filter = active_filter || allowed_filter

      yield filter, active_filter.present?, additional_filter_attributes(filter)
    end
  end

  def additional_filter_attributes(filter)
    opts = filter.autocomplete_options
    opts = opts.merge(appendTo: @autocomplete_append_to) if @autocomplete_append_to
    opts.any? ? { autocomplete_options: opts } : {}
  end

  def filter_form_class(filter)
    if filter.is_a?(Queries::Filters::Shared::BooleanFilter)
      Filters::Inputs::BooleanForm
    elsif filter.autocomplete_options.any?
      Filters::Inputs::AutocompleteForm
    elsif filter.type.in? %i[list list_optional list_all]
      Filters::Inputs::ListForm
    elsif filter.type.in? %i[datetime_past date]
      Filters::Inputs::DateForm
    else
      Filters::Inputs::TextForm
    end
  end
end
