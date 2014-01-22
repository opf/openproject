#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe LaborBudgetItem do
  include Cost::PluginSpecHelper
  let(:item) { FactoryGirl.build(:labor_budget_item, :cost_object => cost_object) }
  let(:cost_object) { FactoryGirl.build(:variable_cost_object, :project => project) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:rate) { FactoryGirl.create(:hourly_rate, :user => user,
                                            :valid_from => Date.today - 4.days,
                                            :rate => 400.0,
                                            :project => project) }
  let(:project) { FactoryGirl.create(:valid_project) }
  let(:project2) { FactoryGirl.create(:valid_project) }

  describe :calculated_costs do
    let(:default_costs) { "0.0".to_f }

    describe "WHEN no user is associated" do
      before do
        item.user = nil
      end

      it { item.calculated_costs.should == default_costs }
    end

    describe "WHEN no hours are defined" do
      before do
        item.hours = nil
      end

      it { item.calculated_costs.should == default_costs }
    end

    describe "WHEN user, hours and rate are defined" do
      before do
        project.save!
        item.hours = 5.0
        item.user = user
        rate.rate = 400.0
        rate.save!
      end

      it { item.calculated_costs.should == (rate.rate * item.hours) }
    end

    describe "WHEN user, hours and rate are defined
              WHEN the user is deleted" do
      before do
        project.save!
        item.hours = 5.0
        item.user = user
        rate.rate = 400.0
        rate.save!

        user.destroy
      end

      it { item.calculated_costs.should == (rate.rate * item.hours) }
    end
  end

  describe :user do
    describe "WHEN an existing user is provided" do
      before do
        item.save!
        item.reload
        item.update_attribute(:user_id, user.id)
        item.reload
      end

      it { item.user.should == user }
    end

    describe "WHEN a non existing user is provided (i.e. the user has been deleted)" do
      before do
        item.save!
        item.reload
        item.update_attribute(:user_id, user.id)
        user.destroy
        item.reload
      end

      it { item.user.should == DeletedUser.first }
      it { item.user_id.should == user.id }
    end
  end

  describe :valid? do
    describe "WHEN hours, cost_object and user are provided" do
      it "should be valid" do
        item.should be_valid
      end
    end

    describe "WHEN no hours are provided" do
      before do
        item.hours = nil
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:hours].should == [I18n.t('activerecord.errors.messages.not_a_number')]
      end
    end

    describe "WHEN hours are provided as nontransformable string" do
      before do
        item.hours = "test"
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:hours].should == [I18n.t('activerecord.errors.messages.not_a_number')]
      end
    end

    describe "WHEN no cost_object is provided" do
      before do
        item.cost_object = nil
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:cost_object].should == [I18n.t('activerecord.errors.messages.blank')]
      end
    end

    describe "WHEN no user is provided" do
      before do
        item.user = nil
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:user].should == [I18n.t('activerecord.errors.messages.blank')]
      end
    end
  end

  describe :costs_visible_by? do
    before do
      project.enabled_module_names = project.enabled_module_names << "costs_module"
    end

    describe "WHEN the item is assigned to the user
              WHEN the user has the view_own_hourly_rate permission" do

      before do
        is_member(project, user, [:view_own_hourly_rate])

        item.user = user
      end

      it { item.costs_visible_by?(user).should be_true }
    end

    describe "WHEN the item is assigned to the user
              WHEN the user lacks permissions" do

      before do
        is_member(project, user, [])

        item.user = user
      end

      it { item.costs_visible_by?(user).should be_false }
    end

    describe "WHEN the item is assigned to another user
              WHEN the user has the view_hourly_rates permission" do

      before do
        is_member(project, user2, [:view_hourly_rates])

        item.user = user
      end

      it { item.costs_visible_by?(user2).should be_true }
    end

    describe "WHEN the item is assigned to another user
              WHEN the user has the view_hourly_rates permission in another project" do

      before do
        is_member(project2, user2, [:view_hourly_rates])

        item.user = user
      end

      it { item.costs_visible_by?(user2).should be_false }
    end
  end
end
