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

RSpec.describe Costs::AggregatedCosts do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_cost_entries
                                                    view_cost_rates
                                                    view_time_entries
                                                    view_hourly_rates
                                                    view_own_hourly_rate
                                                    view_budgets] })
  end
  shared_let(:budget) { create(:budget, project:) }
  shared_let(:work_package) { create(:work_package, project:, budget:) }

  subject(:aggregated) { described_class.new(project:, current_user: user) }

  describe "#spent_material" do
    context "with no cost entries" do
      it "returns 0" do
        expect(aggregated.spent_material).to eq(0)
      end
    end

    context "with cost entries" do
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
               units: 20,
               spent_on: Date.current)
      end

      it "sums effective costs" do
        expect(aggregated.spent_material).to eq(BigDecimal("2000"))
      end
    end

    context "with overridden costs" do
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
               units: 20,
               spent_on: Date.current,
               overridden_costs: BigDecimal("2500"))
      end

      it "uses overridden costs" do
        expect(aggregated.spent_material).to eq(BigDecimal("2500"))
      end
    end

    context "without view_cost_rates permission" do
      let(:user_without_cost_rates) do
        create(:user, member_with_permissions: { project => %i[view_cost_entries] })
      end
      let(:aggregated_without_cost_rates) { described_class.new(project:, current_user: user_without_cost_rates) }
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
               project: project,
               user: user_without_cost_rates,
               cost_type:,
               units: 20,
               spent_on: Date.current)
      end

      it "returns 0" do
        expect(aggregated_without_cost_rates.spent_material).to eq(0)
      end
    end
  end

  describe "#spent_labor" do
    context "with no time entries" do
      it "returns 0" do
        expect(aggregated.spent_labor).to eq(0)
      end
    end

    context "with time entries" do
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project:,
               user:,
               hours: 40,
               spent_on: Date.current)
      end

      before do
        create(:hourly_rate,
               user:,
               project:,
               rate: 50.0,
               valid_from: Date.current - 1.day)
      end

      it "sums effective costs" do
        expect(aggregated.spent_labor).to eq(BigDecimal("2000"))
      end
    end

    context "without view_hourly_rates permission" do
      let(:user_without_hourly_rates) do
        create(:user, member_with_permissions: { project => %i[view_time_entries] })
      end
      let(:aggregated_without_hourly_rates) { described_class.new(project:, current_user: user_without_hourly_rates) }
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project: project,
               user: user_without_hourly_rates,
               hours: 40,
               spent_on: Date.current)
      end

      before do
        create(:hourly_rate,
               user: user_without_hourly_rates,
               project: project,
               rate: 50.0,
               valid_from: Date.current - 1.day)
      end

      it "returns 0" do
        expect(aggregated_without_hourly_rates.spent_labor).to eq(0)
      end
    end

    context "with view_own_hourly_rate permission only" do
      let(:user_with_own_rate_only) do
        create(:user,
               member_with_permissions: { project => %i[view_time_entries view_own_hourly_rate] })
      end
      let(:other_user) do
        create(:user, member_with_permissions: { project => %i[view_time_entries] })
      end
      let(:aggregated_with_own_rate) { described_class.new(project:, current_user: user_with_own_rate_only) }
      let!(:own_time_entry) do
        create(:time_entry,
               entity: work_package,
               project: project,
               user: user_with_own_rate_only,
               hours: 40,
               spent_on: Date.current)
      end
      let!(:other_time_entry) do
        create(:time_entry,
               entity: work_package,
               project: project,
               user: other_user,
               hours: 20,
               spent_on: Date.current)
      end

      before do
        create(:hourly_rate,
               user: user_with_own_rate_only,
               project: project,
               rate: 50.0,
               valid_from: Date.current - 1.day)
        create(:hourly_rate,
               user: other_user,
               project: project,
               rate: 60.0,
               valid_from: Date.current - 1.day)
      end

      it "includes only user's own time entries" do
        expect(aggregated_with_own_rate.spent_labor).to eq(BigDecimal("2000"))
      end
    end
  end

  describe "#spent_total" do
    context "with no spending" do
      it "returns 0" do
        expect(aggregated.spent_total).to eq(0)
      end
    end

    context "with both material and labor spending" do
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

    context "with only material spending" do
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

      it "returns only material costs" do
        expect(aggregated.spent_total).to eq(BigDecimal("1000"))
      end
    end

    context "with only labor spending" do
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project:,
               user:,
               hours: 20,
               spent_on: Date.current)
      end

      before do
        create(:hourly_rate,
               user:,
               project:,
               rate: 50.0,
               valid_from: Date.current - 1.day)
      end

      it "returns only labor costs" do
        expect(aggregated.spent_total).to eq(BigDecimal("1000"))
      end
    end
  end

  describe "#spent_material_by_month_and_type" do
    context "with cost entries in different months" do
      let!(:cost_type_a) { create(:cost_type, name: "Materials A") }
      let!(:cost_type_b) { create(:cost_type, name: "Materials B") }
      let!(:cost_rate_a) do
        create(:cost_rate,
               cost_type: cost_type_a,
               valid_from: Date.new(2025, 1, 1),
               rate: 100.0)
      end
      let!(:cost_rate_b) do
        create(:cost_rate,
               cost_type: cost_type_b,
               valid_from: Date.new(2025, 1, 1),
               rate: 100.0)
      end
      let!(:entry_jan_a) do
        create(:cost_entry,
               entity: work_package,
               project: project,
               user:,
               cost_type: cost_type_a,
               units: 10,
               spent_on: Date.new(2025, 1, 15))
      end
      let!(:entry_feb_a) do
        create(:cost_entry,
               entity: work_package,
               project: project,
               user:,
               cost_type: cost_type_a,
               units: 15,
               spent_on: Date.new(2025, 2, 10))
      end
      let!(:entry_jan_b) do
        create(:cost_entry,
               entity: work_package,
               project: project,
               user:,
               cost_type: cost_type_b,
               units: 5,
               spent_on: Date.new(2025, 1, 20))
      end

      it "groups costs by month and cost type" do
        result = aggregated.spent_material_by_month_and_type
        expect(result.count).to eq(3)
      end

      it "returns keys as [Date, cost_type_name] pairs" do
        result = aggregated.spent_material_by_month_and_type
        expect(result.keys).to all(be_an(Array).and(have_attributes(size: 2)))
        expect(result.keys.map(&:first)).to all(be_a(Date))
      end

      it "calculates sums for each group" do
        result = aggregated.spent_material_by_month_and_type
        total = result.sum { |_key, value| value }
        expect(total).to eq(BigDecimal("3000"))
      end
    end

    context "with no cost entries" do
      it "returns empty collection" do
        result = aggregated.spent_material_by_month_and_type
        expect(result.count).to eq(0)
      end
    end
  end

  describe "#spent_labor_by_month" do
    context "with time entries in different months" do
      let!(:entry_jan) do
        create(:time_entry,
               entity: work_package,
               project: project,
               user:,
               hours: 40,
               spent_on: Date.new(2025, 1, 15))
      end
      let!(:entry_feb) do
        create(:time_entry,
               entity: work_package,
               project: project,
               user:,
               hours: 30,
               spent_on: Date.new(2025, 2, 10))
      end

      before do
        create(:hourly_rate,
               user:,
               project:,
               rate: 50.0,
               valid_from: Date.new(2025, 1, 1))
      end

      it "groups costs by month" do
        result = aggregated.spent_labor_by_month
        expect(result.count).to eq(2)
      end

      it "returns a Date-keyed hash" do
        result = aggregated.spent_labor_by_month
        expect(result.keys).to all(be_a(Date))
      end

      it "calculates sums for each month" do
        result = aggregated.spent_labor_by_month
        total = result.sum { |_key, value| value }
        expect(total).to eq(BigDecimal("3500"))
      end
    end

    context "with no time entries" do
      it "returns empty collection" do
        result = aggregated.spent_labor_by_month
        expect(result.count).to eq(0)
      end
    end
  end

  describe "#months" do
    context "with both labor and material entries" do
      let!(:cost_type) { create(:cost_type, name: "Materials") }
      let!(:cost_rate) do
        create(:cost_rate, cost_type:, valid_from: Date.new(2025, 1, 1), rate: 100.0)
      end
      let!(:cost_entry) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 10, spent_on: Date.new(2025, 3, 15))
      end
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package, project:, user:,
               hours: 10, spent_on: Date.new(2025, 1, 10))
      end

      before do
        create(:hourly_rate, user:, project:, rate: 50.0, valid_from: Date.new(2025, 1, 1))
      end

      it "returns the sorted union of labor and material months as Date objects" do
        expect(aggregated.months).to eq(
          [Date.new(2025, 1, 1), Date.new(2025, 3, 1)]
        )
      end
    end

    context "with no entries" do
      it "returns an empty array" do
        expect(aggregated.months).to eq([])
      end
    end

    context "with a date_range" do
      subject(:aggregated) do
        described_class.new(project:, current_user: user,
                            date_range: Date.new(2025, 1, 1)..Date.new(2025, 3, 31))
      end

      it "returns every month in the range as Date objects, regardless of data" do
        expect(aggregated.months).to eq(
          [Date.new(2025, 1, 1), Date.new(2025, 2, 1), Date.new(2025, 3, 1)]
        )
      end
    end
  end

  describe "#cost_type_names" do
    context "with material entries of different types" do
      let!(:cost_type_a) { create(:cost_type, name: "Concrete") }
      let!(:cost_type_b) { create(:cost_type, name: "Steel") }
      let!(:cost_rate_a) do
        create(:cost_rate, cost_type: cost_type_a, valid_from: Date.new(2025, 1, 1), rate: 100.0)
      end
      let!(:cost_rate_b) do
        create(:cost_rate, cost_type: cost_type_b, valid_from: Date.new(2025, 1, 1), rate: 100.0)
      end
      let!(:entry_a) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type: cost_type_a,
               units: 10, spent_on: Date.new(2025, 1, 15))
      end
      let!(:entry_b) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type: cost_type_b,
               units: 5, spent_on: Date.new(2025, 1, 20))
      end

      it "returns unique cost type names" do
        expect(aggregated.cost_type_names).to contain_exactly("Concrete", "Steel")
      end
    end

    context "with no material entries" do
      it "returns an empty array" do
        expect(aggregated.cost_type_names).to eq([])
      end
    end
  end

  describe "date_range filtering" do
    let(:date_range) { Date.new(2025, 1, 1)..Date.new(2025, 12, 31) }
    let!(:cost_type) { create(:cost_type) }
    let!(:cost_rate) do
      create(:cost_rate, cost_type:, valid_from: Date.new(2024, 1, 1), rate: 100.0)
    end

    subject(:aggregated) { described_class.new(project:, current_user: user, date_range:) }

    before do
      create(:hourly_rate, user:, project:, rate: 50.0, valid_from: Date.new(2024, 1, 1))
    end

    context "with entries inside and outside the date range" do
      let!(:cost_entry_in_range) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 10, spent_on: Date.new(2025, 6, 15))
      end
      let!(:cost_entry_out_of_range) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 20, spent_on: Date.new(2024, 6, 15))
      end
      let!(:time_entry_in_range) do
        create(:time_entry,
               entity: work_package, project:, user:,
               hours: 10, spent_on: Date.new(2025, 3, 10))
      end
      let!(:time_entry_out_of_range) do
        create(:time_entry,
               entity: work_package, project:, user:,
               hours: 20, spent_on: Date.new(2024, 3, 10))
      end

      it "includes only material costs within the date range" do
        expect(aggregated.spent_material).to eq(BigDecimal("1000"))
      end

      it "includes only labor costs within the date range" do
        expect(aggregated.spent_labor).to eq(BigDecimal("500"))
      end

      it "scopes has_spending? to the date range" do
        expect(aggregated.has_spending?).to be(true)
      end
    end

    context "with entries only outside the date range" do
      let!(:cost_entry_out_of_range) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 10, spent_on: Date.new(2024, 6, 15))
      end

      it "returns false for has_spending?" do
        expect(aggregated.has_spending?).to be(false)
      end

      it "returns 0 for spent_total" do
        expect(aggregated.spent_total).to eq(0)
      end
    end

    context "without a date_range (nil)" do
      subject(:aggregated) { described_class.new(project:, current_user: user) }

      let!(:cost_entry_2024) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 10, spent_on: Date.new(2024, 6, 15))
      end
      let!(:cost_entry_2025) do
        create(:cost_entry,
               entity: work_package, project:, user:, cost_type:,
               units: 10, spent_on: Date.new(2025, 6, 15))
      end

      it "includes all entries regardless of date" do
        expect(aggregated.spent_material).to eq(BigDecimal("2000"))
      end
    end
  end

  describe "#has_spending?" do
    context "with no entries" do
      it "returns false" do
        expect(aggregated.has_spending?).to be(false)
      end
    end

    context "with cost entries only" do
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

      it "returns true" do
        expect(aggregated.has_spending?).to be(true)
      end
    end

    context "with time entries only" do
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project:,
               user:,
               hours: 20,
               spent_on: Date.current)
      end

      it "returns true" do
        expect(aggregated.has_spending?).to be(true)
      end
    end

    context "with both cost and time entries" do
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
      let!(:time_entry) do
        create(:time_entry,
               entity: work_package,
               project:,
               user:,
               hours: 20,
               spent_on: Date.current)
      end

      it "returns true" do
        expect(aggregated.has_spending?).to be(true)
      end
    end
  end

  describe "portfolio project support" do
    let(:portfolio) do
      create(:portfolio).tap do |p|
        p.enabled_module_names += %w[costs]
        p.save!
      end
    end
    let(:child_project_one) do
      create(:project_with_types, parent: portfolio).tap do |p|
        p.enabled_module_names += %w[costs]
        p.save!
      end
    end
    let(:child_project_two) do
      create(:project_with_types, parent: portfolio).tap do |p|
        p.enabled_module_names += %w[costs]
        p.save!
      end
    end

    subject(:aggregated) { described_class.new(project: portfolio, current_user: user) }

    before do
      # Ensure child projects are loaded before creating memberships
      child_project_one
      child_project_two
      portfolio.reload

      # Create membership for user in portfolio project
      create(:member,
             project: portfolio,
             user:,
             roles: [create(:project_role,
                            permissions: %i[view_cost_entries
                                            view_cost_rates
                                            view_time_entries
                                            view_hourly_rates
                                            view_budgets])])
      # Create memberships for user in child projects
      create(:member,
             project: child_project_one,
             user:,
             roles: [create(:project_role,
                            permissions: %i[view_cost_entries
                                            view_cost_rates
                                            view_time_entries
                                            view_hourly_rates
                                            view_budgets])])
      create(:member,
             project: child_project_two,
             user:,
             roles: [create(:project_role,
                            permissions: %i[view_cost_entries
                                            view_cost_rates
                                            view_time_entries
                                            view_hourly_rates
                                            view_budgets])])
    end

    context "with spending in child projects" do
      let!(:budget1) { create(:budget, project: child_project_one) }
      let!(:budget2) { create(:budget, project: child_project_two) }
      let!(:wp1) { create(:work_package, project: child_project_one, budget: budget1) }
      let!(:wp2) { create(:work_package, project: child_project_two, budget: budget2) }
      let!(:cost_type) { create(:cost_type) }
      let!(:cost_rate) do
        create(:cost_rate,
               cost_type:,
               valid_from: Date.current - 1.day,
               rate: 100.0)
      end
      let!(:cost_entry1) do
        create(:cost_entry,
               entity: wp1,
               project: child_project_one,
               user:,
               cost_type:,
               units: 10,
               spent_on: Date.current)
      end
      let!(:cost_entry2) do
        create(:cost_entry,
               entity: wp2,
               project: child_project_two,
               user:,
               cost_type:,
               units: 15,
               spent_on: Date.current)
      end

      it "aggregates spending from all child projects" do
        expect(aggregated.spent_material).to eq(BigDecimal("2500"))
      end
    end
  end
end
