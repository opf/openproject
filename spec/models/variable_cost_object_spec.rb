require File.dirname(__FILE__) + '/../spec_helper'

describe VariableCostObject do
  let(:cost_object) { FactoryGirl.build(:variable_cost_object) }
  let(:tracker) { FactoryGirl.create(:tracker_feature) }
  let(:project) { FactoryGirl.create(:project_with_trackers) }
  let(:user) { FactoryGirl.create(:user) }

  describe 'recreate initial journal' do
    before do
      User.stub!(:current).and_return(user)

      @variable_cost_object = FactoryGirl.create(:variable_cost_object , :project => project,
                                                                     :author => user)

      @initial_journal = @variable_cost_object.journals.first
      @recreated_journal = @variable_cost_object.recreate_initial_journal!
    end

    it { @initial_journal.should be_identical(@recreated_journal) }
  end

  describe "initialization" do
    let(:cost_object) { VariableCostObject.new }

    before do
      User.stub!(:current).and_return(user)
    end

    it { cost_object.author.should == user }
  end

  describe "destroy" do
    let(:work_package) { FactoryGirl.create(:work_package) }

    before do
      cost_object.author = user
      cost_object.work_packages = [work_package]
      cost_object.save!

      cost_object.destroy
    end

    it { VariableCostObject.find_by_id(cost_object.id).should be_nil }
    it { WorkPackage.find_by_id(work_package.id).should == work_package }
    it { work_package.reload.cost_object.should be_nil }
  end
end
