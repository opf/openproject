# -- copyright
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
# ++

require "#{File.dirname(__FILE__)}/../../../spec_helper"

RSpec.describe LaborBudgetItems::Scopes::Visible do
  shared_let(:view_project) { create(:project) }
  shared_let(:view_own_project) { create(:project) }
  shared_let(:other_user) { create(:user) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { view_project => %i[view_hourly_rates],
                                      view_own_project => %i[view_own_hourly_rate] })
  end
  shared_let(:view_budget) { create(:budget, project: view_project) }
  shared_let(:view_own_budget) { create(:budget, project: view_own_project) }
  shared_let(:own_budget_item_of_view_budget) { create(:labor_budget_item, budget: view_budget, user:) }
  shared_let(:budget_item_of_view_budget) { create(:labor_budget_item, budget: view_budget, user: other_user) }
  shared_let(:own_budget_item_of_view_own_budget) { create(:labor_budget_item, budget: view_own_budget, user:) }
  shared_let(:budget_item_of_view_own_budget) { create(:labor_budget_item, budget: view_own_budget, user: other_user) }

  describe ".visible" do
    it "returns all from project the user has view permission and only own from project the user has view own permission" do
      expect(LaborBudgetItem.visible(user))
        .to contain_exactly(own_budget_item_of_view_budget,
                            budget_item_of_view_budget,
                            own_budget_item_of_view_own_budget)
    end
  end
end
