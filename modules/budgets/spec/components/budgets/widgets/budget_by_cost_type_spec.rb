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

RSpec.describe Budgets::Widgets::BudgetByCostType, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { create(:project_with_types) }
  let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_budgets view_cost_rates
                                                           view_hourly_rates work_package_assigned] })
  end

  subject(:rendered_component) { render_component(project, current_user:) }

  context "with budget and items" do
    let(:cost_type) { create(:cost_type, name: "Materials A") }
    let!(:budget) { create(:budget, project: project) }
    let!(:labor_item) do
      create(:labor_budget_item,
             budget: budget,
             user: current_user,
             hours: 100,
             amount: BigDecimal("5000"))
    end
    let!(:material_item) do
      create(:material_budget_item,
             budget: budget,
             cost_type: cost_type,
             units: 50,
             amount: BigDecimal("3000"))
    end

    it "renders angular component" do
      expect(rendered_component).to have_css("opce-budget-by-cost-type")
    end

    it "renders view details link in the widget footer" do
      expect(rendered_component).to have_test_selector("budget-by-cost-type-widget-footer") do |footer|
        expect(footer).to have_link(href: projects_budgets_path(project))
      end
    end

    it "displays caption with workspace type (no subitems for leaf project)" do
      expect(rendered_component).to have_text("Data aggregated from 1 budget")
      expect(rendered_component).to have_no_text(/Project/)
      expect(rendered_component).to have_no_text(/subitems/)
    end

    it "interpolates count in the one branch" do
      expect(I18n.t("budgets.widgets.budget_by_cost_type.count_caption", count: 1)).to eq("Data aggregated from 1 budget")
    end

    it "pluralizes the caption without subitems" do
      create(:budget, project: project)

      expect(rendered_component).to have_text("Data aggregated from 2 budgets")
    end

    it "passes currency attribute" do
      expect(rendered_component).to have_element "opce-budget-by-cost-type" do |element|
        expect(element["currency"]).to eq(Setting.costs_currency)
      end
    end

    it "passes chart data with correct structure" do
      expect(rendered_component).to have_element "opce-budget-by-cost-type" do |element|
        chart_data_json = element["chart-data"]
        expect(chart_data_json).to be_present

        chart_data = JSON.parse(chart_data_json)
        expect(chart_data).to have_key("labels")
        expect(chart_data).to have_key("datasets")
        expect(chart_data["labels"]).to be_an(Array)
        expect(chart_data["datasets"]).to be_an(Array)
        expect(chart_data["datasets"]).to have_attributes(size: 1)

        dataset = chart_data["datasets"].first
        expect(dataset).to have_key("label")
        expect(dataset).to have_key("data")
        expect(dataset["label"]).to eq(I18n.t(:label_budget))
        expect(dataset["data"]).to be_an(Array)
      end
    end

    it "includes budget data with labor and material costs" do
      expect(rendered_component).to have_element "opce-budget-by-cost-type" do |element|
        chart_data = JSON.parse(element["chart-data"])

        # Should have labels for labor and material type
        expect(chart_data["labels"]).to include(I18n.t(:caption_labor))
        expect(chart_data["labels"]).to include("Materials A")

        # Should have corresponding data values
        expect(chart_data["datasets"].first["data"].size).to eq(chart_data["labels"].size)
        # Data values should be numeric (convert strings to float for comparison)
        data_values = chart_data["datasets"].first["data"].map(&:to_f)
        expect(data_values).to all(be_a(Numeric))
      end
    end
  end

  context "with a project that has children" do
    let(:project) { create(:project_with_types) }
    let!(:child) { create(:project_with_types, parent: project) }
    let!(:budget) { create(:budget, project:) }
    let!(:labor_item) do
      create(:labor_budget_item,
             budget: budget,
             user: current_user,
             hours: 100,
             amount: BigDecimal("5000"))
    end

    it "displays caption with workspace type and subitems" do
      expect(rendered_component).to have_text("Data aggregated from 1 budget included in this project and its subitems.")
    end

    it "pluralizes the project caption with subitems" do
      create(:budget, project:)

      expect(rendered_component).to have_text("Data aggregated from 2 budgets included in this project and its subitems.")
    end
  end

  context "with a program that has children" do
    let(:project) { create(:program) }
    let!(:child) { create(:project_with_types, parent: project) }
    let!(:budget) { create(:budget, project:) }
    let!(:labor_item) do
      create(:labor_budget_item,
             budget: budget,
             user: current_user,
             hours: 100,
             amount: BigDecimal("5000"))
    end

    it "displays the program-specific caption with subitems" do
      expect(rendered_component).to have_text("Data aggregated from 1 budget included in this program and its subitems.")
    end
  end

  context "with a portfolio that has children" do
    let(:project) { create(:portfolio) }
    let!(:child) { create(:project_with_types, parent: project) }
    let!(:budget) { create(:budget, project:) }
    let!(:labor_item) do
      create(:labor_budget_item,
             budget: budget,
             user: current_user,
             hours: 100,
             amount: BigDecimal("5000"))
    end

    it "displays the portfolio-specific caption with subitems" do
      expect(rendered_component).to have_text("Data aggregated from 1 budget included in this portfolio and its subitems.")
    end
  end

  context "without budgets" do
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t("budgets.widgets.budget_by_cost_type.blankslate.heading")
  end

  context "without proper permissions" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "without view_cost_rates permission" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_budgets] })
    end

    it "renders nothing when missing cost rate permissions" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  describe "#wrapper_arguments" do
    let(:component) { described_class.new(project) }

    it "returns empty hash" do
      expect(component.wrapper_arguments).to eq({})
    end
  end
end
