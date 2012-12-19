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

  describe :assigned_issues do
    before do
      user.save!
    end

    describe "WHEN the user has an issue assigned" do
      before do
        member.save!

        issue.assigned_to = user
        issue.save
      end

      it { user.assigned_issues.should == [issue] }
    end

    describe "WHEN the user has no issue assigned" do
      before do
        member.save

        issue.save
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
        issue.save

        watcher.save
      end

      it { user.watches.should == [watcher] }
    end

    describe "WHEN the user isn't watching" do
      before do
        issue.save
      end

      it { user.watches.should == [] }
    end
  end
end
