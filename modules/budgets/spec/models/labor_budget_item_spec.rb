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

RSpec.describe LaborBudgetItem do
  let(:item) { build(:labor_budget_item, budget:, principal:) }
  let(:budget) { build(:budget, project:) }
  let(:principal) { user }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:rate) do
    create(:hourly_rate, user:,
                         valid_from: Date.today - 4.days,
                         rate: 400.0,
                         project:)
  end
  let(:project) { create(:valid_project) }
  let(:project2) { create(:valid_project) }

  def is_member(project, user, permissions)
    create(:member,
           project:,
           user:,
           roles: [create(:project_role, permissions:)])
  end

  describe "#calculated_costs" do
    let(:default_costs) { "0.0".to_f }

    describe "WHEN no user is associated" do
      before do
        item.user = nil
      end

      it { expect(item.calculated_costs).to eq(default_costs) }
    end

    describe "WHEN no hours are defined" do
      before do
        item.hours = nil
      end

      it { expect(item.calculated_costs).to eq(default_costs) }
    end

    describe "WHEN user, hours and rate are defined" do
      before do
        project.save!
        item.hours = 5.0
        item.user = user
        rate.rate = 400.0
        rate.save!
      end

      it { expect(item.calculated_costs).to eq(rate.rate * item.hours) }
    end

    describe "WHEN user, hours and rate are defined " \
             "WHEN the user is deleted" do
      before do
        project.save!
        item.hours = 5.0
        item.user = user
        rate.rate = 400.0
        rate.save!

        user.destroy
      end

      it { expect(item.calculated_costs).to eq(rate.rate * item.hours) }
    end
  end

  describe "#user" do
    describe "WHEN an existing user is provided" do
      before do
        item.save!
        item.reload
        item.update(user_id: user.id)
        item.reload
      end

      it { expect(item.user).to eq(user) }
    end

    describe "WHEN a group is provided" do
      let(:principal) { group }
      let(:group) { create(:group) }

      before do
        item.save!
        item.reload
        item.update(user_id: group.id)
        item.reload
      end

      it { expect(item.principal).to eq(group) }
    end

    describe "WHEN a non existing user is provided (i.e. the user has been deleted)" do
      before do
        item.save!
        item.reload
        item.update(user_id: user.id)
        user.destroy
        item.reload
      end

      it { expect(item.user).to eq(DeletedUser.first) }
      it { expect(item.user_id).to eq(user.id) }
    end
  end

  describe "#valid?" do
    describe "WHEN hours, budget and user are provided" do
      it "is valid" do
        expect(item).to be_valid
      end
    end

    describe "WHEN no hours are provided" do
      before do
        item.hours = nil
      end

      it "is not valid" do
        expect(item).not_to be_valid
        expect(item.errors[:hours]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN hours are provided as nontransformable string" do
      before do
        item.hours = "test"
      end

      it "is not valid" do
        expect(item).not_to be_valid
        expect(item.errors[:hours]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN no budget is provided" do
      before do
        item.budget = nil
      end

      it "is not valid" do
        expect(item).not_to be_valid
        expect(item.errors[:budget]).to eq([I18n.t("activerecord.errors.messages.blank")])
      end
    end

    describe "WHEN no user is provided" do
      before do
        item.user = nil
      end

      it "is not valid" do
        expect(item).not_to be_valid
        expect(item.errors[:user]).to eq([I18n.t("activerecord.errors.messages.blank")])
      end
    end

    describe "WHEN the user is not a member of the budget project" do
      before do
        item # trigger build so after(:build) creates the membership first
        Member.where(project:, principal: user).destroy_all
      end

      it "is not valid" do
        expect(item).not_to be_valid
        expect(item.errors.where(:principal, :not_a_member_of_budget_project)).not_to be_empty
      end
    end

    describe "WHEN the budget has no project yet" do
      before do
        item.budget = build(:budget, project: nil)
      end

      it "skips the membership check and does not add a membership error" do
        item.valid?
        expect(item.errors.where(:principal, :not_a_member_of_budget_project)).to be_empty
      end
    end

    describe "WHEN a group is provided as principal" do
      let(:group) { create(:group) }

      before do
        create(:member, principal: group, project:, roles: [create(:project_role, permissions: %i[work_package_assigned])])
        item.principal = group
      end

      it "is valid when the group is a member of the budget project" do
        expect(item).to be_valid
      end

      context "when the group is not a member of the budget project" do
        before do
          Member.where(principal: group, project:).destroy_all
        end

        it "is not valid" do
          expect(item).not_to be_valid
          expect(item.errors.where(:principal, :not_a_member_of_budget_project)).not_to be_empty
        end
      end
    end
  end

  describe "#costs_visible_by?" do
    before do
      project.enabled_module_names = project.enabled_module_names << "costs"
    end

    describe "WHEN the item is assigned to the user " \
             "WHEN the user has the view_own_hourly_rate permission" do
      before do
        is_member(project, user, [:view_own_hourly_rate])

        item.user = user
      end

      it { expect(item.costs_visible_by?(user)).to be_truthy }
    end

    describe "WHEN the item is assigned to the user " \
             "WHEN the user lacks permissions" do
      before do
        is_member(project, user, [])

        item.user = user
      end

      it { expect(item.costs_visible_by?(user)).to be_falsey }
    end

    describe "WHEN the item is assigned to another user " \
             "WHEN the user has the view_hourly_rates permission" do
      before do
        is_member(project, user2, [:view_hourly_rates])

        item.user = user
      end

      it { expect(item.costs_visible_by?(user2)).to be_truthy }
    end

    describe "WHEN the item is assigned to another user " \
             "WHEN the user has the view_hourly_rates permission in another project" do
      before do
        is_member(project2, user2, [:view_hourly_rates])

        item.user = user
      end

      it { expect(item.costs_visible_by?(user2)).to be_falsey }
    end
  end
end
