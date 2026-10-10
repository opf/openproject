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

RSpec.describe Primer::OpenProject::Forms::DatePicker, type: :forms do
  include ViewComponent::TestHelpers

  let(:model) { build_stubbed(:comment) }

  describe "single date picker" do
    def render_form
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.single_date_picker(
              name: :some_date,
              label: "Some date",
              placeholder: "Pick a date",
              datepicker_options: { value: "" }
            )
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "renders the label" do
      expect(rendered_form).to have_element :label
    end

    it "renders the single date picker angular component" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker"
    end

    it "passes placeholder as a data attribute" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "data-placeholder": "Pick a date".to_json
    end
  end

  describe "without placeholder" do
    def render_form
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.single_date_picker(
              name: :some_date,
              label: "Some date",
              datepicker_options: { value: "" }
            )
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "defaults placeholder to an empty string" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "data-placeholder": "".to_json
    end
  end

  describe "single datetime picker" do
    def render_form
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.single_datetime_picker(
              name: :some_datetime,
              label: "Some datetime",
              datepicker_options: { value: "2026-10-01T12:30:00Z" }
            )
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "renders the single datetime picker angular component" do
      expect(rendered_form).to have_element "opce-basic-single-datetime-picker"
    end

    it "passes the value as a data attribute" do
      expect(rendered_form).to have_element "opce-basic-single-datetime-picker",
                                            "data-value": "2026-10-01T12:30:00Z".to_json
    end
  end

  describe "range date picker" do
    def render_form
      render_in_view_context(model) do |model|
        primer_form_with(url: "/foo", model:) do |f|
          render_inline_form(f) do |form|
            form.range_date_picker(
              name: :some_date,
              label: "Some date",
              placeholder: "Pick a range",
              datepicker_options: { value: "" }
            )
          end
        end
      end
    end

    subject(:rendered_form) do
      render_form
      page
    end

    it "renders the range date picker angular component" do
      expect(rendered_form).to have_element "opce-range-date-picker"
    end

    it "passes placeholder as a data attribute" do
      expect(rendered_form).to have_element "opce-range-date-picker",
                                            "data-placeholder": "Pick a range".to_json
    end
  end
end
