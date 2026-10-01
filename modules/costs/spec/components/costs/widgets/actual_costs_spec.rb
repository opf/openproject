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

RSpec.describe Costs::Widgets::ActualCosts, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { create(:project_with_types) }
  let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i[view_budgets
                                                    view_cost_entries
                                                    view_cost_rates
                                                    view_time_entries
                                                    view_hourly_rates] })
  end

  subject(:rendered_component) { render_component(project, current_user:) }

  context "with spending data" do
    let!(:budget) { create(:budget, project:) }
    let(:work_package) { create(:work_package, project:, budget:) }
    let!(:hourly_rate) do
      create(:hourly_rate,
             user: current_user,
             project: project,
             rate: 50.0,
             valid_from: 1.month.ago)
    end
    let!(:time_entry) do
      create(:time_entry,
             entity: work_package,
             project: project,
             user: current_user,
             hours: 40,
             spent_on: Date.current)
    end

    it "renders angular component" do
      expect(rendered_component).to have_css("opce-actual-costs")
    end

    it "renders view details link in the widget footer" do
      expect(rendered_component).to have_test_selector("actual-costs-widget-footer") do |footer|
        expect(footer).to have_link(href: cost_reports_path(project))
      end
    end

    it "passes currency attribute" do
      expect(rendered_component).to have_element "opce-actual-costs" do |element|
        expect(element["currency"]).to eq(Setting.costs_currency)
      end
    end

    it "passes chart data with correct structure" do
      expect(rendered_component).to have_element "opce-actual-costs" do |element|
        chart_data_json = element["chart-data"]
        expect(chart_data_json).to be_present

        chart_data = JSON.parse(chart_data_json)
        expect(chart_data).to have_key("labels")
        expect(chart_data).to have_key("datasets")
        expect(chart_data["labels"]).to be_an(Array)
        expect(chart_data["datasets"]).to be_an(Array)

        # Verify labor dataset exists
        labor_dataset = chart_data["datasets"].find { |ds| ds["label"] == I18n.t(:caption_labor) }
        expect(labor_dataset).to be_present
        expect(labor_dataset["data"]).to be_an(Array)
      end
    end

    it "includes actual cost data in chart datasets" do
      expect(rendered_component).to have_element "opce-actual-costs" do |element|
        chart_data = JSON.parse(element["chart-data"])

        expect(chart_data["labels"]).not_to be_empty
        expect(chart_data["datasets"]).not_to be_empty

        # Verify labor dataset has data
        labor_dataset = chart_data["datasets"].first
        expect(labor_dataset["data"]).not_to be_empty
        expect(labor_dataset["data"].sum(&:to_f)).to be > 0
      end
    end
  end

  context "with material cost entries" do
    let!(:budget) { create(:budget, project:) }
    let(:work_package) { create(:work_package, project:, budget:) }
    let(:cost_type) { create(:cost_type, name: "Development") }
    let!(:cost_rate) do
      create(:cost_rate,
             cost_type:,
             valid_from: 1.month.ago,
             rate: 100.0)
    end
    let!(:cost_entry) do
      create(:cost_entry,
             entity: work_package,
             project:,
             user: current_user,
             cost_type:,
             units: 20,
             spent_on: Date.current)
    end

    it "includes material cost data in chart datasets" do
      expect(rendered_component).to have_element "opce-actual-costs" do |element|
        chart_data = JSON.parse(element["chart-data"])
        material_dataset = chart_data["datasets"].find { |ds| ds["label"] == "Development" }

        expect(material_dataset).to be_present
        expect(material_dataset["data"].sum(&:to_f)).to be > 0
      end
    end
  end

  context "with spending data only from a prior year" do
    let!(:budget) { create(:budget, project:) }
    let(:work_package) { create(:work_package, project:, budget:) }
    let!(:hourly_rate) do
      create(:hourly_rate,
             user: current_user,
             project: project,
             rate: 50.0,
             valid_from: 2.years.ago)
    end
    let!(:time_entry_last_year) do
      create(:time_entry,
             entity: work_package,
             project: project,
             user: current_user,
             hours: 40,
             spent_on: 1.year.ago.to_date)
    end

    it "shows the blankslate instead of the chart" do
      expect(rendered_component).to have_no_css("opce-actual-costs")
      expect(rendered_component).to have_css(".blankslate")
    end
  end

  context "without spending data" do
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t("costs.widgets.actual_costs.blankslate.heading")
  end

  context "without proper permissions" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it "renders nothing" do
      expect(rendered_component.to_s).to be_empty
    end
  end

  context "with partial permissions" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_time_entries] })
    end

    it "renders nothing when missing cost entry permissions" do
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
