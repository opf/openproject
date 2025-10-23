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

RSpec.describe Budgets::MaterialBudgetItems::SubformRowComponent, type: :component do
  let(:project) { create(:project) }
  let(:budget) { create(:budget) }
  let(:table) do
    instance_double(
      Budgets::MaterialBudgetItems::SubformTableComponent,
      columns: %i[units cost_type comments cost],
      project:,
      budget:
    )
  end

  current_user { create(:admin) }

  subject(:rendered_component) do
    render_in_view_context(
      described_class,
      budget,
      budget_item,
      table,
      self
    ) do |described_class, budget, budget_item, table, spec_context|
      primer_form_with(url: "/foo", model: budget) do |f|
        spec_context.allow(table).to spec_context.receive(:form).and_return(f)

        render(described_class.new(row: budget_item, row_counter: 0, table:))
      end
    end

    rendered_content # we want a string rather Nokogiri::HTML5.fragment to workaround it stripping <tr>
  end

  context "with new budget item" do
    let(:budget_item) { build(:material_budget_item) }

    it "renders row" do
      expect(rendered_component).to have_element :tr
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Units' input" do
      expect(rendered_component).to have_field "Units" do |field|
        expect(field["name"]).to eq "budget[new_material_budget_item_attributes][0][units]"
        expect(field["id"]).to eq "budget_new_material_budget_item_attributes_0_units"
      end
    end

    it "renders the unit inside the units field" do
      expect(rendered_component)
        .to have_css "#budget_new_material_budget_item_attributes_0_unit_name", text: budget_item.cost_type.unit_plural
      expect(rendered_component).to have_field "Units" do |field|
        expect(field["aria-describedby"].to_s.split)
          .to include("budget_new_material_budget_item_attributes_0_unit_name")
      end
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[new_material_budget_item_attributes][0][comments]"
        expect(field["id"]).to eq "budget_new_material_budget_item_attributes_0_comments"
      end
    end

    it "renders 'Budget' override input hidden and enabled" do
      field_name = "budget[new_material_budget_item_attributes][0][amount]"

      expect(rendered_component).to have_field field_name, disabled: false, visible: :hidden do |field|
        expect(field["id"]).to eq "budget_new_material_budget_item_attributes_0_cost_override"
        expect(field["aria-label"]).to eq "Budget"
      end
    end

    it "renders no hint element" do
      expect(rendered_component).to have_no_selector :css, "[data-costs--budget-inline-cost-edit-target='hint']", visible: :all
    end
  end

  context "with existing budget item" do
    let(:budget_item) { create(:material_budget_item) }

    it "renders row" do
      expect(rendered_component).to have_element :tr
    end

    it "renders cells" do
      expect(rendered_component).to have_element :td, count: 5
    end

    it "renders 'Units' input" do
      expect(rendered_component).to have_field "Units" do |field|
        expect(field["name"]).to eq "budget[existing_material_budget_item_attributes][#{budget_item.id}][units]"
        expect(field["id"]).to eq "budget_existing_material_budget_item_attributes_#{budget_item.id}_units"
      end
    end

    context "with fractional units" do
      let(:budget_item) { create(:material_budget_item, units: 3.5) }

      it "renders the units formatted" do
        expect(rendered_component).to have_field "Units", with: "3.50"
      end

      context "with a German locale" do
        around { |example| I18n.with_locale(:de, &example) }

        it "renders the units with the locale's separator" do
          expect(rendered_component)
            .to have_field MaterialBudgetItem.human_attribute_name(:units), with: "3,50"
        end
      end
    end

    it "renders the unit inside the units field" do
      expect(rendered_component)
        .to have_css "#budget_existing_material_budget_item_attributes_#{budget_item.id}_unit_name",
                     text: budget_item.cost_type.unit_plural
      expect(rendered_component).to have_field "Units" do |field|
        expect(field["aria-describedby"].to_s.split)
          .to include("budget_existing_material_budget_item_attributes_#{budget_item.id}_unit_name")
      end
    end

    it "renders 'Comment' input" do
      expect(rendered_component).to have_field "Comment" do |field|
        expect(field["name"]).to eq "budget[existing_material_budget_item_attributes][#{budget_item.id}][comments]"
        expect(field["id"]).to eq "budget_existing_material_budget_item_attributes_#{budget_item.id}_comments"
      end
    end

    it "renders 'Budget' override input hidden and enabled" do
      field_name = "budget[existing_material_budget_item_attributes][#{budget_item.id}][amount]"

      expect(rendered_component).to have_field field_name, disabled: false, visible: :hidden do |field|
        expect(field["id"]).to eq "budget_existing_material_budget_item_attributes_#{budget_item.id}_cost_override"
        expect(field["aria-label"]).to eq "Budget"
      end
    end

    it "renders no hint element" do
      expect(rendered_component).to have_no_selector :css, "[data-costs--budget-inline-cost-edit-target='hint']", visible: :all
    end
  end

  context "with an overridden budget item" do
    let(:budget_item) { create(:material_budget_item, amount: 250) }

    it "renders the override input enabled with the override" do
      expect(rendered_component).to have_field accessible_name: "Budget", with: "250.00"
    end
  end

  context "with a budget item without cost type" do
    let(:budget_item) { build(:material_budget_item, cost_type: nil) }

    it "renders an empty unit element for the row refresh" do
      expect(rendered_component)
        .to have_css "#budget_new_material_budget_item_attributes_0_unit_name", exact_text: "", normalize_ws: true, visible: :all
    end
  end

  context "with the template row" do
    let(:budget_item) { build(:material_budget_item) }

    subject(:rendered_component) do
      render_in_view_context(
        described_class, budget, budget_item, table, self
      ) do |described_class, budget, budget_item, table, spec_context|
        primer_form_with(url: "/foo", model: budget) do |f|
          spec_context.allow(table).to spec_context.receive(:form).and_return(f)

          render(described_class.new(row: budget_item, row_counter: nil, table:, templated: true))
        end
      end

      rendered_content
    end

    it "carries the INDEX placeholder in every id and name" do
      expect(rendered_component).to have_element :tr, id: "budget_new_material_budget_item_attributes_INDEX"
      expect(rendered_component).to have_css "#budget_new_material_budget_item_attributes_INDEX_unit_name", visible: :all
      expect(rendered_component).to have_css "#budget_new_material_budget_item_attributes_INDEX_costs"
    end
  end
end
