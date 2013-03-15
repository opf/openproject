require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.create(:project_with_trackers) }
  let(:role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                        :roles => [role],
                                        :principal => user) }
  let(:issue_status) { FactoryGirl.create(:issue_status) }
  let(:issue) { FactoryGirl.build(:issue, :tracker => project.trackers.first,
                                      :author => user,
                                      :project => project,
                                      :status => issue_status) }



  describe 'a user with a long login (<= 256 chars)' do
    it 'is valid' do
      user.login = 'a' * 256
      user.should be_valid
    end

    it 'may be stored in the database' do
      user.login = 'a' * 256
      user.save.should be_true
    end

    it 'may be loaded from the database' do
      user.login = 'a' * 256
      user.save

      User.find_by_login('a' * 256).should == user
    end
  end

  describe 'a user with and overly long login (> 256 chars)' do
    it 'is invalid' do
      user.login = 'a' * 257
      user.should_not be_valid
    end

    it 'may not be stored in the database' do
      user.login = 'a' * 257
      user.save.should be_false
    end

  end


  describe :assigned_issues do
    before do
      user.save!
    end

    describe "WHEN the user has an issue assigned" do
      before do
        member.save!

        issue.assigned_to = user
        issue.save!
      end

      it { user.assigned_issues.should == [issue] }
    end

    describe "WHEN the user has no issue assigned" do
      before do
        member.save!

        issue.save!
      end

      it { user.assigned_issues.should == [] }
    end
  end

  describe :watches do
    before do
      user.save!
    end

    describe "WHEN the user is watching" do
      let(:watcher) { Watcher.new(:watchable => issue,
                                  :user => user) }

      before do
        issue.save!

        # allow the user to watch the issue
        issue.stubs(:visible?).with(user).returns(true)

        watcher.save!
      end

      it { user.watches.should == [watcher] }
    end

    describe "WHEN the user isn't watching" do
      before do
        issue.save!
      end

      it { user.watches.should == [] }
    end
  end
end
