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

require_relative "../../spec_helper"

RSpec.describe "adding a new budget", :js do
  let(:project) { create(:project_with_types, members: project_members) }
  let(:user) { create(:admin) }
  let(:project_members) { {} }

  before do
    login_as user
  end

  it "shows link to create a new budget" do
    visit projects_budgets_path(project)

    page.find("[aria-label='Add budget']").click

    expect(page).to have_content "New budget"
    expect(page).to have_content "Description"
    expect(page).to have_content "Subject"
  end

  describe "with multiple cost types" do
    let!(:cost_type_1) do
      create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps")
    end

    let!(:cost_type_2) do
      create(:cost_type, name: "Foobar", unit: "bar", unit_plural: "bars")
    end

    it "can switch between them" do
      visit projects_budgets_path(project)

      page.find("[aria-label='Add budget']").click
      expect(page).to have_content "New budget"

      fill_in "Subject", with: "My subject"
      fill_in "budget_new_material_budget_item_attributes_0_units", with: 15

      # change cost type
      select "Foobar", from: "budget_new_material_budget_item_attributes_0_cost_type_id"

      expect(page).to have_content "bars"

      click_on "Create"

      expect(page).to have_content "Successful creation"
      expect(page).to have_content "My subject"

      expect(page).to have_css(".material_budget_items td.units", text: "15.00")
      expect(page).to have_css(".material_budget_items td", text: "Foobar")
    end

    context "and a project-scoped cost type not mapped to this project" do
      let!(:scoped_mapped) do
        create(:cost_type, name: "Mapped", unit: "x", unit_plural: "xs", for_all_projects: false).tap do |ct|
          CostTypesProject.create!(cost_type: ct, project: project)
        end
      end
      let!(:scoped_unmapped) do
        create(:cost_type, name: "Hidden", unit: "y", unit_plural: "ys", for_all_projects: false)
      end

      it "omits the unmapped cost type from the dropdown" do
        visit new_projects_budget_path(project)

        select_id = "budget_new_material_budget_item_attributes_0_cost_type_id"
        within("##{select_id}") do
          expect(page).to have_css("option", text: "Post-war")
          expect(page).to have_css("option", text: "Foobar")
          expect(page).to have_css("option", text: "Mapped")
          expect(page).to have_no_css("option", text: "Hidden")
        end
      end
    end
  end

  it "create the budget" do
    visit new_projects_budget_path(project)

    fill_in("Subject", with: "My subject")

    click_on "Create"

    expect(page).to have_content "Successful creation"
    expect(page).to have_content "My subject"
  end

  context "with cost items" do
    let(:cost_type) do
      create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps")
    end

    let(:new_budget_page) { Pages::NewBudget.new project.identifier }
    let(:budget_page) { Pages::EditBudget.new Budget.last }

    let(:project_members) { { user => create(:project_role, permissions: %i[work_package_assigned]) } }

    before do
      create(:cost_rate, cost_type:, rate: 50.0, valid_from: 1.year.ago)
      create(:default_hourly_rate, user:, rate: 25.0, valid_from: 1.year.ago)
    end

    context "with german locale" do
      around do |example|
        I18n.with_locale(:de, &example)
      end

      let(:user) { create(:admin, language: :de) }

      it "creates the budget including the given cost items with german locale" do
        new_budget_page.visit!

        fill_in Budget.human_attribute_name(:subject), with: "First Aid"

        new_budget_page.add_unit_costs! "3,50", comment: "RadAway", expected_costs: "175,00 €"
        new_budget_page.add_unit_costs! "1.000,50", comment: "Rad-X", expected_costs: "50.025,00 €"

        new_budget_page.add_labor_costs! "5000,10", user_name: user.name, comment: "treatment", expected_costs: "125.002,50 €"
        new_budget_page.add_labor_costs! "0,5", user_name: user.name, comment: "attendance", expected_costs: "12,50 €"

        page.find('[data-test-selector="budgets-create-button"]').click
        expect_and_dismiss_flash(message: I18n.t(:notice_successful_create))

        expect(new_budget_page.unit_costs_at(1)).to have_content "175,00 €"
        expect(new_budget_page.unit_costs_at(2)).to have_content "50.025,00 €"
        expect(new_budget_page.overall_unit_costs).to have_content "50.200,00 €"

        expect(new_budget_page.labor_costs_at(1)).to have_content "125.002,50 €"
        expect(new_budget_page.labor_costs_at(2)).to have_content "12,50 €"
        expect(new_budget_page.overall_labor_costs).to have_content "125.015,00 €"

        click_on I18n.t(:button_update)

        budget_page.expect_planned_costs! type: :material, row: 1, expected: "175,00 €"
        budget_page.expect_planned_costs! type: :material, row: 2, expected: "50.025,00 €"
        budget_page.expect_planned_costs! type: :labor, row: 1, expected: "125.002,50 €"
        budget_page.expect_planned_costs! type: :labor, row: 2, expected: "12,50 €"

        fields = page
          .all("input.budget-item-value")
          .select { |node| node.value.present? }
          .map(&:value)

        expect(fields).to contain_exactly "3,50", "1.000,50", "5.000,10", "0,50"
      end
    end

    it "creates the budget including the given cost items" do
      new_budget_page.visit!

      fill_in "Subject", with: "First Aid"

      new_budget_page.add_unit_costs! 3, comment: "RadAway"
      new_budget_page.add_unit_costs! 2, comment: "Rad-X"

      new_budget_page.add_labor_costs! 5, user_name: user.name, comment: "treatment"
      new_budget_page.add_labor_costs! 2, user_name: user.name, comment: "attendance"

      click_on "Create"
      expect(page).to have_content("Successful creation")

      expect(page).to have_css("td.currency", text: "150.00 €")
      expect(new_budget_page.unit_costs_at(1)).to have_content "150.00 €"
      expect(new_budget_page.unit_costs_at(2)).to have_content "100.00 €"
      expect(new_budget_page.overall_unit_costs).to have_content "250.00 €"

      expect(page).to have_css("td.currency", text: "125.00 €")
      expect(new_budget_page.labor_costs_at(1)).to have_content "125.00 €"
      expect(new_budget_page.labor_costs_at(2)).to have_content "50.00 €"
      expect(new_budget_page.overall_labor_costs).to have_content "175.00 €"
    end
  end
end
