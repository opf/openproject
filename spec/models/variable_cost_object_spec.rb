require File.dirname(__FILE__) + '/../spec_helper'

describe VariableCostObject do
  let(:cost_object) { Factory.build(:variable_cost_object) }
  let(:tracker) { Factory.create(:tracker_feature) }
  let(:project) { Factory.create(:project_with_trackers) }
  let(:user) { Factory.create(:user) }

  describe 'recreate initial journal' do
    before do
      User.current = user

      @variable_cost_object = Factory.create(:variable_cost_object , :project => project,
                                                                     :author => user)

      @initial_journal = @variable_cost_object.journals.first
      @recreated_journal = @variable_cost_object.recreate_initial_journal!
    end

    it { @initial_journal.should be_identical(@recreated_journal) }
  end

  describe "initialization" do
    let(:cost_object) { VariableCostObject.new }

    before do
      User.current = user
    end

    it { cost_object.author.should == user }
  end

  describe "destroy" do
    let(:issue) { Factory.create(:valid_issue) }

    before do
      cost_object.author = user
      cost_object.issues = [issue]
      cost_object.save!

      cost_object.destroy
    end

    it { VariableCostObject.find_by_id(cost_object.id).should be_nil }
    it { Issue.find_by_id(issue.id).should == issue }
    it { issue.reload.cost_object.should be_nil }
  end
end
