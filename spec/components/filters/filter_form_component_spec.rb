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

require "spec_helper"

RSpec.describe Filters::FilterFormComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:query) { UserQuery.new }

  # `Member.human_attribute_name(:blocked)` is what BlockedFilter#human_name
  # depends on; UserQuery#available_advanced_filters includes it, and we keep
  # the full set in these specs so the spec doesn't drift from production.
  let(:allowed_filters) { nil }
  let(:options) { { query:, allowed_filters: } }

  def render_form(form_options = options)
    render_in_view_context(form_options) do |form_options|
      primer_form_with(url: "/foo", method: :post) do |f|
        render(Filters::FilterFormComponent.new(builder: f, **form_options))
      end
    end
  end

  describe "basic rendering" do
    it "renders an Add filter select advertising the query's filters" do
      render_form

      # Sanity: at least the well-known UserQuery filters are advertised
      # (option text is `User.human_attribute_name(filter.name)`).
      expect(page).to have_select "add_filter_select",
                                  with_options: %w[Name Status Username]
    end

    it "renders the row of an active filter visible and inactive rows hidden" do
      query.where(:login, "=", ["alice"])
      render_form

      # `data-filter--filters-form-target="filter"` scopes to the outer row;
      # operator/value descendants also carry `data-filter-name`.
      expect(page).to have_element "data-filter--filters-form-target": "filter",
                                   "data-filter-name": "login" do |row|
        expect(row["hidden"]).to be_nil
      end

      expect(page).to have_element "data-filter--filters-form-target": "filter",
                                   "data-filter-name": "status",
                                   visible: :all do |row|
        expect(row["hidden"]).to eq("hidden")
      end
    end
  end

  describe "allowed_filters" do
    let(:restricted) do
      query.available_advanced_filters.select { |f| f.name == :login }
    end

    it "limits the rendered Add filter options" do
      render_form(query:, allowed_filters: restricted)

      expect(page).to have_select "add_filter_select" do |select|
        # Two options: the blank prompt + the single allowed filter.
        expect(select).to have_selector :option, count: 2
        expect(select).to have_selector :option, text: "Username"
      end
    end
  end

  describe "wrap_with_controller:" do
    it "does not emit a controller wrapper by default" do
      render_form

      expect(page).to have_no_element "data-controller": "filter--filters-form"
    end

    it "emits an `op-filters-form -expanded` controller wrapper when true" do
      render_form(query:, wrap_with_controller: true)

      expect(page).to have_element "data-controller": "filter--filters-form",
                                   class: %w[op-filters-form -expanded]
    end
  end

  describe "hidden_input_name:" do
    it "renders no hidden filters field by default" do
      render_form

      expect(page).to have_no_element :input,
                                      "data-filter--filters-form-target": "filtersInput",
                                      visible: :all
    end

    it "renders a hidden field bound to the filtersInput target when set" do
      render_form(query:, hidden_input_name: "filters")

      expect(page).to have_element :input,
                                   type: "hidden",
                                   name: "filters",
                                   "data-filter--filters-form-target": "filtersInput",
                                   visible: :all
    end
  end

  describe "output_format:" do
    it "sets the controller value when wrapping the controller" do
      render_form(query:, wrap_with_controller: true, output_format: :json)

      expect(page).to have_element "data-controller": "filter--filters-form",
                                   "data-filter--filters-form-output-format-value": "json"
    end

    it "omits the data attribute by default" do
      render_form(query:, wrap_with_controller: true)

      expect(page).to have_element "data-controller": "filter--filters-form" do |wrapper|
        expect(wrapper["data-filter--filters-form-output-format-value"]).to be_nil
      end
    end

    it "raises on unknown values" do
      expect do
        described_class.new(builder: nil, query:, output_format: :bogus)
      end.to raise_error(Primer::FetchOrFallbackHelper::InvalidValueError, /Expected one of/)
    end
  end

  describe "wrapper system arguments" do
    it "forwards standard system arguments to the controller wrapper" do
      render_form(
        query:,
        wrap_with_controller: true,
        id: "custom-filter-wrapper",
        aria: { label: "Filters" },
        data: { test_selector: "filters-wrapper" }
      )

      expect(page).to have_element :div,
                                   id: "custom-filter-wrapper",
                                   "aria-label": "Filters",
                                   "data-test-selector": "filters-wrapper"
    end

    it "merges caller classes and data with the required wrapper data" do
      render_form(
        query:,
        wrap_with_controller: true,
        classes: "custom-class",
        data: {
          controller: "custom-controller",
          action: "keydown->custom#close"
        }
      )

      expect(page).to have_element :div,
                                   class: %w[op-filters-form -expanded custom-class],
                                   "data-controller": "custom-controller filter--filters-form",
                                   "data-action": "keydown->custom#close"
    end
  end

  describe "value-less operators (operator `data-no-value` attribute)" do
    # A date custom field surfaces operators whose `requires_value?` is
    # false (`t`, `w`, `!*`) alongside ones that require a value (`=d`,
    # `>t-`, …). That's enough to assert both branches of the dispatch.
    let!(:date_field) { create(:user_custom_field, field_format: "date") }

    it "marks value-less operators with data-no-value and leaves the rest untouched" do
      render_form

      operator_select = page.find(:element, :select,
                                  name: "operator_cf_#{date_field.id}",
                                  visible: :all)

      # `t` (Today) — `Queries::Operators::Today` declares `require_value false`.
      expect(operator_select).to have_element :option,
                                              value: "t",
                                              "data-no-value": "true",
                                              visible: :all

      # `=d` (OnDate) — declares `require_value true` (the default).
      expect(operator_select).to have_element :option,
                                              value: "=d",
                                              visible: :all do |option|
        expect(option["data-no-value"]).to be_nil
      end
    end
  end

  describe "autocomplete_append_to:" do
    # `appendTo` arrives at the angular component as a JSON-encoded data
    # attribute (`angular_component_tag` json-encodes its `inputs:` hash).
    def append_to_value_in(filter_name)
      page.find(:element,
                "data-filter-name": filter_name,
                "data-filter-autocomplete": "true",
                visible: :all)
          .find(:element, "data-append-to": /.*/, visible: :all)["data-append-to"]
          .then { |v| JSON.parse(v) }
    end

    it "forwards the selector into the autocomplete options of ListForm filters" do
      render_form(query:, autocomplete_append_to: "#dialog-x")

      # :status is a list filter (no native autocomplete_options) and is
      # routed to ListForm.
      expect(append_to_value_in("status")).to eq("#dialog-x")
    end

    it "is absent from autocomplete data when not set" do
      render_form

      expect(page).to have_element "data-filter-name": "status",
                                   "data-filter-autocomplete": "true",
                                   visible: :all do |wrapper|
        expect(wrapper).to have_no_element "data-append-to": /.*/, visible: :all
      end
    end
  end
end
