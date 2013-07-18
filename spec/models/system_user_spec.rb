require 'spec_helper'

describe SystemUser do
  let(:system_user) { User.system }

  describe '#grant_privileges' do
    before do
      system_user.admin.should be_false
      system_user.status.should == User::STATUSES[:locked]
      system_user.grant_privileges
    end

    it 'grant admin rights' do
      system_user.admin.should be_true
    end

    it 'unlocks the user' do
      system_user.status.should == User::STATUSES[:builtin]
    end
  end

  describe '#remove_privileges' do
    before do
      system_user.admin = true
      system_user.status = User::STATUSES[:active]
      system_user.save
      system_user.remove_privileges
    end

    it 'removes admin rights' do
      system_user.admin.should be_false
    end

    it 'locks the user' do
      system_user.status.should == User::STATUSES[:locked]
    end
  end

  describe '#run_given' do
    let(:project) { FactoryGirl.create(:project_with_types, :is_public => false) }
    let(:user) { FactoryGirl.build(:user) }
    let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_packages]) }
    let(:member) { FactoryGirl.build(:member, :project => project,
                                              :roles => [role],
                                              :principal => user) }
    let(:issue_status) { FactoryGirl.create(:issue_status) }
    let(:issue) { FactoryGirl.build(:issue, :type => project.types.first,
                                            :author => user,
                                            :project => project,
                                            :status => issue_status) }

    before do
      issue.save!
      @u = system_user
    end

    it 'runs block with SystemUser' do
      @u.admin?.should be_false
      before_user = User.current

      @u.run_given do
        issue.done_ratio = 50
        issue.save
      end
      issue.done_ratio.should == 50
      issue.journals.last.user.should == @u

      @u.admin?.should be_false
      User.current.should == before_user
    end
  end
end
