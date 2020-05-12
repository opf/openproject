#-- encoding: UTF-8
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
require_relative '../legacy_spec_helper'

describe User, type: :model do
  include MiniTest::Assertions # refute

  fixtures :all

  before do
    @admin = User.find(1)
    @jsmith = User.find(2)
    @dlopper = User.find(3)
  end

  specify 'object_daddy creation' do
    FactoryBot.create(:user, firstname: 'Testing connection')
    FactoryBot.create(:user, firstname: 'Testing connection')
    assert_equal 2, User.where(firstname: 'Testing connection').count
  end

  it 'should truth' do
    assert_kind_of User, @jsmith
  end

  it 'should mail should be stripped' do
    u = User.new
    u.mail = ' foo@bar.com  '
    assert_equal 'foo@bar.com', u.mail
  end

  it 'should create' do
    user = User.new(firstname: 'new', lastname: 'user', mail: 'newuser@somenet.foo')

    user.login = 'jsmith'
    user.password = 'adminADMIN!'
    user.password_confirmation = 'adminADMIN!'
    # login uniqueness
    assert !user.save
    assert_equal 1, user.errors.count

    user.login = 'newuser'
    user.password = 'adminADMIN!'
    user.password_confirmation = 'NOTadminADMIN!'
    # password confirmation
    assert !user.save
    assert_equal 1, user.errors.count

    user.password = 'adminADMIN!'
    user.password_confirmation = 'adminADMIN!'
    assert user.save
  end

  context 'User#before_create' do
    it 'should set the mail_notification to the default Setting' do
      @user1 = FactoryBot.create(:user, mail_notification: nil)
      assert_equal 'only_my_events', @user1.mail_notification

      Setting.default_notification_option = 'all'
      @user2 = FactoryBot.create(:user)
      assert_equal 'all', @user2.mail_notification
    end
  end

  context 'User.login' do
    it 'should be case-insensitive.' do
      u = User.new(firstname: 'new', lastname: 'user', mail: 'newuser@somenet.foo')
      u.login = 'newuser'
      u.password = 'adminADMIN!'
      u.password_confirmation = 'adminADMIN!'
      assert u.save

      u = User.new(firstname: 'Similar', lastname: 'User', mail: 'similaruser@somenet.foo')
      u.login = 'NewUser'
      u.password = 'adminADMIN!'
      u.password_confirmation = 'adminADMIN!'
      assert !u.save
      assert_includes u.errors[:login], I18n.translate('activerecord.errors.messages.taken')
    end
  end

  it 'should mail uniqueness should not be case sensitive' do
    u = User.new(firstname: 'new', lastname: 'user', mail: 'newuser@somenet.foo')
    u.login = 'newuser1'
    u.password = 'adminADMIN!'
    u.password_confirmation = 'adminADMIN!'
    assert u.save

    u = User.new(firstname: 'new', lastname: 'user', mail: 'newUser@Somenet.foo')
    u.login = 'newuser2'
    u.password = 'adminADMIN!'
    u.password_confirmation = 'adminADMIN!'
    assert !u.save
    assert_includes u.errors[:mail], I18n.translate('activerecord.errors.messages.taken')
  end

  it 'should update' do
    assert_equal 'admin', @admin.login
    @admin.login = 'john'
    assert @admin.save, @admin.errors.full_messages.join('; ')
    @admin.reload
    assert_equal 'john', @admin.login
  end

  it 'should destroy' do
    User.find(2).destroy
    assert_nil User.find_by(id: 2)
    assert Member.where(user_id: 2).empty?
  end

  it 'should validate login presence' do
    @admin.login = ''
    assert !@admin.save
    assert_equal 1, @admin.errors.count
  end

  it 'should validate mail notification inclusion' do
    u = User.new
    u.mail_notification = 'foo'
    u.save
    refute_empty u.errors[:mail_notification]
  end

  context 'User#try_to_login' do
    it 'should fall-back to case-insensitive if user login is not found as-typed.' do
      user = User.try_to_login('AdMin', 'adminADMIN!')
      assert_kind_of User, user
      assert_equal 'admin', user.login
    end

    it 'should select the exact matching user first' do
      case_sensitive_user = FactoryBot.create(:user, login: 'changed', password: 'adminADMIN!', password_confirmation: 'adminADMIN!')
      # bypass validations to make it appear like existing data
      case_sensitive_user.update_attribute(:login, 'ADMIN')

      user = User.try_to_login('ADMIN', 'adminADMIN!')
      assert_kind_of User, user
      assert_equal 'ADMIN', user.login
    end
  end

  it 'should password' do
    user = User.try_to_login('admin', 'adminADMIN!')
    assert_kind_of User, user
    assert_equal 'admin', user.login
    user.password = 'newpassPASS!'
    assert user.save

    user = User.try_to_login('admin', 'newpassPASS!')
    assert_kind_of User, user
    assert_equal 'admin', user.login
  end

  it 'should name format' do
    assert_equal 'Smith, John', @jsmith.name(:lastname_coma_firstname)
    Setting.user_format = :firstname_lastname
    assert_equal 'John Smith', @jsmith.reload.name
    Setting.user_format = :username
    assert_equal 'jsmith', @jsmith.reload.name
  end

  it 'should lock' do
    user = User.try_to_login('jsmith', 'jsmith')
    assert_equal @jsmith, user

    @jsmith.status = User::STATUSES[:locked]
    assert @jsmith.save

    user = User.try_to_login('jsmith', 'jsmith')
    assert_equal nil, user
  end

  context '.try_to_login' do
    context 'with good credentials' do
      it 'should return the user' do
        user = User.try_to_login('admin', 'adminADMIN!')
        assert_kind_of User, user
        assert_equal 'admin', user.login
      end
    end

    context 'with wrong credentials' do
      it 'should return nil' do
        assert_nil User.try_to_login('admin', 'foo')
      end
    end
  end

  if ldap_configured?
    context '#try_to_login using LDAP' do
      context 'with failed connection to the LDAP server' do
        it 'should return nil' do
          @auth_source = LdapAuthSource.find(1)
          allow_any_instance_of(AuthSource).to receive(:initialize_ldap_con).and_raise(Net::LDAP::LdapError, 'Cannot connect')

          assert_equal nil, User.try_to_login('edavis', 'wrong')
        end
      end

      context 'with an unsuccessful authentication' do
        it 'should return nil' do
          assert_equal nil, User.try_to_login('edavis', 'wrong')
        end
      end

      context 'on the fly registration' do
        before do
          @auth_source = LdapAuthSource.find(1)
        end

        context 'with a successful authentication' do
          it "should create a new user account if it doesn't exist" do
            assert_difference('User.count') do
              user = User.try_to_login('edavis', '123456')
              assert !user.admin?
            end
          end

          it 'should retrieve existing user' do
            user = User.try_to_login('edavis', '123456')
            user.admin = true
            user.save!

            assert_no_difference('User.count') do
              user = User.try_to_login('edavis', '123456')
              assert user.admin?
            end
          end
        end
      end
    end

  else
    puts 'Skipping LDAP tests.'
  end

  it 'should return existing or new anonymous' do
    anon = User.anonymous
    assert !anon.new_record?
    assert_kind_of AnonymousUser, anon
  end

  it { is_expected.to have_one :rss_token }

  it 'should rss key' do
    assert_nil @jsmith.rss_token
    key = @jsmith.rss_key
    assert_equal 64, key.length

    @jsmith.reload
    assert_equal key, @jsmith.rss_key
  end

  it { is_expected.to have_one :api_token }

  context 'User#find_by_api_key' do
    it 'should return nil if no matching key is found' do
      assert_nil User.find_by_api_key('zzzzzzzzz')
    end

    it 'should return nil if the key is found for an inactive user' do
      user = FactoryBot.create(:user, status: User::STATUSES[:locked])
      token = FactoryBot.build(:api_token, user: user)
      user.api_token = token
      user.save

      assert_nil User.find_by_api_key(token.value)
    end

    it 'should return the user if the key is found for an active user' do
      user = FactoryBot.create(:user, status: User::STATUSES[:active])
      token = FactoryBot.build(:api_token, user: user)
      user.api_token = token
      user.save

      assert_equal user, User.find_by_api_key(token.plain_value)
    end
  end

  it 'should roles for project' do
    # user with a role
    roles = @jsmith.roles_for_project(Project.find(1))
    assert_kind_of Role, roles.first
    assert_equal 'Manager', roles.first.name

    # user with no role
    assert_nil @dlopper.roles_for_project(Project.find(2)).detect(&:member?)
  end

  it 'should projects by role for user with role' do
    user = User.find(2)
    assert_kind_of Hash, user.projects_by_role
    assert_equal 2, user.projects_by_role.size
    assert_equal [1, 5], user.projects_by_role[Role.find(1)].map(&:id).sort
    assert_equal [2], user.projects_by_role[Role.find(2)].map(&:id).sort
  end

  it 'should projects by role for user with no role' do
    user = FactoryBot.create(:user)
    assert_equal({}, user.projects_by_role)
  end

  it 'should projects by role for anonymous' do
    assert_equal({}, User.anonymous.projects_by_role)
  end

  it 'should valid notification options' do
    # without memberships
    assert_equal 5, User.find(7).valid_notification_options.size
    # with memberships
    assert_equal 6, User.find(2).valid_notification_options.size
  end

  it 'should valid notification options class method' do
    assert_equal 5, User.valid_notification_options.size
    assert_equal 5, User.valid_notification_options(User.find(7)).size
    assert_equal 6, User.valid_notification_options(User.find(2)).size
  end

  it 'should mail notification all' do
    @jsmith.mail_notification = 'all'
    @jsmith.notified_project_ids = []
    @jsmith.save
    @jsmith.reload
    assert @jsmith.projects.first.recipients.include?(@jsmith)
  end

  it 'should mail notification selected' do
    @jsmith.mail_notification = 'selected'
    @jsmith.notified_project_ids = [1]
    @jsmith.save
    @jsmith.reload
    assert Project.find(1).recipients.include?(@jsmith)
  end

  it 'should mail notification only my events' do
    @jsmith.mail_notification = 'only_my_events'
    @jsmith.notified_project_ids = []
    @jsmith.save
    @jsmith.reload
    assert !@jsmith.projects.first.recipients.include?(@jsmith)
  end

  it 'should comments sorting preference' do
    assert !@jsmith.wants_comments_in_reverse_order?
    @jsmith.pref.comments_sorting = 'asc'
    assert !@jsmith.wants_comments_in_reverse_order?
    @jsmith.pref.comments_sorting = 'desc'
    assert @jsmith.wants_comments_in_reverse_order?
  end

  it 'should find by mail should be case insensitive' do
    u = User.find_by_mail('JSmith@somenet.foo')
    refute_nil u
    assert_equal 'jsmith@somenet.foo', u.mail
  end
end
