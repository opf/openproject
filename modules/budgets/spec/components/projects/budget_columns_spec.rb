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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Projects::BudgetColumns do
  let(:project) do
    create(:project,
           enabled_module_names: %i[budgets work_package_tracking],
           members: { user => role })
  end
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_budgets]) }
  let(:table) { TableComponent.new }
  let(:component_class) do
    Class.new(Projects::RowComponent) do
      prepend Projects::BudgetColumns
    end
  end
  let(:component) { component_class.new(row: [project, 0], table: table) }

  before do
    login_as(user)
  end

  describe "columns" do
    describe "#budget_planned" do
      context "when user has permission and project has budgets" do
        let!(:budget) { create(:budget, project:, base_amount: 1500) }

        it "returns formatted currency" do
          allow(component).to receive(:number_to_currency).and_call_original
          expect(component.budget_planned).to include("1,500")
        end
      end

      context "when user lacks permission" do
        let(:role) { create(:project_role, permissions: []) }
        let!(:budget) { create(:budget, project:) }

        it "returns nil" do
          expect(component.budget_planned).to be_nil
        end
      end

      context "when project has no budgets" do
        it "returns nil" do
          expect(component.budget_planned).to be_nil
        end
      end
    end

    describe "#budget_spent" do
      context "when user has permission and project has budgets" do
        let!(:budget) { create(:budget, project:) }

        it "returns the spent amount formatted as currency" do
          expect(component.budget_spent).to eq(component.number_to_currency(budget.spent, precision: 0))
        end
      end

      context "when user lacks permission" do
        let(:role) { create(:project_role, permissions: []) }
        let!(:budget) { create(:budget, project:) }

        it "returns nil" do
          expect(component.budget_spent).to be_nil
        end
      end

      context "when project has no budgets" do
        it "returns nil" do
          expect(component.budget_spent).to be_nil
        end
      end
    end

    describe "#budget_spent_ratio" do
      context "when user has permission and project has budgets" do
        let!(:budget) { create(:budget, project:) }
        let(:helpers_mock) { instance_double(CostlogHelper) }

        before do
          allow(component).to receive(:helpers).and_return(helpers_mock)
        end

        it "returns extended progress bar with ratio" do
          allow(helpers_mock).to receive(:extended_progress_bar).and_return("<progress>0%</progress>")

          expect(component.budget_spent_ratio).to eq("<progress>0%</progress>")
          expect(helpers_mock).to have_received(:extended_progress_bar).with(0, legend: "0")
        end
      end

      context "when user lacks permission" do
        let(:role) { create(:project_role, permissions: []) }
        let!(:budget) { create(:budget, project:) }

        it "returns nil" do
          expect(component.budget_spent_ratio).to be_nil
        end
      end

      context "when project has no budgets" do
        it "returns nil" do
          expect(component.budget_spent_ratio).to be_nil
        end
      end
    end

    describe "#budget_available" do
      context "when user has permission and project has budgets" do
        let!(:budget) { create(:budget, project:, base_amount: 500) }

        it "returns formatted currency" do
          expect(component.budget_available).to include("500")
        end
      end

      context "when user lacks permission" do
        let(:role) { create(:project_role, permissions: []) }
        let!(:budget) { create(:budget, project:) }

        it "returns nil" do
          expect(component.budget_available).to be_nil
        end
      end

      context "when project has no budgets" do
        it "returns nil" do
          expect(component.budget_available).to be_nil
        end
      end
    end

    describe "#with_budget_aggregation" do
      context "when project has budgets and user has permission" do
        let!(:budget) { create(:budget, project:) }

        it "yields the budget aggregation" do
          expect { |b| component.with_budget_aggregation(&b) }.to yield_with_args(kind_of(Budgets::ProjectBudgetAggregation))
        end

        it "memoizes the budget aggregation" do
          first_aggregation = nil
          second_aggregation = nil

          component.with_budget_aggregation { |aggregation| first_aggregation = aggregation }
          component.with_budget_aggregation { |aggregation| second_aggregation = aggregation }

          expect(first_aggregation).to be(second_aggregation)
        end
      end

      context "when project has no budgets" do
        it "does not yield" do
          expect { |b| component.with_budget_aggregation(&b) }.not_to yield_control
        end
      end

      context "when user lacks view_budgets permission" do
        let(:role) { create(:project_role, permissions: []) }
        let!(:budget) { create(:budget, project:) }

        it "does not yield" do
          expect { |b| component.with_budget_aggregation(&b) }.not_to yield_control
        end
      end

      context "when current user is not set" do
        let!(:budget) { create(:budget, project:) }

        before do
          allow(User).to receive(:current).and_return(User.anonymous)
        end

        it "does not yield" do
          expect { |b| component.with_budget_aggregation(&b) }.not_to yield_control
        end
      end
    end
  end

  describe "permission checks" do
    context "when user has partial permissions" do
      let(:role) { create(:project_role, permissions: %i[view_budgets view_project]) }
      let!(:budget) { create(:budget, project:) }

      it "still allows budget viewing with view_budgets permission" do
        expect(component.budget_planned).not_to be_nil
      end
    end

    context "when project is archived" do
      let!(:budget) { create(:budget, project:) }

      before do
        project.update(active: false)
      end

      it "does not show budget information for archived projects when user lacks permission" do
        expect(component.budget_planned).to be_nil
      end
    end
  end
end
