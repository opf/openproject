require File.dirname(__FILE__) + '/../spec_helper'

describe LaborBudgetItem do
  let(:item) { Factory.build(:labor_budget_item, :cost_object => cost_object) }
  let(:cost_object) { Factory.build(:variable_cost_object, :project => project) }
  let(:user) { Factory.create(:user) }
  let(:rate) { Factory.create(:hourly_rate, :user => user,
                                            :valid_from => Date.today - 4.days,
                                            :rate => 400.0,
                                            :project => project) }
  let(:project) { Factory.create(:valid_project) }

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
        item.errors[:hours].should == I18n.t('activerecord.errors.messages.not_a_number')
      end
    end

    describe "WHEN hours are provided as nontransformable string" do
      before do
        item.hours = "test"
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:hours].should == I18n.t('activerecord.errors.messages.not_a_number')
      end
    end

    describe "WHEN no cost_object is provided" do
      before do
        item.cost_object = nil
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:cost_object].should == I18n.t('activerecord.errors.messages.blank')
      end
    end

    describe "WHEN no user is provided" do
      before do
        item.user = nil
      end

      it "should not be valid" do
        item.should_not be_valid
        item.errors[:user].should == I18n.t('activerecord.errors.messages.blank')
      end
    end
  end
end
