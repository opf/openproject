require File.dirname(__FILE__) + '/../spec_helper'

describe DefaultHourlyRate do
  let(:project) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user) }
  let(:rate) { FactoryGirl.build(:default_hourly_rate, :project => project,
                                                   :user => user) }

  describe :user do
    describe "WHEN an existing user is provided" do
      before do
        rate.user = user
        rate.save!
      end

      it { rate.user.should == user }
    end

    describe "WHEN a non existing user is provided (i.e. the user is deleted)" do
      before do
        rate.user = user
        rate.save!
        user.destroy
        rate.reload
      end

      it { rate.user.should == DeletedUser.first }
    end
  end
end
