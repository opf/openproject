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

RSpec.describe Budgets::AggregatedBudgetsWithSpend do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_budgets
                                                    view_cost_entries
                                                    view_cost_rates
                                                    view_time_entries
                                                    view_hourly_rates
                                                    work_package_assigned] })
  end
  shared_let(:work_package) { create(:work_package, project: project) }

  subject(:aggregated) do
    described_class.new(project:, current_user: user)
  end

  describe "#spent_total" do
    context "with no spending" do
      it "returns 0" do
        expect(aggregated.spent_total).to eq(0)
      end
    end

    context "with both material and labor spending" do
      let!(:budget) { create(:budget, project:) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 50.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project:,
               user:,
               hours: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update!(budget:)
        create(:hourly_rate,
               user:,
               project:,
               rate: 50.0,
               valid_from: Date.current - 1.day)
      end

      it "sums material and labor costs" do
        expect(aggregated.spent_total).to eq(BigDecimal("2000"))
      end
    end
  end

  describe "#spent_ratio" do
    context "with zero budget total" do
      it "returns 0 without raising error" do
        expect(aggregated.spent_ratio).to eq(BigDecimal("0"))
      end
    end

    context "with normal spending" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 250.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update(budget:)
      end

      it "calculates the ratio of spent to budget" do
        expect(aggregated.spent_ratio).to eq(BigDecimal("0.5"))
      end
    end

    context "when over budget" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 750.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update(budget:)
      end

      it "returns a ratio greater than 1" do
        expect(aggregated.spent_ratio).to eq(BigDecimal("1.5"))
      end
    end

    context "with no spending" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }

      it "returns 0" do
        expect(aggregated.spent_ratio).to eq(BigDecimal("0"))
      end
    end
  end

  describe "#remaining" do
    context "with positive remaining budget" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 150.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update(budget:)
      end

      it "calculates remaining as budgeted_total - spent_total" do
        expect(aggregated.remaining).to eq(BigDecimal("7000"))
      end
    end

    context "when at budget" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 500.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update(budget:)
      end

      it "returns 0" do
        expect(aggregated.remaining).to eq(BigDecimal("0"))
      end
    end

    context "when over budget" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 600.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package,
               project:,
               user:,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      before do
        work_package.update(budget:)
      end

      it "returns negative value" do
        expect(aggregated.remaining).to eq(BigDecimal("-2000"))
      end
    end

    context "with no spending" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }

      it "returns the total budget" do
        expect(aggregated.remaining).to eq(BigDecimal("10000"))
      end
    end
  end

  describe "delegation" do
    let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
    let!(:cost_type) { create(:cost_type) }
    let!(:cost_rate) do
      create(:cost_rate,
             cost_type:,
             valid_from: Date.current - 1.day,
             rate: 100.0)
    end
    let!(:cost_entry) do
      create(:cost_entry,
             entity: work_package,
             project:,
             user:,
             cost_type:,
             units: 10,
             spent_on: Date.current)
    end
    let!(:labor_item) do
      create(:labor_budget_item,
             budget:,
             user:,
             hours: 100,
             amount: BigDecimal("5000"))
    end

    before do
      work_package.update!(budget:)
      create(:hourly_rate,
             user:,
             project:,
             rate: 50.0,
             valid_from: Date.current - 1.day)
    end

    it "delegates budget_count to Budgets::AggregatedBudgets" do
      expect(aggregated.budget_count).to eq(1)
    end

    it "delegates budgeted_base to Budgets::AggregatedBudgets" do
      expect(aggregated.budgeted_base).to eq(BigDecimal("10000"))
    end

    it "delegates budgeted_labor to Budgets::AggregatedBudgets" do
      expect(aggregated.budgeted_labor).to eq(BigDecimal("5000"))
    end

    it "delegates spent_material to Costs::AggregatedCosts" do
      expect(aggregated.spent_material).to eq(BigDecimal("1000"))
    end
  end
end
