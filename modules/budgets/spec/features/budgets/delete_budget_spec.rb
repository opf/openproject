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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper.rb")

RSpec.describe "Deleting a budget", :js do
  let(:project) { create(:project, enabled_module_names: %i[budgets costs]) }
  let(:user) { create(:admin) }
  let(:budget_subject) { "A budget subject" }
  let(:budget_description) { "A budget description" }
  let!(:budget) do
    create(:budget,
           subject: budget_subject,
           description: budget_description,
           author: user,
           project:)
  end

  let(:budget_page) { Pages::EditBudget.new budget.id }
  let(:budget_index_page) { Pages::IndexBudget.new project }

  before do
    login_as(user)
    budget_page.visit!
  end

  context "when no WP are assigned to this budget" do
    it "simply deletes the budget without additional checks" do
      # Delete the budget
      budget_page.click_delete

      # Get directly back to index page and the budget is deleted
      budget_index_page.expect_budget_not_listed budget_subject
    end
  end

  context "when WPs are assigned to this budget" do
    let(:wp1) { create(:work_package, project:, budget:) }
    let(:wp2) { create(:work_package, project:, budget:) }
    let(:budget_destroy_info_page) { Pages::DestroyInfo.new budget }

    before do
      wp1
      wp2
    end

    context "with no other budget to assign to" do
      before do
        # When deleting with WPs assigned we get to the destroy_info page
        budget_page.click_delete
        budget_destroy_info_page.expect_loaded

        # In any case the delete option is shown
        budget_destroy_info_page.expect_delete_option
      end

      it "deletes the budget from the WPs" do
        # Select to delete the budget from the WPs
        budget_destroy_info_page.expect_no_reassign_option
        budget_destroy_info_page.select_delete_option

        # Delete the budget
        budget_destroy_info_page.delete

        # Get back to index page and the budget is deleted
        budget_index_page.expect_budget_not_listed budget_subject

        # Both WPs are updated correctly
        wp1.reload
        wp2.reload
        expect(wp1.budget).to be_nil
        expect(wp2.budget).to be_nil
      end
    end

    context "with another budget to assign to" do
      let(:budget2) do
        create(:budget,
               subject: "Another budget",
               description: budget_description,
               author: user,
               project:)
      end

      before do
        budget2

        # When deleting with WPs assigned we get to the destroy_info page
        budget_page.click_delete
        budget_destroy_info_page.expect_loaded

        # In any case the delete option is shown
        budget_destroy_info_page.expect_delete_option
      end

      it "reassigns the WP to another budget" do
        # Select reassign
        budget_destroy_info_page.expect_reassign_option
        budget_destroy_info_page.select_reassign_option budget2.subject

        # Delete the budget
        budget_destroy_info_page.delete

        # Get back to index page and the budget is deleted
        budget_index_page.expect_budget_not_listed budget_subject

        # Both WPs are updated correctly
        wp1.reload
        wp2.reload
        expect(wp1.budget.id).to eq budget2.id
        expect(wp2.budget.id).to eq budget2.id
      end
    end
  end
end
