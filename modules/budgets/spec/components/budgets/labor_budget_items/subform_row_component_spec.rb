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

RSpec.describe Budgets::LaborBudgetItems::SubformRowComponent, type: :component do
  let(:project) { create(:project) }
  let(:budget) { create(:budget) }
  let(:table) do
    instance_double(
      Budgets::LaborBudgetItems::SubformTableComponent,
      columns: %i[hours user comments cost],
      project:,
      budget:
    )
  end

  current_user { create(:admin) }

  subject(:rendered_component) do
    render_in_view_context(
      described_class,
      budget_item,
      budget,
      table,
      self
    ) do |described_class, budget_item, budget, table, spec_context|
      primer_form_with(url: "/foo", model: budget) do |f|
        spec_context.allow(table).to spec_context.receive(:form).and_return(f)

        render(described_class.new(row: budget_item, row_counter: 0, table:))
      end
    end

    rendered_content # we want a string rather Nokogiri::HTML5.fragment to workaround it stripping <tr>
  end

  context "with new budget item" do
    let(:budget_item) { build(:labor_budget_item, budget:) }

    it "renders row" do
      expect(rendered_component).to have_element :tr, id: "budget_new_labor_budget_item_attributes_0"
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Hours' input as a chronic duration field" do
      expect(rendered_component).to have_field "Hours", placeholder: "e.g., 2d 10h" do |field|
        expect(field["name"]).to eq "budget[new_labor_budget_item_attributes][0][hours]"
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_hours"
        expect(field["data-controller"]).to eq "chronic-duration"
        expect(field["data-request-key"]).to eq "hours"
      end
    end

    it "renders 'User' autocompleter" do
      # The inputs are JSON-encoded, so ">" appears as the literal escape \u003e
      expect(rendered_component)
        .to have_element "opce-user-autocompleter",
                         "data-input-name": %("budget[new_labor_budget_item_attributes][0][user_id]"),
                         "data-id": %("budget_new_labor_budget_item_attributes_0_user_id"),
                         "data-hidden-field-action": '"change-\u003ecosts--budget-subform#valueChanged"'
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[new_labor_budget_item_attributes][0][comments]"
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_comments"
      end
    end

    it "renders 'Budget' override input hidden and enabled" do
      expect(rendered_component)
        .to have_field "budget[new_labor_budget_item_attributes][0][amount]", disabled: false, visible: :hidden do |field|
        expect(field["id"]).to eq "budget_new_labor_budget_item_attributes_0_cost_override"
        expect(field["aria-label"]).to eq "Budget"
      end
    end

    it "renders the elements the row refresh writes to" do
      expect(rendered_component).to have_css "#budget_new_labor_budget_item_attributes_0_costs"
      expect(rendered_component).to have_css "#budget_new_labor_budget_item_attributes_0_cost_value", visible: :hidden
      expect(rendered_component).to have_css "#budget_new_labor_budget_item_attributes_0_cost_hint", visible: :all
      expect(rendered_component).to have_no_css "#budget_new_labor_budget_item_attributes_0_amount", visible: :all
    end
  end

  context "with existing budget item" do
    let(:budget_item) { create(:labor_budget_item, budget:) }

    it "renders row" do
      expect(rendered_component).to have_element :tr, id: "budget_existing_labor_budget_item_attributes_#{budget_item.id}"
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Hours' input as a chronic duration field" do
      expect(rendered_component).to have_field "Hours", placeholder: "e.g., 2d 10h" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][hours]"
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_hours"
        expect(field["data-controller"]).to eq "chronic-duration"
        expect(field["data-request-key"]).to eq "hours"
      end
    end

    it "renders the hours as a duration" do
      budget_item.update!(hours: 12)

      expect(rendered_component).to have_field "Hours", with: DurationConverter.output(12)
    end

    it "renders 'User' autocompleter" do
      # The inputs are JSON-encoded, so ">" appears as the literal escape \u003e
      expect(rendered_component)
        .to have_element "opce-user-autocompleter",
                         "data-input-name": %("budget[existing_labor_budget_item_attributes][#{budget_item.id}][user_id]"),
                         "data-id": %("budget_existing_labor_budget_item_attributes_#{budget_item.id}_user_id"),
                         "data-hidden-field-action": '"change-\u003ecosts--budget-subform#valueChanged"'
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][comments]"
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_comments"
      end
    end

    it "renders 'Budget' override input hidden and enabled" do
      field_name = "budget[existing_labor_budget_item_attributes][#{budget_item.id}][amount]"

      expect(rendered_component).to have_field field_name, disabled: false, visible: :hidden do |field|
        expect(field["id"]).to eq "budget_existing_labor_budget_item_attributes_#{budget_item.id}_cost_override"
        expect(field["aria-label"]).to eq "Budget"
      end
    end

    it "renders the elements the row refresh writes to" do
      prefix = "#budget_existing_labor_budget_item_attributes_#{budget_item.id}"

      expect(rendered_component).to have_css "#{prefix}_costs"
      expect(rendered_component).to have_css "#{prefix}_cost_value", visible: :hidden
      expect(rendered_component).to have_css "#{prefix}_cost_hint", visible: :all
      expect(rendered_component).to have_no_css "#{prefix}_amount", visible: :all
    end
  end

  context "with an overridden budget item" do
    let(:budget_item) { create(:labor_budget_item, budget:, amount: 250) }

    it "renders the override input enabled with the override" do
      expect(rendered_component).to have_field accessible_name: "Budget", with: "250.00" do |field|
        expect(field["name"]).to eq "budget[existing_labor_budget_item_attributes][#{budget_item.id}][amount]"
      end
    end
  end

  context "with a budget item whose user has no hourly rate" do
    let(:user) { create(:user) }
    let(:budget_item) { create(:labor_budget_item, budget:, principal: user, hours: 5) }

    it "renders the missing rate hint" do
      expect(rendered_component)
        .to have_css "#budget_existing_labor_budget_item_attributes_#{budget_item.id}_cost_hint",
                     text: I18n.t("budgets.labor_budget_items.no_rate_at_fixed_date", date: I18n.l(budget.fixed_date))
    end
  end

  context "when the current user may not see the costs" do
    current_user { create(:user, member_with_permissions: { budget.project => %i[view_budgets edit_budgets] }) }

    let(:budget_item) { create(:labor_budget_item, budget:, hours: 5) }

    it "renders neither the cost nor a hint element" do
      prefix = "budget_existing_labor_budget_item_attributes_#{budget_item.id}"

      expect(rendered_component).to have_css "##{prefix}_costs", exact_text: ""
      expect(rendered_component).to have_no_css "##{prefix}_cost_hint", visible: :all
      expect(rendered_component).to have_no_selector :css, "##{prefix}_cost_override", visible: :all
    end
  end

  context "with the template row" do
    let(:budget_item) { build(:labor_budget_item, budget:) }

    subject(:rendered_component) do
      render_in_view_context(
        described_class, budget_item, budget, table, self
      ) do |described_class, budget_item, budget, table, spec_context|
        primer_form_with(url: "/foo", model: budget) do |f|
          spec_context.allow(table).to spec_context.receive(:form).and_return(f)

          render(described_class.new(row: budget_item, row_counter: nil, table:, templated: true))
        end
      end

      rendered_content
    end

    it "carries the INDEX placeholder in every id and name" do
      expect(rendered_component).to have_element :tr, id: "budget_new_labor_budget_item_attributes_INDEX"
      expect(rendered_component).to have_css "#budget_new_labor_budget_item_attributes_INDEX_costs"
      expect(rendered_component)
        .to have_field "budget[new_labor_budget_item_attributes][INDEX][amount]", disabled: false, visible: :hidden
      expect(rendered_component).to include "budget[new_labor_budget_item_attributes][INDEX][user_id]"
    end
  end
end
