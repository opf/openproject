require File.dirname(__FILE__) + '/../spec_helper'

describe VariableCostObject do
  before(:each) do
    @tracker ||= Factory.create(:tracker_feature)
    @project ||= Factory.create(:project_with_trackers)
    @current = Factory.create(:user, :login => "user1", :mail => "user1@users.com")

    User.stub!(:current).and_return(@current)
  end

  it 'should work with recreate initial journal' do
    @variable_cost_object ||= Factory.create(:variable_cost_object , :project => @project, :author => @current)

    initial_journal = @variable_cost_object.journals.first
    recreated_journal = @variable_cost_object.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end
end
