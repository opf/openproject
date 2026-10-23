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

RSpec.describe Budgets::MaterialBudgetItems::SubformComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { create(:project) }
  let(:budget) { create(:budget) }
  let(:form) { instance_double(Primer::Forms::Builder, fields_for: "") }

  subject(:rendered_component) do
    with_controller_class(BudgetsController) do
      with_request_url("/budgets/1/edit") do
        render_component(budget: budget, form:, project:)
      end
    end
  end

  before do
    budget.reload
  end

  context "with no cost types" do
    it "renders nothing" do
      expect(rendered_component.to_s).to be_blank
    end
  end

  context "with cost types" do
    let!(:cost_type) { create(:cost_type, unit: "cap", unit_plural: "caps") }

    context "with no budget items" do
      let!(:budget_items) { create_list(:material_budget_item, 0, budget:) }

      it "renders collapsible section" do
        expect(rendered_component).to have_element :"collapsible-section" do |table|
          expect(table["data-controller"]).to eq "costs--budget-subform"
          expect(table["data-costs--budget-subform-item-count-value"]).to eq "1"
        end
      end

      it "renders table" do
        expect(rendered_component).to have_element :table do |table|
          expect(table["data-costs--budget-subform-target"]).to eq "table"
        end
      end
    end

    context "with budget items" do
      let!(:budget_items) { create_list(:material_budget_item, 2, budget:) }

      it "renders collapsible section" do
        expect(rendered_component).to have_element :"collapsible-section" do |table|
          expect(table["data-controller"]).to eq "costs--budget-subform"
          expect(table["data-costs--budget-subform-item-count-value"]).to eq "3"
        end
      end

      it "renders table" do
        expect(rendered_component).to have_element :table do |table|
          expect(table["data-costs--budget-subform-target"]).to eq "table"
        end
      end
    end
  end
end
