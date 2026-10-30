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

require "rails_helper"

RSpec.describe Budgets::BudgetItems::InlineCostEditComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:arguments) do
    {
      control_id: "row_costs",
      calculated_id: "row_cost_value",
      input_name: "budget[rows][1][amount]",
      input_id: "row_cost_override",
      cost_value: BigDecimal("20")
    }
  end
  let(:options) { {} }

  subject(:rendered_component) { render_component(**arguments, **options) }

  context "without an override" do
    it "shows the edit button and hides the cancel button" do
      expect(rendered_component).to have_button accessible_name: "Click here to edit."
      expect(rendered_component).to have_css "button[data-test-selector='cancel_inline_cost_edit']", visible: :hidden
    end

    it "shows the calculated cost with currency in the display element" do
      expect(rendered_component).to have_css "#row_costs", text: "20.00 €"
    end

    it "renders the override input hidden, enabled and empty so that a blank amount is submitted" do
      expect(rendered_component)
        .to have_field "budget[rows][1][amount]", disabled: false, visible: :hidden do |field|
          expect(field["id"]).to eq "row_cost_override"
          expect(field.value).to be_blank
          expect(field["aria-label"]).to eq "Budget"
        end
    end

    it "keeps the unformatted calculated cost in a hidden holder" do
      expect(rendered_component).to have_css "#row_cost_value", text: "20.00", visible: :hidden
    end

    it "does not mark the controller as editing" do
      expect(rendered_component).to have_no_css "[data-costs--budget-inline-cost-edit-is-editing-value='true']"
    end

    it "never renders a hidden amount field" do
      expect(rendered_component).to have_no_selector :css, "input[type='hidden']", visible: :all
    end
  end

  context "with an override" do
    let(:options) { { override_value: BigDecimal("123.5") } }

    it "renders the override input enabled and visible with the override" do
      expect(rendered_component)
        .to have_field accessible_name: "Budget", with: "123.50", disabled: false, accessible_description: "€"
    end

    it "shows the cancel button and hides the edit button and display" do
      expect(rendered_component).to have_button accessible_name: "Cancel editing budget"
      expect(rendered_component).to have_css "button[data-test-selector='edit_inline_cost']", visible: :hidden
      expect(rendered_component).to have_css "#row_costs", text: "20.00 €", visible: :hidden
    end

    it "marks the controller as editing" do
      expect(rendered_component).to have_css "[data-costs--budget-inline-cost-edit-is-editing-value='true']"
    end
  end

  context "when the costs must not be shown" do
    let(:options) { { show_cost: false } }

    it "renders an empty display element" do
      expect(rendered_component).to have_css "#row_costs", exact_text: ""
    end

    it "renders no edit machinery" do
      expect(rendered_component).to have_no_selector :css, "[data-test-selector='edit_inline_cost']", visible: :all
      expect(rendered_component).to have_no_selector :css, "[data-test-selector='cancel_inline_cost_edit']", visible: :all
      expect(rendered_component).to have_no_selector :css, "input", visible: :all
      expect(rendered_component)
        .to have_no_selector :css, "[data-costs--budget-inline-cost-edit-target='calculated']", visible: :all
      expect(rendered_component).to have_no_selector :css, "[data-controller]", visible: :all
    end

    it "does not make the display element focusable or clickable" do
      expect(rendered_component).to have_no_selector :css, "[tabindex]", visible: :all
      expect(rendered_component).to have_no_selector :css, "[data-action]", visible: :all
    end

    context "with an override" do
      let(:options) { { show_cost: false, override_value: BigDecimal("123.5") } }

      it "does not expose the override amount" do
        expect(rendered_component.to_html).not_to include "123"
        expect(rendered_component).to have_no_selector :css, "input", visible: :all
      end
    end
  end

  context "without a hint" do
    it "renders no hint element" do
      expect(rendered_component).to have_no_css "[data-costs--budget-inline-cost-edit-target='hint']", visible: :all
    end
  end

  context "with an empty hint" do
    let(:options) { { hint: "", hint_id: "row_cost_hint" } }

    it "renders the empty hint element so the row refresh can fill it" do
      expect(rendered_component).to have_css "#row_cost_hint", exact_text: "", visible: :all
    end
  end

  context "with a hint" do
    let(:options) { { hint: "No hourly rate", hint_id: "row_cost_hint" } }

    it "renders the hint and describes the input with it" do
      expect(rendered_component).to have_css "#row_cost_hint", text: "No hourly rate"
      expect(rendered_component)
        .to have_field "budget[rows][1][amount]", disabled: false, visible: :hidden do |field|
          expect(field["aria-describedby"].split).to include("row_cost_hint")
        end
    end

    context "with an override" do
      let(:options) { { hint: "No hourly rate", hint_id: "row_cost_hint", override_value: BigDecimal(5) } }

      it "hides the hint" do
        expect(rendered_component).to have_css "#row_cost_hint", visible: :hidden
      end
    end
  end
end
