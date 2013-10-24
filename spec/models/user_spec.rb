#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe User do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_packages]) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                        :roles => [role],
                                        :principal => user) }
  let(:status) { FactoryGirl.create(:status) }
  let(:issue) { FactoryGirl.build(:work_package, :type => project.types.first,
                                      :author => user,
                                      :project => project,
                                      :status => status) }



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

  describe :blocked do
    let!(:blocked_user) do
      FactoryGirl.create(:user,
                         :failed_login_count => 3,
                         :last_failed_login_on => Time.now)
    end

    before do
      user.save!
      Setting.stub(:brute_force_block_after_failed_logins).and_return(3)
      Setting.stub(:brute_force_block_minutes).and_return(30)
    end

    it 'should return the single blocked user' do
      User.blocked.length.should == 1
      User.blocked.first.id.should == blocked_user.id
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
        user.reload # the user object needs to know of its membership for the watcher to be valid
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
    it { @u.force_password_change.should be_true}
  end

  describe :try_authentication_for_existing_user do
    def build_user_double_with_expired_password(is_expired)
      user_double = double('User')
      user_double.stub(:check_password?) { true }
      user_double.stub(:active?) { true }
      user_double.stub(:auth_source) { nil }
      user_double.stub(:force_password_change) { false }

      # check for expired password should always happen
      user_double.should_receive(:password_expired?) { is_expired }

      user_double
    end

    it 'should not allow login with an expired password' do
      user_double = build_user_double_with_expired_password(true)

      # use !! to ensure value is boolean
      (!!User.try_authentication_for_existing_user(user_double, 'anypassword')).should \
        == false
    end
    it 'should allow login with a not expired password' do
      user_double = build_user_double_with_expired_password(false)

      # use !! to ensure value is boolean
      (!!User.try_authentication_for_existing_user(user_double, 'anypassword')).should \
        == true
    end

    context 'with an external auth source' do
      let(:auth_source) { FactoryGirl.build(:auth_source) }
      let(:user_with_external_auth_source) do
        user = FactoryGirl.build(:user, :login => 'user')
        user.stub(:auth_source).and_return(auth_source)
        user
      end

      context 'and successful external authentication' do
        before do
          auth_source.should_receive(:authenticate).with('user', 'password').and_return(true)
        end

        it 'should succeed' do
          User.try_authentication_for_existing_user(user_with_external_auth_source, 'password').
            should == user_with_external_auth_source
        end
      end

      context 'and failing external authentication' do
        before do
          auth_source.should_receive(:authenticate).with('user', 'password').and_return(false)
        end

        it 'should fail when the authentication fails' do
          User.try_authentication_for_existing_user(user_with_external_auth_source, 'password').
            should == nil
        end
      end
    end
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

  describe ".default_admin_account_deleted_or_changed?" do
    let(:default_admin) { FactoryGirl.build(:user, :login => 'admin', :password => 'admin', :password_confirmation => 'admin', :admin => true) }

    before do
      Setting.password_min_length = 5
    end

    context "default admin account exists with default password" do
      before do
        default_admin.save
      end
      it { User.default_admin_account_changed?.should be_false }
    end

    context "default admin account exists with changed password" do
      before do
        default_admin.update_attribute :password, 'dafaultAdminPwd'
        default_admin.update_attribute :password_confirmation, 'dafaultAdminPwd'
        default_admin.save
      end

      it { User.default_admin_account_changed?.should be_true }
    end

    context "default admin account was deleted" do
      before do
        default_admin.save
        default_admin.delete
      end

      it { User.default_admin_account_changed?.should be_true }
    end

    context "default admin account was disabled" do
      before do
        default_admin.status = User::STATUSES[:locked]
        default_admin.save
      end

      it { User.default_admin_account_changed?.should be_true }
    end
  end

  describe ".find_by_rss_key" do
    before do
      @rss_key = user.rss_key
    end

    context "feeds enabled" do
      before do
        Setting.stub(:feeds_enabled?).and_return(true)
      end

      it { User.find_by_rss_key(@rss_key).should == user }
    end

    context "feeds disabled" do
      before do
        Setting.stub(:feeds_enabled?).and_return(false)
      end

      it { User.find_by_rss_key(@rss_key).should == nil }
    end
  end
end
