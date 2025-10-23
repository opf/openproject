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

require_relative "../spec_helper"

RSpec.describe Budget do
  let(:budget) { build(:budget, project:) }
  let(:type) { create(:type_feature) }
  let(:project) { create(:project_with_types) }
  let(:user) { create(:user) }

  describe "#labor_budget_items" do
    it "eager-loads the principal for users and placeholder users alike" do
      budget.save!
      create(:labor_budget_item, budget:, principal: user, hours: 1)
      create(:labor_budget_item, budget:, principal: create(:placeholder_user), hours: 2)

      principals = budget.reload.labor_budget_items.map(&:principal)

      expect(principals.map(&:class)).to contain_exactly(User, PlaceholderUser)
    end
  end

  describe "destroy" do
    let(:work_package) { create(:work_package, project:) }

    before do
      budget.author = user
      budget.work_packages = [work_package]
      budget.save!

      budget.destroy
    end

    it { expect(described_class.find_by(id: budget.id)).to be_nil }
    it { expect(WorkPackage.find_by(id: work_package.id)).to eq(work_package) }
    it { expect(work_package.reload.budget).to be_nil }
  end

  describe "#base_amount=" do
    it "sets the base amount to 0.0 when an empty string is passed" do
      budget.base_amount = ""
      expect(budget.base_amount).to eq(0.0)
    end

    it "sets the base amount to 0.0 when nil is passed" do
      budget.base_amount = nil
      expect(budget.base_amount).to eq(0.0)
    end

    it "sets the base amount to the given float value" do
      budget.base_amount = "12.34"
      expect(budget.base_amount).to eq(12.34)
    end

    it "parses the base amount according to the current locale" do
      I18n.with_locale(:de) do
        budget.base_amount = "12,34"
        expect(budget.base_amount).to eq(12.34)
      end
    end
  end

  describe "#new_labor_budget_item_attributes=", with_settings: { hours_per_day: 8, days_per_month: 20 } do
    def build_item(hours)
      budget.new_labor_budget_item_attributes = { "0": { hours:, user_id: user.id } }
      budget.labor_budget_items.last
    end

    it "parses a plain decimal value" do
      expect(build_item("10.5").hours).to eq(10.5)
    end

    it "parses a value given in hours" do
      expect(build_item("8h").hours).to eq(8)
    end

    it "resolves days through the hours per day setting" do
      expect(build_item("1d").hours).to eq(8)
      expect(build_item("2d 10h").hours).to eq(26)
    end

    it "parses the value according to the current locale" do
      I18n.with_locale(:de) do
        expect(build_item("10,5").hours).to eq(10.5)
      end
    end

    it "does not build an item for unparseable input" do
      build_item("garbage")

      expect(budget.labor_budget_items).to be_empty
    end
  end

  describe "#new_labor_budget_item_attributes= for a copied item" do
    let(:source_project) { project }
    let(:source) do
      create(:labor_budget_item, budget: create(:budget, project: source_project), user:, hours: 2, amount: 999.0)
    end

    def build_item(**attributes)
      budget.new_labor_budget_item_attributes = { "0": { hours: "2", user_id: user.id, copied_from_id: source.id, **attributes } }
      budget.labor_budget_items.last
    end

    it "takes the override from the source item when no amount is given" do
      expect(build_item.amount).to eq 999.0
    end

    it "uses a given amount" do
      expect(build_item(amount: "5").amount).to eq 5
    end

    it "clears the override for a blank amount" do
      expect(build_item(amount: "").amount).to be_nil
    end

    it "ignores a source item given to another user" do
      expect(build_item(user_id: create(:user).id).amount).to be_nil
    end

    context "with the source item in another project" do
      let(:source_project) { create(:project) }

      it "ignores the source item" do
        expect(build_item.amount).to be_nil
      end
    end
  end

  describe "#new_material_budget_item_attributes= for a copied item" do
    let(:source_project) { project }
    let(:source) do
      create(:material_budget_item, budget: create(:budget, project: source_project), units: 2, amount: 600.0)
    end

    def build_item(**attributes)
      budget.new_material_budget_item_attributes = { "0": { units: "2", copied_from_id: source.id, **attributes } }
      budget.material_budget_items.last
    end

    it "takes the override from the source item when no amount is given" do
      expect(build_item.amount).to eq 600.0
    end

    it "clears the override for a blank amount" do
      expect(build_item(amount: "").amount).to be_nil
    end

    context "with the source item in another project" do
      let(:source_project) { create(:project) }

      it "ignores the source item" do
        expect(build_item.amount).to be_nil
      end
    end
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

  describe "#existing_labor_budget_item_attributes=" do
    let!(:existing_labor_budget_item) do
      create(:labor_budget_item, budget:, principal: user, hours: 2.0, amount: 250)

      budget.labor_budget_items.reload.first
    end
    let(:item_attributes) { { hours: "2", user_id: user.id } }

    def assign(attributes)
      budget.existing_labor_budget_item_attributes = { existing_labor_budget_item.id.to_s.to_sym => attributes }
    end

    before do
      mock_permissions_for(User.current) do |mock|
        mock.allow_in_project :edit_budgets, project:
      end
    end

    it "leaves the amount untouched when no amount is sent" do
      assign(item_attributes)

      expect(existing_labor_budget_item.amount).to eq 250
    end

    it "clears the amount when a blank amount is sent" do
      assign(item_attributes.merge(amount: ""))

      expect(existing_labor_budget_item.amount).to be_nil
    end

    it "sets the amount when a number is sent" do
      assign(item_attributes.merge(amount: "300"))

      expect(existing_labor_budget_item.amount).to eq 300
    end
  end

  describe "#existing_material_budget_item_attributes= with an overridden amount" do
    let!(:existing_material_budget_item) do
      create(:material_budget_item, budget:, units: 10.0, amount: 250)

      budget.material_budget_items.reload.first
    end
    let(:item_attributes) { { units: "10", cost_type_id: existing_material_budget_item.cost_type_id } }

    def assign(attributes)
      budget.existing_material_budget_item_attributes = { existing_material_budget_item.id.to_s.to_sym => attributes }
    end

    before do
      mock_permissions_for(User.current) do |mock|
        mock.allow_in_project :edit_budgets, project:
      end
    end

    it "leaves the amount untouched when no amount is sent" do
      assign(item_attributes)

      expect(existing_material_budget_item.amount).to eq 250
    end

    it "clears the amount when a blank amount is sent" do
      assign(item_attributes.merge(amount: ""))

      expect(existing_material_budget_item.amount).to be_nil
    end

    it "sets the amount when a number is sent" do
      assign(item_attributes.merge(amount: "300"))

      expect(existing_material_budget_item.amount).to eq 300
    end
  end
end
