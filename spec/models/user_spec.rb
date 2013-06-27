#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.create(:project_with_trackers) }
  let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_packages]) }
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
        member.save!
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

  describe 'user create with empty password' do
    before do
      @u = User.new(:firstname => "new", :lastname => "user", :mail => "newuser@somenet.foo")
      @u.login = "new_user"
      @u.password, @u.password_confirmation = "", ""
      @u.save
    end

    it { @u.valid?.should be_false }
    it { @u.errors[:password].should include I18n.t('activerecord.errors.messages.too_short', :count => Setting.password_min_length.to_i) }
  end

  describe '#random_password' do
    before do
      @u = User.new
      @u.password.should be_nil
      @u.password_confirmation.should be_nil
      @u.random_password!
    end

    it { @u.password.should_not be_blank }
    it { @u.password_confirmation.should_not be_blank }
  end

  describe '.system' do
    context 'no SystemUser exists' do
      before do
        SystemUser.delete_all
      end

      it 'creates a SystemUser' do
        lambda do
          system_user = User.system
          system_user.new_record?.should be_false
          system_user.is_a?(SystemUser).should be_true
        end.should change(User, :count).by(1)
      end
    end

    context 'a SystemUser exists' do
      before do
        @u = User.system
        SystemUser.first.should == @u
      end

      it 'returns existing SystemUser'  do
        lambda do
          system_user = User.system
          system_user.should == @u
        end.should change(User, :count).by(0)
      end
    end
  end
end
