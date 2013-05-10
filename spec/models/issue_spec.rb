require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Issue do
  let(:user) { FactoryGirl.create(:admin)}
  let(:role) { FactoryGirl.create(:role) }
  let(:project) do
      project = FactoryGirl.create(:project_with_trackers)
      project.add_member!(user, role)
      project
  end

  let(:project2) { FactoryGirl.create(:project_with_trackers) }
  let(:issue) { FactoryGirl.create(:issue, :project => project,
                                       :tracker => project.trackers.first,
                                       :author => user) }
  let!(:cost_entry) { FactoryGirl.create(:cost_entry, issue: issue, project: project, units: 3, spent_on: Date.today, user: user, comments: "test entry") }
  let!(:cost_object) { FactoryGirl.create(:cost_object, project: project) }

  before(:each) do
    User.current = user
    @example = issue
    @cost_entry = cost_entry
  end

  it "should update cost entries on move" do
    @example.project_id.should eql project.id
    @example.move_to_project(project2).should_not be_false
    @cost_entry.reload.project_id.should eql project2.id
  end

  it "should allow to set cost_object to nil" do
    @example.cost_object = cost_object
    @example.save!
    @example.cost_object.should eql cost_object

    @example.cost_object = nil
    lambda { @example.save! }.should_not raise_error(ActiveRecord::RecordInvalid)
  end
end
