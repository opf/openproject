#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require File.expand_path('../../test_helper', __FILE__)

class UserTest < ActiveSupport::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  def setup
    super
    @admin = User.find(1)
    @jsmith = User.find(2)
    @dlopper = User.find(3)
  end

  test 'object_daddy creation' do
    User.generate_with_protected!(:firstname => 'Testing connection')
    User.generate_with_protected!(:firstname => 'Testing connection')
    assert_equal 2, User.count(:all, :conditions => {:firstname => 'Testing connection'})
  end

  def test_truth
    assert_kind_of User, @jsmith
  end

  def test_mail_should_be_stripped
    u = User.new
    u.mail = " foo@bar.com  "
    assert_equal "foo@bar.com", u.mail
  end

  def test_create
    user = User.new(:firstname => "new", :lastname => "user", :mail => "newuser@somenet.foo")

    user.login = "jsmith"
    user.password, user.password_confirmation = "adminADMIN!", "adminADMIN!"
    # login uniqueness
    assert !user.save
    assert_equal 1, user.errors.count

    user.login = "newuser"
    user.password, user.password_confirmation = "adminADMIN!", "NOTadminADMIN!"
    # password confirmation
    assert !user.save
    assert_equal 1, user.errors.count

    user.password, user.password_confirmation = "adminADMIN!", "adminADMIN!"
    assert user.save
  end

  context "User#before_create" do
    should "set the mail_notification to the default Setting" do
      @user1 = User.generate_with_protected!
      assert_equal 'only_my_events', @user1.mail_notification

      with_settings :default_notification_option => 'all' do
        @user2 = User.generate_with_protected!
        assert_equal 'all', @user2.mail_notification
      end
    end
  end

  context "User.login" do
    should "be case-insensitive." do
      u = User.new(:firstname => "new", :lastname => "user", :mail => "newuser@somenet.foo")
      u.login = 'newuser'
      u.password, u.password_confirmation = "adminADMIN!", "adminADMIN!"
      assert u.save

      u = User.new(:firstname => "Similar", :lastname => "User", :mail => "similaruser@somenet.foo")
      u.login = 'NewUser'
      u.password, u.password_confirmation = "adminADMIN!", "adminADMIN!"
      assert !u.save
      assert_include u.errors[:login], I18n.translate('activerecord.errors.messages.taken')
    end
  end

  def test_mail_uniqueness_should_not_be_case_sensitive
    u = User.new(:firstname => "new", :lastname => "user", :mail => "newuser@somenet.foo")
    u.login = 'newuser1'
    u.password, u.password_confirmation = "adminADMIN!", "adminADMIN!"
    assert u.save

    u = User.new(:firstname => "new", :lastname => "user", :mail => "newUser@Somenet.foo")
    u.login = 'newuser2'
    u.password, u.password_confirmation = "adminADMIN!", "adminADMIN!"
    assert !u.save
    assert_include u.errors[:mail], I18n.translate('activerecord.errors.messages.taken')
  end

  def test_update
    assert_equal "admin", @admin.login
    @admin.login = "john"
    assert @admin.save, @admin.errors.full_messages.join("; ")
    @admin.reload
    assert_equal "john", @admin.login
  end

  def test_destroy
    User.find(2).destroy
    assert_nil User.find_by_id(2)
    assert Member.find_all_by_user_id(2).empty?
  end

  def test_validate_login_presence
    @admin.login = ""
    assert !@admin.save
    assert_equal 1, @admin.errors.count
  end

  def test_validate_mail_notification_inclusion
    u = User.new
    u.mail_notification = 'foo'
    u.save
    refute_empty u.errors[:mail_notification]
  end

  context "User#try_to_login" do
    should "fall-back to case-insensitive if user login is not found as-typed." do
      user = User.try_to_login("AdMin", "adminADMIN!")
      assert_kind_of User, user
      assert_equal "admin", user.login
    end

    should "select the exact matching user first" do
      case_sensitive_user = User.generate_with_protected!(:login => 'changed', :password => 'adminADMIN!', :password_confirmation => 'adminADMIN!')
      # bypass validations to make it appear like existing data
      case_sensitive_user.update_attribute(:login, 'ADMIN')

      user = User.try_to_login("ADMIN", "adminADMIN!")
      assert_kind_of User, user
      assert_equal "ADMIN", user.login

    end
  end

  def test_password
    user = User.try_to_login("admin", "adminADMIN!")
    assert_kind_of User, user
    assert_equal "admin", user.login
    user.password = "newpassPASS!"
    assert user.save

    user = User.try_to_login("admin", "newpassPASS!")
    assert_kind_of User, user
    assert_equal "admin", user.login
  end

  def test_name_format
    assert_equal 'Smith, John', @jsmith.name(:lastname_coma_firstname)
    Setting.user_format = :firstname_lastname
    assert_equal 'John Smith', @jsmith.reload.name
    Setting.user_format = :username
    assert_equal 'jsmith', @jsmith.reload.name
  end

  def test_lock
    user = User.try_to_login("jsmith", "jsmith")
    assert_equal @jsmith, user

    @jsmith.status = User::STATUSES[:locked]
    assert @jsmith.save

    user = User.try_to_login("jsmith", "jsmith")
    assert_equal nil, user
  end

  context ".try_to_login" do
    context "with good credentials" do
      should "return the user" do
        user = User.try_to_login("admin", "adminADMIN!")
        assert_kind_of User, user
        assert_equal "admin", user.login
      end
    end

    context "with wrong credentials" do
      should "return nil" do
        assert_nil User.try_to_login("admin", "foo")
      end
    end
  end

  if ldap_configured?
    context "#try_to_login using LDAP" do
      context "with failed connection to the LDAP server" do
        should "return nil" do
          @auth_source = LdapAuthSource.find(1)
          AuthSource.any_instance.stub(:initialize_ldap_con).and_raise(Net::LDAP::LdapError, 'Cannot connect')

          assert_equal nil, User.try_to_login('edavis', 'wrong')
        end
      end

      context "with an unsuccessful authentication" do
        should "return nil" do
          assert_equal nil, User.try_to_login('edavis', 'wrong')
        end
      end

      context "on the fly registration" do
        setup do
          @auth_source = LdapAuthSource.find(1)
        end

        context "with a successful authentication" do
          should "create a new user account if it doesn't exist" do
            assert_difference('User.count') do
              user = User.try_to_login('edavis', '123456')
              assert !user.admin?
            end
          end

          should "retrieve existing user" do
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
    puts "Skipping LDAP tests."
  end

  def test_create_anonymous
    AnonymousUser.delete_all
    anon = User.anonymous
    assert !anon.new_record?
    assert_kind_of AnonymousUser, anon
  end

  should have_one :rss_token

  def test_rss_key
    assert_nil @jsmith.rss_token
    key = @jsmith.rss_key
    assert_equal 40, key.length

    @jsmith.reload
    assert_equal key, @jsmith.rss_key
  end


  should have_one :api_token

  context "User#api_key" do
    should "generate a new one if the user doesn't have one" do
      user = User.generate_with_protected!(:api_token => nil)
      assert_nil user.api_token

      key = user.api_key
      assert_equal 40, key.length
      user.reload
      assert_equal key, user.api_key
    end

    should "return the existing api token value" do
      user = User.generate_with_protected!
      token = Token.generate!(:action => 'api')
      user.api_token = token
      assert user.save

      assert_equal token.value, user.api_key
    end
  end

  context "User#find_by_api_key" do
    should "return nil if no matching key is found" do
      assert_nil User.find_by_api_key('zzzzzzzzz')
    end

    should "return nil if the key is found for an inactive user" do
      user = User.generate_with_protected!(:status => User::STATUSES[:locked])
      token = Token.generate!(:action => 'api')
      user.api_token = token
      user.save

      assert_nil User.find_by_api_key(token.value)
    end

    should "return the user if the key is found for an active user" do
      user = User.generate_with_protected!(:status => User::STATUSES[:active])
      token = Token.generate!(:action => 'api')
      user.api_token = token
      user.save

      assert_equal user, User.find_by_api_key(token.value)
    end
  end

  def test_roles_for_project
    # user with a role
    roles = @jsmith.roles_for_project(Project.find(1))
    assert_kind_of Role, roles.first
    assert_equal "Manager", roles.first.name

    # user with no role
    assert_nil @dlopper.roles_for_project(Project.find(2)).detect {|role| role.member?}
  end

  def test_projects_by_role_for_user_with_role
    user = User.find(2)
    assert_kind_of Hash, user.projects_by_role
    assert_equal 2, user.projects_by_role.size
    assert_equal [1,5], user.projects_by_role[Role.find(1)].collect(&:id).sort
    assert_equal [2], user.projects_by_role[Role.find(2)].collect(&:id).sort
  end

  def test_projects_by_role_for_user_with_no_role
    user = User.generate!
    assert_equal({}, user.projects_by_role)
  end

  def test_projects_by_role_for_anonymous
    assert_equal({}, User.anonymous.projects_by_role)
  end

  def test_valid_notification_options
    # without memberships
    assert_equal 5, User.find(7).valid_notification_options.size
    # with memberships
    assert_equal 6, User.find(2).valid_notification_options.size
  end

  def test_valid_notification_options_class_method
    assert_equal 5, User.valid_notification_options.size
    assert_equal 5, User.valid_notification_options(User.find(7)).size
    assert_equal 6, User.valid_notification_options(User.find(2)).size
  end

  def test_mail_notification_all
    @jsmith.mail_notification = 'all'
    @jsmith.notified_project_ids = []
    @jsmith.save
    @jsmith.reload
    assert @jsmith.projects.first.recipients.include?(@jsmith.mail)
  end

  def test_mail_notification_selected
    @jsmith.mail_notification = 'selected'
    @jsmith.notified_project_ids = [1]
    @jsmith.save
    @jsmith.reload
    assert Project.find(1).recipients.include?(@jsmith.mail)
  end

  def test_mail_notification_only_my_events
    @jsmith.mail_notification = 'only_my_events'
    @jsmith.notified_project_ids = []
    @jsmith.save
    @jsmith.reload
    assert !@jsmith.projects.first.recipients.include?(@jsmith.mail)
  end

  def test_comments_sorting_preference
    assert !@jsmith.wants_comments_in_reverse_order?
    @jsmith.pref.comments_sorting = 'asc'
    assert !@jsmith.wants_comments_in_reverse_order?
    @jsmith.pref.comments_sorting = 'desc'
    assert @jsmith.wants_comments_in_reverse_order?
  end

  def test_find_by_mail_should_be_case_insensitive
    u = User.find_by_mail('JSmith@somenet.foo')
    assert_not_nil u
    assert_equal 'jsmith@somenet.foo', u.mail
  end

  context "#allowed_to?" do
    context "with a unique project" do
      should "return false if project is archived" do
        project = Project.find(1)
        Project.any_instance.stub(:status).and_return(Project::STATUS_ARCHIVED)
        assert ! @admin.allowed_to?(:view_work_packages, Project.find(1))
      end

      should "return false if related module is disabled" do
        project = Project.find(1)
        project.enabled_module_names = ["work_package_tracking"]
        assert @admin.allowed_to?(:add_work_packages, project)
        assert ! @admin.allowed_to?(:view_wiki_pages, project)
      end

      should "authorize nearly everything for admin users" do
        project = Project.find(1)
        project.enabled_module_names = ["work_package_tracking", "news", "wiki", "repository"]
        assert ! @admin.member_of?(project)
        %w(edit_work_packages delete_work_packages manage_news manage_repository manage_wiki).each do |p|
          assert @admin.allowed_to?(p.to_sym, project)
        end
      end

      should "authorize normal users depending on their roles" do
        project = Project.find(1)
        project.enabled_module_names = ["boards"]
        assert @jsmith.allowed_to?(:delete_messages, project)    #Manager
        assert ! @dlopper.allowed_to?(:delete_messages, project) #Developper
      end

      should "only managers are allowed to export tickets" do
        project = Project.find(1)
        project.enabled_module_names = ["work_package_tracking"]
        assert @jsmith.allowed_to?(:export_work_packages, project)    #Manager
        assert ! @dlopper.allowed_to?(:export_work_packages, project) #Developper
      end
    end

    context "with multiple projects" do
      should "return false if array is empty" do
        assert ! @admin.allowed_to?(:view_project, [])
      end

      should "return true only if user has permission on all these projects" do
        Project.all.each do |project|
          project.enabled_module_names = ["work_package_tracking"]
          project.save!
        end

        assert @admin.allowed_to?(:view_project, Project.all)
        assert ! @dlopper.allowed_to?(:view_project, Project.all) #cannot see Project(2)
        assert @jsmith.allowed_to?(:edit_work_packages, @jsmith.projects) #Manager or Developer everywhere
        assert ! @jsmith.allowed_to?(:delete_work_package_watchers, @jsmith.projects) #Dev cannot delete_work_package_watchers
      end

      should "behave correctly with arrays of 1 project" do
        assert ! User.anonymous.allowed_to?(:delete_work_packages, [Project.first])
      end
    end

    context "with options[:global]" do
      should "authorize if user has at least one role that has this permission" do
        @dlopper2 = User.find(5) #only Developper on a project, not Manager anywhere
        @anonymous = User.find(6)
        assert @jsmith.allowed_to?(:delete_work_package_watchers, nil, :global => true)
        assert ! @dlopper2.allowed_to?(:delete_work_package_watchers, nil, :global => true)
        assert @dlopper2.allowed_to?(:add_work_packages, nil, :global => true)
        assert ! @anonymous.allowed_to?(:add_work_packages, nil, :global => true)
        assert @anonymous.allowed_to?(:view_work_packages, nil, :global => true)
      end
    end
  end

  context "User#notify_about?" do
    context "Issues" do
      setup do
        @project = Project.find(1)
        @author = User.generate_with_protected!
        @assignee = User.generate_with_protected!
        @issue = FactoryGirl.create(:work_package, project: @project, :assigned_to => @assignee, :author => @author)
      end

      should "be true for a user with :all" do
        @author.update_attribute(:mail_notification, 'all')
        assert @author.notify_about?(@issue)
      end

      should "be false for a user with :none" do
        @author.update_attribute(:mail_notification, 'none')
        assert ! @author.notify_about?(@issue)
      end

      should "be false for a user with :only_my_events and isn't an author, creator, or assignee" do
        @user = User.generate_with_protected!(:mail_notification => 'only_my_events')
        (Member.new.tap do |m|
          m.force_attributes = { :user => @user, :project => @project, :role_ids => [1] }
        end).save!
        assert ! @user.notify_about?(@issue)
      end

      should "be true for a user with :only_my_events and is the author" do
        @author.update_attribute(:mail_notification, 'only_my_events')
        assert @author.notify_about?(@issue)
      end

      should "be true for a user with :only_my_events and is the assignee" do
        @assignee.update_attribute(:mail_notification, 'only_my_events')
        assert @assignee.notify_about?(@issue)
      end

      should "be true for a user with :only_assigned and is the assignee" do
        @assignee.update_attribute(:mail_notification, 'only_assigned')
        assert @assignee.notify_about?(@issue)
      end

      should "be false for a user with :only_assigned and is not the assignee" do
        @author.update_attribute(:mail_notification, 'only_assigned')
        assert ! @author.notify_about?(@issue)
      end

      should "be true for a user with :only_owner and is the author" do
        @author.update_attribute(:mail_notification, 'only_owner')
        assert @author.notify_about?(@issue)
      end

      should "be false for a user with :only_owner and is not the author" do
        @assignee.update_attribute(:mail_notification, 'only_owner')
        assert ! @assignee.notify_about?(@issue)
      end

      should "be true for a user with :selected and is the author" do
        @author.update_attribute(:mail_notification, 'selected')
        assert @author.notify_about?(@issue)
      end

      should "be true for a user with :selected and is the assignee" do
        @assignee.update_attribute(:mail_notification, 'selected')
        assert @assignee.notify_about?(@issue)
      end

      should "be false for a user with :selected and is not the author or assignee" do
        @user = User.generate_with_protected!(:mail_notification => 'selected')
        (Member.new.tap do |m|
          m.force_attributes = { :user => @user, :project => @project, :role_ids => [1] }
        end).save!
        assert ! @user.notify_about?(@issue)
      end
    end

    context "other events" do
      should 'be added and tested'
    end
  end

end
