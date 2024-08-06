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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe Budget do
  let(:budget) { build(:budget, project:) }
  let(:type) { create(:type_feature) }
  let(:project) { create(:project_with_types) }
  let(:user) { create(:user) }

  describe "destroy" do
    let(:work_package) { create(:work_package, project:) }

    before do
      budget.author = user
      budget.work_packages = [work_package]
      budget.save!

      budget.destroy
    end

    it { expect(Budget.find_by_id(budget.id)).to be_nil }
    it { expect(WorkPackage.find_by_id(work_package.id)).to eq(work_package) }
    it { expect(work_package.reload.budget).to be_nil }
  end

  describe "#existing_material_budget_item_attributes=" do
    let!(:existing_material_budget_item) do
      create(:material_budget_item, budget:, units: 10.0)

      budget.material_budget_items.reload.first
    end

    context "allowed to edit budgets" do
      before do
        mock_permissions_for(User.current) do |mock|
          mock.allow_in_project :edit_budgets, project:
        end
      end

      context "with a non integer value" do
        it "updates the item" do
          budget.existing_material_budget_item_attributes = { existing_material_budget_item.id.to_s.to_sym => { units: "0.5" } }

          expect(existing_material_budget_item.units)
            .to be 0.5
        end
      end

      context "with no value" do
        it "deletes the item" do
          budget.existing_material_budget_item_attributes = { existing_material_budget_item.id.to_s.to_sym => {} }

          expect(existing_material_budget_item)
            .to be_destroyed
        end
      end
    end
  end
end
