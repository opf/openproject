require 'spec_helper'

describe WorkPackages::BulkController do
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:controller_role) { FactoryGirl.build(:role, :permissions => [:view_work_packages, :edit_work_packages]) }
  let(:user) { FactoryGirl.create :user, member_in_project: project, member_through_role: controller_role }
  let(:cost_object) { FactoryGirl.create :cost_object, project: project }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }

  before do
    User.stub(:current).and_return user
  end

  describe :update do
    context 'when a cost report is assigned' do
      before { put :update, ids: [work_package.id], work_package: {cost_object_id: cost_object.id} }

      subject { work_package.reload.cost_object.try :id }

      it { should == cost_object.id }
    end
  end

end