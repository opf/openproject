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

RSpec.describe Budgets::AggregatedBudgets do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_budgets] })
  end

  subject(:aggregated) { described_class.new(project:, current_user: user) }

  describe "#budget_count" do
    context "with no budgets" do
      it "returns 0" do
        expect(aggregated.budget_count).to eq(0)
      end
    end

    context "with visible budgets" do
      let!(:budget1) { create(:budget, project:) }
      let!(:budget2) { create(:budget, project:) }

      it "counts all visible budgets" do
        expect(aggregated.budget_count).to eq(2)
      end
    end

    context "without view_budgets permission" do
      let(:user_without_permissions) { create(:user) }
      let(:aggregated_for_restricted_user) { described_class.new(project:, current_user: user_without_permissions) }
      let!(:budget) { create(:budget, project:) }

      it "returns 0" do
        expect(aggregated_for_restricted_user.budget_count).to eq(0)
      end
    end

    context "with budgets in other projects" do
      let!(:other_project) { create(:project_with_types) }
      let!(:budget_in_project) { create(:budget, project:) }
      let!(:budget_in_other_project) { create(:budget, project: other_project) }

      it "counts only budgets in the specified project" do
        expect(aggregated.budget_count).to eq(1)
      end
    end
  end

  describe "#budgeted_total" do
    context "with no budgets" do
      it "returns 0" do
        expect(aggregated.budgeted_total).to eq(0)
      end
    end

    context "with base_amount only" do
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }

      it "returns the base amount" do
        expect(aggregated.budgeted_total).to eq(BigDecimal("10000"))
      end
    end

    context "with all components" do
      let(:user_with_rates) do
        create(:user,
               member_with_permissions: { project => %i[view_budgets view_cost_rates view_hourly_rates work_package_assigned] })
      end
      let(:aggregated) { described_class.new(project:, current_user: user_with_rates) }
      let!(:cost_type) { create(:cost_type) }
      let!(:budget) { create(:budget, project:, base_amount: BigDecimal("10000")) }
      let!(:labor_item) do
        create(:labor_budget_item,
               budget:,
               user: user_with_rates,
               hours: 100,
               amount: BigDecimal("5000"))
      end
      let!(:material_item) do
        create(:material_budget_item,
               budget:,
               cost_type:,
               units: 50,
               amount: BigDecimal("3000"))
      end

      it "sums base_amount, labor, and material amounts" do
        expect(aggregated.budgeted_total).to eq(BigDecimal("18000"))
      end
    end
  end

  describe "subproject aggregation for regular projects" do
    let(:child_project) do
      create(:project_with_types, parent: project).tap do |p|
        p.enabled_module_names += %w[budgets]
        p.save!
      end
    end

    before do
      child_project
      project.reload
      create(:member, project: child_project, user:,
                      roles: [create(:project_role, permissions: %i[view_budgets])])
    end

    context "with a budget in the child project" do
      let!(:budget) { create(:budget, project: child_project, base_amount: BigDecimal("4000")) }

      it "includes child project budgets in budget_count" do
        expect(aggregated.budget_count).to eq(1)
      end

      it "includes child project base amounts in budgeted_base" do
        expect(aggregated.budgeted_base).to eq(BigDecimal("4000"))
      end
    end

    context "with budgets in both parent and child project" do
      let!(:parent_budget) { create(:budget, project:, base_amount: BigDecimal("2000")) }
      let!(:child_budget) { create(:budget, project: child_project, base_amount: BigDecimal("4000")) }

      it "aggregates budget counts from parent and child" do
        expect(aggregated.budget_count).to eq(2)
      end

      it "aggregates base amounts from parent and child" do
        expect(aggregated.budgeted_base).to eq(BigDecimal("6000"))
      end
    end
  end

  describe "portfolio project support" do
    let(:portfolio) do
      create(:portfolio).tap do |p|
        p.enabled_module_names += %w[budgets]
        p.save!
      end
    end
    let(:child_project_one) do
      create(:project_with_types, parent: portfolio).tap do |p|
        p.enabled_module_names += %w[budgets]
        p.save!
      end
    end
    let(:child_project_two) do
      create(:project_with_types, parent: portfolio).tap do |p|
        p.enabled_module_names += %w[budgets]
        p.save!
      end
    end

    subject(:aggregated) { described_class.new(project: portfolio, current_user: user) }

    before do
      # Ensure child projects are loaded before creating memberships
      child_project_one
      child_project_two
      portfolio.reload

      # Create membership for user in portfolio and child projects
      [portfolio, child_project_one, child_project_two].each do |p|
        create(:member, project: p, user:,
                        roles: [create(:project_role, permissions: %i[view_budgets])])
      end
    end

    context "with budgets in child projects" do
      let!(:budget1) { create(:budget, project: child_project_one, base_amount: BigDecimal("5000")) }
      let!(:budget2) { create(:budget, project: child_project_two, base_amount: BigDecimal("3000")) }

      it "aggregates budget count from all child projects" do
        expect(aggregated.budget_count).to eq(2)
      end

      it "aggregates base amounts from all child projects" do
        expect(aggregated.budgeted_base).to eq(BigDecimal("8000"))
      end
    end
  end
end
