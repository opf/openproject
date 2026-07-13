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

require_relative "../spec_helper"

RSpec.describe BudgetsController do
  describe "#destroy_info" do
    let(:project) { create(:project_with_types, enabled_module_names: %i[budgets work_package_tracking]) }
    let(:user) { create(:user, member_with_permissions: { project => %i[view_budgets edit_budgets] }) }
    let!(:budget) { create(:budget, project:, author: user) }

    before { login_as(user) }

    it "responds with 200" do
      get :destroy_info, params: { id: budget.id }
      expect(response).to have_http_status(:ok)
    end

    it "assigns @possible_other_budgets with other budgets in the project, excluding the current one" do
      other_budget = create(:budget, project:, author: user)
      other_project_budget = create(:budget, author: user)

      get :destroy_info, params: { id: budget.id }

      expect(assigns(:possible_other_budgets)).to include(other_budget)
      expect(assigns(:possible_other_budgets)).not_to include(budget)
      expect(assigns(:possible_other_budgets)).not_to include(other_project_budget)
    end
  end

  describe "#destroy" do
    let(:project) { create(:project_with_types, enabled_module_names: %i[budgets work_package_tracking]) }
    let(:user) { create(:user, member_with_permissions: { project => %i[view_budgets edit_budgets] }) }
    let!(:budget) { create(:budget, project:, author: user) }

    before { login_as(user) }

    context "when the budget has work packages and todo is not set" do
      let!(:work_package) { create(:work_package, project:, budget:) }

      it "redirects to destroy_info" do
        delete :destroy, params: { id: budget.id }
        expect(response).to redirect_to(destroy_info_budget_path(budget))
      end

      it "does not delete the budget" do
        expect { delete :destroy, params: { id: budget.id } }.not_to change(Budget, :count)
      end
    end

    context "when the budget has no work packages" do
      it "destroys the budget" do
        expect { delete :destroy, params: { id: budget.id } }.to change(Budget, :count).by(-1)
      end

      it "redirects to the budget index with a success notice" do
        delete :destroy, params: { id: budget.id }
        expect(flash[:notice]).to be_present
        expect(response).to have_http_status(:see_other)
      end
    end

    context "with work packages and todo=delete" do
      let!(:wp1) { create(:work_package, project:, budget:) }
      let!(:wp2) { create(:work_package, project:, budget:) }

      it "nullifies budget_id on all associated work packages and journals with the right cause" do
        delete :destroy, params: { id: budget.id, todo: "delete" }

        [wp1, wp2].each(&:reload)

        expect(wp1.budget_id).to be_nil
        expect(wp1.journals.last.cause["type"]).to eq("budget_deleted")

        expect(wp2.budget_id).to be_nil
        expect(wp2.journals.last.cause["type"]).to eq("budget_deleted")
      end

      it "destroys the budget" do
        expect { delete :destroy, params: { id: budget.id, todo: "delete" } }.to change(Budget, :count).by(-1)
        expect { budget.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with work packages and todo=reassign" do
      let!(:wp1) { create(:work_package, project:, budget:) }
      let!(:wp2) { create(:work_package, project:, budget:) }

      context "when the target budget is in the same project" do
        let!(:other_budget) { create(:budget, project:, author: user) }

        it "reassigns all work packages to the target budget and sets the correct cause" do
          delete :destroy, params: { id: budget.id, todo: "reassign", reassign_to_id: other_budget.id }

          [wp1, wp2].each(&:reload)

          expect(wp1.budget_id).to eq(other_budget.id)
          expect(wp1.journals.last.cause["type"]).to eq("budget_deleted")

          expect(wp2.budget_id).to eq(other_budget.id)
          expect(wp2.journals.last.cause["type"]).to eq("budget_deleted")
        end

        it "destroys the budget" do
          expect { delete :destroy, params: { id: budget.id, todo: "reassign", reassign_to_id: other_budget.id } }
            .to change(Budget, :count).by(-1)
          expect { budget.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the target budget is in a different project" do
        let(:other_project) do
          create(:project_with_types,
                 enabled_module_names: %i[budgets work_package_tracking],
                 member_with_permissions: { user => %i[view_budgets edit_budgets] })
        end
        let!(:other_budget) { create(:budget, project: other_project, author: user) }

        it "returns 404" do
          delete :destroy, params: { id: budget.id, todo: "reassign", reassign_to_id: other_budget.id }
          expect(response).to have_http_status(:not_found)
        end

        it "does not destroy the budget" do
          expect { delete :destroy, params: { id: budget.id, todo: "reassign", reassign_to_id: other_budget.id } }
            .not_to change(Budget, :count)
        end

        it "does not modify the work packages" do
          delete :destroy, params: { id: budget.id, todo: "reassign", reassign_to_id: other_budget.id }
          expect(wp1.reload.budget_id).to eq(budget.id)
          expect(wp2.reload.budget_id).to eq(budget.id)
        end
      end
    end
  end

  describe "#update_labor_budget_item" do
    let(:project) { create(:project) }
    let(:current_user) { create(:user, member_with_permissions: { project => [:view_hourly_rates] }) }
    let(:project_member) { create(:user, member_with_permissions: { project => [] }) }
    let(:non_member) { create(:user) }
    let(:element_id) { "labor_budget_item_1" }

    before { login_as(current_user) }

    context "when the referenced user is a project member" do
      let!(:hourly_rate) { create(:hourly_rate, user: project_member, project:, rate: 100.0, valid_from: Time.zone.today) }

      it "calculates costs based on the member's hourly rate" do
        get :update_labor_budget_item,
            format: :json,
            params: { project_id: project.id, user_id: project_member.id, hours: "2",
                      fixed_date: Time.zone.today.to_s, element_id: }

        json = response.parsed_body
        expect(json["#{element_id}_cost_value"]).to eq("200.00")
      end
    end

    context "when the referenced user is not a project member" do
      let!(:hourly_rate) { create(:hourly_rate, user: non_member, project:, rate: 100.0, valid_from: Time.zone.today) }

      it "returns zero costs" do
        get :update_labor_budget_item,
            format: :json,
            params: { project_id: project.id, user_id: non_member.id, hours: "2",
                      fixed_date: Time.zone.today.to_s, element_id: }

        json = response.parsed_body
        expect(json["#{element_id}_cost_value"]).to eq("0.00")
      end
    end
  end
end
