#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe User, type: :model do
  let(:user) { FactoryBot.build(:user) }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:member) do
    FactoryBot.build(:member, project: project,
                              roles: [role],
                              principal: user)
  end
  let(:status) { FactoryBot.create(:status) }
  let(:issue) do
    FactoryBot.build(:work_package, type: project.types.first,
                                    author: user,
                                    project: project,
                                    status: status)
  end

  describe '.not_builtin' do
    let!(:anonymous_user) { FactoryBot.create(:anonymous) }
    let!(:system_user) { FactoryBot.create(:system) }
    let!(:deleted_user) { FactoryBot.create(:deleted_user) }
    let!(:user) { FactoryBot.create(:user) }

    subject { described_class.not_builtin }

    it 'returns only actual users', :aggregate_failures do
      expect(subject).to include(user)
      expect(subject).not_to include(anonymous_user)
      expect(subject).not_to include(system_user)
      expect(subject).not_to include(deleted_user)
    end
  end

  describe 'a user with a long login (<= 256 chars)' do
    let(:login) { 'a' * 256 }
    it 'is valid' do
      user.login = login
      expect(user).to be_valid
    end

    it 'may be loaded from the database' do
      user.login = login
      expect(user.save).to be_truthy

      expect(User.find_by_login(login)).to eq(user)
      expect(User.find_by_unique(login)).to eq(user)
    end
  end

  describe 'a user with an invalid login' do
    let(:login) { 'me' }

    it 'is invalid' do
      user.login = login
      expect(user).not_to be_valid
    end
  end

  describe 'a user with and overly long login (> 256 chars)' do
    it 'is invalid' do
      user.login = 'a' * 257
      expect(user).not_to be_valid
    end

    it 'may not be stored in the database' do
      user.login = 'a' * 257
      expect(user.save).to be_falsey
    end
  end

  describe 'login whitespace' do
    before do
      user.login = login
    end

    context 'simple spaces' do
      let(:login) { 'a b  c' }

      it 'is valid' do
        expect(user).to be_valid
      end

      it 'may be stored in the database' do
        expect(user.save).to be_truthy
      end
    end

    context 'line breaks' do
      let(:login) { 'ab\nc' }

      it 'is invalid' do
        expect(user).not_to be_valid
      end

      it 'may not be stored in the database' do
        expect(user.save).to be_falsey
      end
    end

    context 'tabs' do
      let(:login) { 'ab\tc' }

      it 'is invalid' do
        expect(user).not_to be_valid
      end

      it 'may not be stored in the database' do
        expect(user.save).to be_falsey
      end
    end
  end

  describe 'login symbols' do
    before do
      user.login = login
    end

    %w[+ _ . - @].each do |symbol|
      context symbol do
        let(:login) { "foo#{symbol}bar" }

        it 'is valid' do
          expect(user).to be_valid
        end

        it 'may be stored in the database' do
          expect(user.save).to be_truthy
        end
      end
    end

    context 'combination thereof' do
      let(:login) { 'the+boss-is@the_house.' }

      it 'is valid' do
        expect(user).to be_valid
      end

      it 'may be stored in the database' do
        expect(user.save).to be_truthy
      end
    end

    context 'with invalid symbol' do
      let(:login) { 'invalid!name' }

      it 'is invalid' do
        expect(user).not_to be_valid
      end

      it 'may not be stored in the database' do
        expect(user.save).to be_falsey
      end
    end
  end

  describe '#assigned_issues' do
    before do
      user.save!
    end

    describe 'WHEN the user has an issue assigned' do
      before do
        member.save!

        issue.assigned_to = user
        issue.save!
      end

      it { expect(user.assigned_issues).to eq([issue]) }
    end

    describe 'WHEN the user has no issue assigned' do
      before do
        member.save!

        issue.save!
      end

      it { expect(user.assigned_issues).to eq([]) }
    end
  end

  describe '#authentication_provider' do
    before do
      user.identity_url = 'test_provider:veryuniqueid'
      user.save!
    end

    it 'should create a human readable name' do
      expect(user.authentication_provider).to eql('Test Provider')
    end
  end

  describe '#blocked' do
    let!(:blocked_user) do
      FactoryBot.create(:user,
                        failed_login_count: 3,
                        last_failed_login_on: Time.now)
    end

    before do
      user.save!
      allow(Setting).to receive(:brute_force_block_after_failed_logins).and_return(3)
      allow(Setting).to receive(:brute_force_block_minutes).and_return(30)
    end

    it 'should return the single blocked user' do
      expect(User.blocked.length).to eq(1)
      expect(User.blocked.first.id).to eq(blocked_user.id)
    end
  end

  describe '#change_password_allowed?' do
    let(:user) { FactoryBot.build(:user) }

    context 'for user without auth source' do
      before do
        user.auth_source = nil
      end

      it 'should be true' do
        assert user.change_password_allowed?
      end
    end

    context 'for user with an auth source' do
      let(:allowed_auth_source) { FactoryBot.create :auth_source }

      context 'that allows password changes' do
        before do
          def allowed_auth_source.allow_password_changes?; true; end
          user.auth_source = allowed_auth_source
        end

        it 'should allow password changes' do
          expect(user.change_password_allowed?).to be_truthy
        end
      end

      context 'that does not allow password changes' do
        let(:denied_auth_source) { FactoryBot.create :auth_source }

        before do
          def denied_auth_source.allow_password_changes?; false; end
          user.auth_source = denied_auth_source
        end

        it 'should not allow password changes' do
          expect(user.change_password_allowed?).to be_falsey
        end
      end
    end

    context 'for user without authsource and with external authentication' do
      before do
        user.auth_source = nil
        allow(user).to receive(:uses_external_authentication?).and_return(true)
      end

      it 'should not allow a password change' do
        expect(user.change_password_allowed?).to be_falsey
      end
    end
  end

  describe '#watches' do
    before do
      user.save!
    end

    describe 'WHEN the user is watching' do
      let(:watcher) do
        Watcher.new(watchable: issue,
                    user: user)
      end

      before do
        issue.save!
        member.save!
        user.reload # the user object needs to know of its membership for the watcher to be valid
        watcher.save!
      end

      it { expect(user.watches).to eq([watcher]) }
    end

    describe "WHEN the user isn't watching" do
      before do
        issue.save!
      end

      it { expect(user.watches).to eq([]) }
    end
  end

  describe '#uses_external_authentication?' do
    context 'with identity_url' do
      let(:user) { FactoryBot.build(:user, identity_url: 'test_provider:veryuniqueid') }

      it 'should return true' do
        expect(user.uses_external_authentication?).to be_truthy
      end
    end

    context 'without identity_url' do
      let(:user) { FactoryBot.build(:user, identity_url: nil) }

      it 'should return false' do
        expect(user.uses_external_authentication?).to be_falsey
      end
    end
  end

  describe 'user create with empty password' do
    before do
      @u = User.new(firstname: 'new', lastname: 'user', mail: 'newuser@somenet.foo')
      @u.login = 'new_user'
      @u.password = ''
      @u.password_confirmation = ''
      @u.save
    end

    it { expect(@u.valid?).to be_falsey }
    it { expect(@u.errors[:password]).to include I18n.t('activerecord.errors.messages.too_short', count: Setting.password_min_length.to_i) }
  end

  describe '#random_password' do
    before do
      @u = User.new
      expect(@u.password).to be_nil
      expect(@u.password_confirmation).to be_nil
      @u.random_password!
    end

    it { expect(@u.password).not_to be_blank }
    it { expect(@u.password_confirmation).not_to be_blank }
    it { expect(@u.force_password_change).to be_truthy }
  end

  describe '#try_authentication_for_existing_user' do
    def build_user_double_with_expired_password(is_expired)
      user_double = double('User')
      allow(user_double).to receive(:check_password?) { true }
      allow(user_double).to receive(:active?) { true }
      allow(user_double).to receive(:auth_source) { nil }
      allow(user_double).to receive(:force_password_change) { false }

      # check for expired password should always happen
      expect(user_double).to receive(:password_expired?) { is_expired }

      user_double
    end

    it 'should not allow login with an expired password' do
      user_double = build_user_double_with_expired_password(true)

      # use !! to ensure value is boolean
      expect(!!User.try_authentication_for_existing_user(user_double, 'anypassword')).to \
        eq(false)
    end
    it 'should allow login with a not expired password' do
      user_double = build_user_double_with_expired_password(false)

      # use !! to ensure value is boolean
      expect(!!User.try_authentication_for_existing_user(user_double, 'anypassword')).to \
        eq(true)
    end

    context 'with an external auth source' do
      let(:auth_source) { FactoryBot.build(:auth_source) }
      let(:user_with_external_auth_source) do
        user = FactoryBot.build(:user, login: 'user')
        allow(user).to receive(:auth_source).and_return(auth_source)
        user
      end

      context 'and successful external authentication' do
        before do
          expect(auth_source).to receive(:authenticate).with('user', 'password').and_return(true)
        end

        it 'should succeed' do
          expect(User.try_authentication_for_existing_user(user_with_external_auth_source, 'password'))
            .to eq(user_with_external_auth_source)
        end
      end

      context 'and failing external authentication' do
        before do
          expect(auth_source).to receive(:authenticate).with('user', 'password').and_return(false)
        end

        it 'should fail when the authentication fails' do
          expect(User.try_authentication_for_existing_user(user_with_external_auth_source, 'password'))
            .to eq(nil)
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
        expect do
          system_user = User.system
          expect(system_user.new_record?).to be_falsey
          expect(system_user.is_a?(SystemUser)).to be_truthy
        end.to change(User, :count).by(1)
      end
    end

    context 'a SystemUser exists' do
      before do
        @u = User.system
        expect(SystemUser.first).to eq(@u)
      end

      it 'returns existing SystemUser' do
        expect do
          system_user = User.system
          expect(system_user).to eq(@u)
        end.to change(User, :count).by(0)
      end
    end
  end

  describe '.default_admin_account_deleted_or_changed?' do
    let(:default_admin) { FactoryBot.build(:user, login: 'admin', password: 'admin', password_confirmation: 'admin', admin: true) }

    before do
      Setting.password_min_length = 5
    end

    context 'default admin account exists with default password' do
      before do
        default_admin.save
      end
      it { expect(User.default_admin_account_changed?).to be_falsey }
    end

    context 'default admin account exists with changed password' do
      before do
        default_admin.update_attribute :password, 'dafaultAdminPwd'
        default_admin.update_attribute :password_confirmation, 'dafaultAdminPwd'
        default_admin.save
      end

      it { expect(User.default_admin_account_changed?).to be_truthy }
    end

    context 'default admin account was deleted' do
      before do
        default_admin.save
        default_admin.delete
      end

      it { expect(User.default_admin_account_changed?).to be_truthy }
    end

    context 'default admin account was disabled' do
      before do
        default_admin.status = User::STATUSES[:locked]
        default_admin.save
      end

      it { expect(User.default_admin_account_changed?).to be_truthy }
    end
  end

  describe '.find_by_rss_key' do
    before do
      @rss_key = user.rss_key
    end

    context 'feeds enabled' do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(true)
      end

      it { expect(User.find_by_rss_key(@rss_key)).to eq(user) }
    end

    context 'feeds disabled' do
      before do
        allow(Setting).to receive(:feeds_enabled?).and_return(false)
      end

      it { expect(User.find_by_rss_key(@rss_key)).to eq(nil) }
    end
  end

  describe '#notify_about?' do
    let(:work_package) do
      FactoryBot.build_stubbed(:work_package,
                               assigned_to: assignee,
                               responsible: responsible,
                               author: author)
    end
    let(:author) do
      FactoryBot.build_stubbed(:user)
    end
    let(:assignee) do
      FactoryBot.build_stubbed(:user)
    end
    let(:responsible) do
      FactoryBot.build_stubbed(:user)
    end
    let(:project) do
      work_package.project
    end
    let(:role) do
      FactoryBot.build_stubbed(:role)
    end

    it 'is false for an inactive user' do
      user.status = User::STATUSES[:locked]
      user.mail_notification = 'all'
      expect(user.notify_about?({})).to be_falsey
    end

    context 'Work package' do
      it 'is true for a user with :all' do
        author.mail_notification = 'all'
        assert author.notify_about?(work_package)
      end

      it 'is false for a user with :none' do
        author.mail_notification = 'none'
        expect(author.notify_about?(work_package)).to be_falsey
      end

      it "is false for a user with :only_my_events who has no relation to the work package" do
        user = FactoryBot.build_stubbed(:user, mail_notification: 'only_my_events')
        (Member.new.tap do |m|
          m.attributes = { principal: user, project: project, role_ids: [role.id] }
        end)
        expect(user.notify_about?(work_package)).to be_falsey
      end

      it 'is true for a user with :only_my_events who is the author' do
        author.mail_notification = 'only_my_events'
        expect(author.notify_about?(work_package)).to be_truthy
      end

      it 'is true for a user with :only_my_events who is the assignee' do
        assignee.mail_notification = 'only_my_events'
        expect(assignee.notify_about?(work_package)).to be_truthy
      end

      it 'is true for a user with :only_assigned who is the assignee' do
        assignee.mail_notification = 'only_assigned'
        expect(assignee.notify_about?(work_package)).to be_truthy
      end

      it 'is true for a user with :only_assigned who is the responsible' do
        responsible.mail_notification = 'only_assigned'
        expect(responsible.notify_about?(work_package)).to be_truthy
      end

      it 'is false for a user with :only_assigned who is neither assignee nor responsible' do
        author.mail_notification = 'only_assigned'
        expect(author.notify_about?(work_package)).to be_falsey
      end

      it 'is true for a user with :only_owner who is the author' do
        author.mail_notification = 'only_owner'
        expect(author.notify_about?(work_package)).to be_truthy
      end

      it 'is false for a user with :only_owner who is not the author' do
        assignee.mail_notification = 'only_owner'
        expect(assignee.notify_about?(work_package)).to be_falsey
      end

      it 'is true for a user with :selected who is the author' do
        author.mail_notification = 'selected'
        expect(author.notify_about?(work_package)).to be_truthy
      end

      it 'is true for a user with :selected who is the assignee' do
        assignee.mail_notification = 'selected'
        expect(assignee.notify_about?(work_package)).to be_truthy
      end

      it 'is true for a user with :selected who is the responsible' do
        responsible.mail_notification = 'selected'
        expect(responsible.notify_about?(work_package)).to be_truthy
      end

      it "is false for a user with :only_my_events who has no relation to the work package" do
        user = FactoryBot.build(:user, mail_notification: 'selected')
        (Member.new.tap do |m|
          m.attributes = { principal: user, project: project, role_ids: [role.id] }
        end)
        expect(user.notify_about?(work_package)).to be_falsey
      end
    end
  end

  describe 'scope.newest' do
    let!(:anonymous) { User.anonymous }
    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }

    let(:newest) { User.newest.to_a }

    it 'without anonymous user', :aggregate_failures do
      expect(newest).to include(user1)
      expect(newest).to include(user2)
      expect(newest).not_to include(anonymous)
    end
  end

  describe '#mail_regexp' do
    it 'handles suffixed mails' do
      _, suffixed = User.mail_regexp('foo+bar@example.org')
      expect(suffixed).to be_truthy
    end
  end

  describe '#find_by_mail' do
    let!(:user1) { FactoryBot.create(:user, mail: 'foo+test@example.org') }
    let!(:user2) { FactoryBot.create(:user, mail: 'foo@example.org') }
    let!(:user3) { FactoryBot.create(:user, mail: 'foo-bar@example.org') }

    context 'with default plus suffix' do
      it 'finds users matching the suffix' do
        expect(Setting.mail_suffix_separators).to eq '+'

        # Can match either of the first two
        match2 = User.find_by_mail('foo@example.org')
        expect([user1.id, user2.id]).to include(match2.id)

        matches = User.where_mail_with_suffix('foo@example.org')
        expect(matches.pluck(:id)).to match_array [user1.id, user2.id]

        matches = User.where_mail_with_suffix('foo+test@example.org')
        expect(matches.pluck(:id)).to match_array [user1.id]
      end
    end

    context 'with plus and minus suffix', with_settings: { mail_suffix_separators: '+-' } do
      it 'finds users matching the suffix' do
        expect(Setting.mail_suffix_separators).to eq '+-'

        match1 = User.find_by_mail('foo-bar@example.org')
        expect(match1).to eq(user3)

        # Can match either of the three
        match2 = User.find_by_mail('foo@example.org')
        expect([user1.id, user2.id, user3.id]).to include(match2.id)

        matches = User.where_mail_with_suffix('foo@example.org')
        expect(matches.pluck(:id)).to match_array [user1.id, user2.id, user3.id]
      end
    end
  end
end
