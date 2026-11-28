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

require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::DatePicker, type: :forms do
  include ViewComponent::TestHelpers

  let(:model) { build_stubbed(:comment) }
  let(:picker_arguments) { {} }

  def render_form(picker, **arguments)
    render_in_view_context(model) do |model|
      primer_form_with(url: "/foo", model:) do |f|
        render_inline_form(f) do |form|
          form.public_send(picker, name: :some_date, label: "Some date", **arguments)
        end
      end
    end
    page
  end

  describe "single date picker" do
    subject(:rendered_form) do
      render_form(:single_date_picker, placeholder: "Pick a date", datepicker_options: { value: "2026-12-24" })
    end

    it "renders the label" do
      expect(rendered_form).to have_element :label
    end

    it "passes the field as plain attributes" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "input-id": "comment_some_date",
                                            name: "comment[some_date]",
                                            value: "2026-12-24",
                                            placeholder: "Pick a date"
    end

    it "keeps the id off the custom element and the picker options out of its attributes" do
      picker = rendered_form.find(:element, "opce-basic-single-date-picker")

      expect(picker[:id]).to be_nil
      expect(picker.native.attributes.keys).to contain_exactly("input-id", "name", "value", "placeholder", "input-class-names")
    end
  end

  describe "without placeholder" do
    subject(:rendered_form) do
      render_form(:single_date_picker, datepicker_options: { value: "" })
    end

    it "omits the placeholder" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker", value: ""
      expect(rendered_form).to have_no_element "opce-basic-single-date-picker", placeholder: /.*/
    end
  end

  describe "with picker options" do
    subject(:rendered_form) do
      render_form(
        :single_date_picker,
        datepicker_options: {
          id: "custom_id",
          name: "custom[name]",
          value: "2026-12-24",
          class: "extra-class",
          inDialog: "my-dialog",
          data: { action: "change->form#preview" },
          input_attributes: { "data-filter-name" => "due" }
        }
      )
    end

    it "passes them as plain attributes" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "input-id": "custom_id",
                                            name: "custom[name]",
                                            "input-class-names": "extra-class",
                                            "in-dialog": "my-dialog"
    end

    it "hands the data action to the inner input instead of setting it on the custom element" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "input-attrs": {
                                              "data-action" => "change->form#preview",
                                              "data-filter-name" => "due"
                                            }.to_json
      expect(rendered_form).to have_no_element "opce-basic-single-date-picker", "data-action": /.*/
    end
  end

  describe "with input attributes explicitly set to nil" do
    subject(:rendered_form) do
      render_form(:single_date_picker, datepicker_options: { value: "", input_attributes: nil })
    end

    it "renders the picker without input attributes" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker", value: ""
      expect(rendered_form).to have_no_element "opce-basic-single-date-picker", "input-attrs": /.*/
    end
  end

  describe "with the value taken from the model" do
    let(:model) { build_stubbed(:version, start_date: Date.new(2026, 12, 24)) }

    subject(:rendered_form) do
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) { |form| form.single_date_picker(name: :start_date, label: "Start date") }
        end
      end
      page
    end

    it "passes the date as an ISO 8601 string" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "input-id": "version_start_date",
                                            value: "2026-12-24"
    end
  end

  describe "single datetime picker" do
    subject(:rendered_form) do
      render_form(:single_datetime_picker, datepicker_options: { value: "2026-10-01T12:30:00Z" })
    end

    it "passes the value as a plain attribute" do
      expect(rendered_form).to have_element "opce-basic-single-datetime-picker", value: "2026-10-01T12:30:00Z"
    end
  end

  describe "range date picker" do
    subject(:rendered_form) do
      render_form(:range_date_picker,
                  placeholder: "Pick a range",
                  datepicker_options: { value: "2026-08-01 - 2026-08-14", showClearButton: true })
    end

    it "passes the range and the clear button as plain attributes" do
      expect(rendered_form).to have_element "opce-range-date-picker",
                                            value: "2026-08-01 - 2026-08-14",
                                            placeholder: "Pick a range",
                                            "show-clear-button": ""
    end
  end

  describe "inside a multi input" do
    subject(:rendered_form) do
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.multi(name: :created_at, label: "Created at") do |multi|
              multi.single_date_picker(name: :singleDay, label: :singleDay, datepicker_options: { value: "" })
              multi.range_date_picker(name: :dateRange, label: :dateRange, hidden: true, datepicker_options: { value: "-" })
            end
          end
        end
      end
      page
    end

    it "names each picker for primer-multi-input with a plain data-name" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "data-targets": "primer-multi-input.fields",
                                            "data-name": "singleDay",
                                            name: "comment[created_at]"
      expect(rendered_form).to have_element "opce-range-date-picker",
                                            "data-targets": "primer-multi-input.fields",
                                            "data-name": "dateRange",
                                            visible: :all
    end
  end
end
