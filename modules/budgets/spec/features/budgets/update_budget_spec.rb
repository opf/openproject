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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

RSpec.describe "updating a budget", :js do
  let(:project) do
    create(:project_with_types,
           enabled_module_names: %i[budgets costs work_package_tracking],
           members: { user => create(:project_role, permissions: %i[work_package_assigned]) })
  end
  let(:user) { create(:admin) }
  let(:budget) { create(:budget, author: user, project:) }

  current_user { user }

  describe "with new cost items", :with_cuprite do
    let(:cost_type) do
      create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps")
    end

    let(:budget_page) { Pages::EditBudget.new budget.id }

    before do
      create(:cost_rate, cost_type:, rate: 50.0, valid_from: 1.day.ago)
      create(:default_hourly_rate, user:, rate: 25.0, valid_from: 1.day.ago)
    end

    it "creates the cost items" do
      budget_page.visit!
      click_on "Update"

      budget_page.add_unit_costs! 3, comment: "Stimpak", expected_costs: "150.00 EUR"
      budget_page.add_labor_costs! 5, user_name: user.name, comment: "treatment", expected_costs: "125.00 EUR"

      click_on "Submit"
      expect(budget_page).to have_content("Successful update")

      expect(page).to have_css("tbody td.currency", text: "150.00 EUR")
      expect(budget_page.overall_unit_costs).to have_content "150.00 EUR"

      expect(page).to have_css("tbody td.currency", text: "125.00 EUR")
      expect(budget_page.labor_costs_at(1)).to have_content "125.00 EUR"
      expect(budget_page.overall_labor_costs).to have_content "125.00 EUR"
    end
  end

  describe "with existing cost items" do
    let(:cost_type) do
      create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps")
    end

    let(:material_budget_item) do
      create(:material_budget_item,
             units: 3,
             cost_type:,
             budget:)
    end

    let(:labor_budget_item) do
      create(:labor_budget_item,
             hours: 5,
             user:,
             budget:)
    end

    let(:budget_page) { Pages::EditBudget.new budget.id }

    before do
      create(:cost_rate, cost_type:, rate: 50.0)
      create(:default_hourly_rate, user:, rate: 25.0)

      # trigger creation
      material_budget_item
      labor_budget_item
    end

    it "updates the cost items" do
      budget_page.visit!
      click_on "Update"

      budget_page.expect_planned_costs! type: :material, row: 1, expected: "150.00 EUR"
      budget_page.expect_planned_costs! type: :labor, row: 1, expected: "125.00 EUR"

      budget_page.edit_unit_costs! material_budget_item.id,
                                   units: 5,
                                   comment: "updated num stimpaks"
      budget_page.edit_labor_costs! labor_budget_item.id,
                                    hours: 3,
                                    user_name: user.name,
                                    comment: "updated treatment duration"

      # Test for updated planned costs (Regression #31247)
      budget_page.expect_planned_costs! type: :material, row: 1, expected: "250.00 EUR"
      budget_page.expect_planned_costs! type: :labor, row: 1, expected: "75.00 EUR"

      click_on "Submit"
      expect(budget_page).to have_content("Successful update")

      expect(page).to have_css("tbody td.currency", text: "250.00 EUR")
      expect(budget_page.unit_costs_at(1)).to have_content "250.00 EUR"
      expect(budget_page.overall_unit_costs).to have_content "250.00 EUR"

      expect(page).to have_css("tbody td.currency", text: "75.00 EUR")
      expect(budget_page.labor_costs_at(1)).to have_content "75.00 EUR"
      expect(budget_page.overall_labor_costs).to have_content "75.00 EUR"
    end

    context "with german locale" do
      let(:user) { create(:admin, language: :de) }
      let(:cost_type2) do
        create(:cost_type, name: "ABC", unit: "abc", unit_plural: "abcs")
      end

      let(:material_budget_item2) do
        create(:material_budget_item,
               units: 3,
               cost_type: cost_type2,
               budget:,
               amount: 1000.0)
      end

      it "retains the overridden budget when opening, but not editing (Regression #32822)" do
        material_budget_item2
        budget_page.visit!
        click_on I18n.t(:button_update, locale: :de)

        budget_page.expect_planned_costs! type: :material, row: 1, expected: "150,00 EUR"
        budget_page.expect_planned_costs! type: :material, row: 2, expected: "1.000,00 EUR"
        budget_page.expect_planned_costs! type: :labor, row: 1, expected: "125,00 EUR"

        # Open first item
        budget_page.open_edit_planned_costs! material_budget_item.id, type: :material
        expect(page).to have_field("budget_existing_material_budget_item_attributes_#{material_budget_item.id}_amount")

        click_on "OK"
        expect(budget_page).to have_content(I18n.t(:notice_successful_update, locale: :de))

        expect(page).to have_css("tbody td.currency", text: "150,00 EUR")
        expect(page).to have_css("tbody td.currency", text: "1.000,00 EUR")
        expect(page).to have_css("tbody td.currency", text: "125,00 EUR")
      end
    end

    context "with two material budget items" do
      let!(:material_budget_item_2) do
        create(:material_budget_item,
               units: 5,
               cost_type:,
               budget:)
      end

      it "keeps previous planned material costs (Regression test #27692)" do
        budget_page.visit!
        click_on "Update"

        # Update first element
        budget_page.edit_planned_costs! material_budget_item.id, type: :material, costs: 123
        expect(budget_page).to have_content("Successful update")
        expect(page).to have_css("tbody td.currency", text: "123.00 EUR")

        click_on "Update"

        # Update second element
        budget_page.edit_planned_costs! material_budget_item_2.id, type: :material, costs: 543
        expect(budget_page).to have_content("Successful update")
        expect(page).to have_css("tbody td.currency", text: "123.00 EUR")
        expect(page).to have_css("tbody td.currency", text: "543.00 EUR")

        # Expect overridden costs on both
        material_budget_item.reload
        material_budget_item_2.reload

        # Expect budget == costs
        expect(material_budget_item.amount).to eq(123.0)
        expect(material_budget_item.overridden_costs?).to be_truthy
        expect(material_budget_item.costs).to eq(123.0)
        expect(material_budget_item_2.amount).to eq(543.0)
        expect(material_budget_item_2.overridden_costs?).to be_truthy
        expect(material_budget_item_2.costs).to eq(543.0)
      end

      context "with a reversed currency format" do
        before do
          allow(Setting)
            .to receive(:plugin_costs)
            .and_return({ costs_currency_format: "%u %n", costs_currency: "USD" }.with_indifferent_access)
        end

        it "can still update budgets (Regression test #32664)" do
          budget_page.visit!
          click_on "Update"

          # Update first element
          budget_page.edit_planned_costs! material_budget_item.id, type: :material, costs: 123
          expect(budget_page).to have_content("Successful update")
          expect(page).to have_css("tbody td.currency", text: "USD 123.00")

          click_on "Update"

          # Update second element
          budget_page.edit_planned_costs! material_budget_item_2.id, type: :material, costs: 543
          expect(budget_page).to have_content("Successful update")
          expect(page).to have_css("tbody td.currency", text: "USD 123.00")
          expect(page).to have_css("tbody td.currency", text: "USD 543.00")

          # Expect overridden costs on both
          material_budget_item.reload
          material_budget_item_2.reload

          # Expect budget == costs
          expect(material_budget_item.amount).to eq(123.0)
          expect(material_budget_item.overridden_costs?).to be_truthy
          expect(material_budget_item.costs).to eq(123.0)
          expect(material_budget_item_2.amount).to eq(543.0)
          expect(material_budget_item_2.overridden_costs?).to be_truthy
          expect(material_budget_item_2.costs).to eq(543.0)
        end
      end
    end

    context "with two labor budget items" do
      let!(:labor_budget_item_2) do
        create(:labor_budget_item,
               hours: 5,
               user:,
               budget:)
      end

      it "keeps previous planned labor costs (Regression test #27692)" do
        budget_page.visit!
        click_on "Update"

        # Update first element
        budget_page.edit_planned_costs! labor_budget_item.id, type: :labor, costs: 456
        expect(budget_page).to have_content("Successful update")
        expect(page).to have_css("tbody td.currency", text: "456.00 EUR")

        click_on "Update"

        # Update second element
        budget_page.edit_planned_costs! labor_budget_item_2.id, type: :labor, costs: 987
        expect(budget_page).to have_content("Successful update")
        expect(page).to have_css("tbody td.currency", text: "456.00 EUR")
        expect(page).to have_css("tbody td.currency", text: "987.00 EUR")

        # Expect overridden costs on both
        labor_budget_item.reload
        labor_budget_item_2.reload

        # Expect budget == costs
        expect(labor_budget_item.amount).to eq(456.0)
        expect(labor_budget_item.overridden_costs?).to be_truthy
        expect(labor_budget_item.costs).to eq(456.0)
        expect(labor_budget_item_2.amount).to eq(987.0)
        expect(labor_budget_item_2.overridden_costs?).to be_truthy
        expect(labor_budget_item_2.costs).to eq(987.0)
      end

      context "with a reversed currency format" do
        before do
          allow(Setting)
            .to receive(:plugin_costs)
            .and_return({ costs_currency_format: "%u %n", costs_currency: "USD" }.with_indifferent_access)
        end

        it "can still update budgets (Regression test #32664)" do
          budget_page.visit!
          click_on "Update"

          # Update first element
          budget_page.edit_planned_costs! labor_budget_item.id, type: :labor, costs: 456
          expect(budget_page).to have_content("Successful update")
          expect(page).to have_css("tbody td.currency", text: "USD 456.00")

          click_on "Update"

          # Update second element
          budget_page.edit_planned_costs! labor_budget_item_2.id, type: :labor, costs: 987
          expect(budget_page).to have_content("Successful update")
          expect(page).to have_css("tbody td.currency", text: "USD 456.00")
          expect(page).to have_css("tbody td.currency", text: "USD 987.00")

          # Expect overridden costs on both
          labor_budget_item.reload
          labor_budget_item_2.reload

          # Expect budget == costs
          expect(labor_budget_item.amount).to eq(456.0)
          expect(labor_budget_item.overridden_costs?).to be_truthy
          expect(labor_budget_item.costs).to eq(456.0)
          expect(labor_budget_item_2.amount).to eq(987.0)
          expect(labor_budget_item_2.overridden_costs?).to be_truthy
          expect(labor_budget_item_2.costs).to eq(987.0)
        end
      end
    end

    it "removes existing cost items" do
      budget_page.visit!

      click_on "Update"

      page.find("#budget_existing_labor_budget_item_attributes_#{labor_budget_item.id} a.delete-budget-item").click
      click_on "Submit"

      expect(budget_page.labor_costs_at(1)).to have_no_content "125.00 EUR"
    end
  end
end
