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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::SegmentedControl, type: :forms do
  include ViewComponent::TestHelpers

  describe "rendering" do
    let(:value) { "t" }
    let(:items) do
      [
        { value: "f", label: "No" },
        { value: "t", label: "Yes" }
      ]
    end
    let(:wrapper_data_attributes) do
      { "filter--filters-form-target": "filterValueContainer", "filter-name": "blocked" }
    end

    def render_form
      render_in_view_context(value, items, wrapper_data_attributes) do |value, items, wrapper_data_attributes|
        primer_form_with(url: "/foo") do |f|
          render_inline_form(f) do |form|
            form.segmented_control(
              name: :blocked_value,
              label: "Blocked",
              value:,
              items:,
              wrapper_data_attributes:
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
      expect(rendered_form).to have_element :label, text: "Blocked"
    end

    it "renders one button per item" do
      expect(rendered_form).to have_button "No"
      expect(rendered_form).to have_button "Yes"
      expect(rendered_form).to have_button count: 2
    end

    it "renders a hidden field carrying the current value" do
      field = rendered_form.find(:element, "data-filter--segmented-control-target": "field", visible: :all)

      expect(field[:type]).to eq("hidden")
      expect(field[:value]).to eq("t")
    end

    it "marks the item matching the value as current" do
      expect(rendered_form).to have_button "Yes", aria: { current: true }
      expect(rendered_form).to have_button aria: { current: true }, count: 1
    end

    context "when no value is given" do
      let(:value) { nil }

      it "falls back to the first item" do
        field = rendered_form.find(:element, "data-filter--segmented-control-target": "field", visible: :all)

        expect(field[:value]).to eq("f")
        expect(rendered_form).to have_button "No", aria: { current: true }
        expect(rendered_form).to have_button aria: { current: true }, count: 1
      end
    end

    it "applies wrapper data attributes to the form control" do
      expect(rendered_form).to have_element "data-filter--filters-form-target": "filterValueContainer",
                                            "data-filter-name": "blocked"
    end
  end
end
