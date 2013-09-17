require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WorkPackage do
  let(:user) { FactoryGirl.create(:admin)}
  let(:role) { FactoryGirl.create(:role) }
  let(:project) do
      project = FactoryGirl.create(:project_with_trackers)
      project.add_member!(user, role)
      project
  end

  let(:project2) { FactoryGirl.create(:project_with_trackers) }
  let(:work_package) { FactoryGirl.create(:work_package, :project => project,
                                       :tracker => project.trackers.first,
                                       :author => user) }
  let!(:cost_entry) { FactoryGirl.create(:cost_entry, work_package: work_package, project: project, units: 3, spent_on: Date.today, user: user, comments: "test entry") }
  let!(:cost_object) { FactoryGirl.create(:cost_object, project: project) }

  before(:each) do
    User.stub!(:current).and_return(user)
  end

  it "should update cost entries on move" do
    work_package.project_id.should eql project.id
    work_package.move_to_project(project2).should_not be_false
    cost_entry.reload.project_id.should eql project2.id
  end

  it "should allow to set cost_object to nil" do
    work_package.cost_object = cost_object
    work_package.save!
    work_package.cost_object.should eql cost_object

    work_package.cost_object = nil
    lambda { work_package.save! }.should_not raise_error(ActiveRecord::RecordInvalid)
  end
end
