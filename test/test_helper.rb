# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')
require File.join(RAILS_ROOT,'test', 'mocks', 'open_id_authentication_mock.rb')

require File.expand_path(File.dirname(__FILE__) + '/object_daddy_helpers')
include ObjectDaddyHelpers

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...

  def log_user(login, password)
    User.anonymous
    get "/login"
    assert_equal nil, session[:user_id]
    assert_response :success
    assert_template "account/login"
    post "/login", :username => login, :password => password
    assert_equal login, User.find(session[:user_id]).login
  end

  def uploaded_test_file(name, mime)
    ActionController::TestUploadedFile.new(ActiveSupport::TestCase.fixture_path + "/files/#{name}", mime)
  end

  # Mock out a file
  def self.mock_file
    file = 'a_file.png'
    file.stubs(:size).returns(32)
    file.stubs(:original_filename).returns('a_file.png')
    file.stubs(:content_type).returns('image/png')
    file.stubs(:read).returns(false)
    file
  end

  def mock_file
    self.class.mock_file
  end

  # Use a temporary directory for attachment related tests
  def set_tmp_attachments_directory
    Dir.mkdir "#{RAILS_ROOT}/tmp/test" unless File.directory?("#{RAILS_ROOT}/tmp/test")
    Dir.mkdir "#{RAILS_ROOT}/tmp/test/attachments" unless File.directory?("#{RAILS_ROOT}/tmp/test/attachments")
    Attachment.storage_path = "#{RAILS_ROOT}/tmp/test/attachments"
  end

  def with_settings(options, &block)
    saved_settings = options.keys.inject({}) {|h, k| h[k] = Setting[k].dup; h}
    options.each {|k, v| Setting[k] = v}
    yield
    saved_settings.each {|k, v| Setting[k] = v}
  end

  def change_user_password(login, new_password)
    user = User.first(:conditions => {:login => login})
    user.password, user.password_confirmation = new_password, new_password
    user.save!
  end

  def self.ldap_configured?
    @test_ldap = Net::LDAP.new(:host => '127.0.0.1', :port => 389)
    return @test_ldap.bind
  rescue Exception => e
    # LDAP is not listening
    return nil
  end

  # Returns the path to the test +vendor+ repository
  def self.repository_path(vendor)
    File.join(RAILS_ROOT.gsub(%r{config\/\.\.}, ''), "/tmp/test/#{vendor.downcase}_repository")
  end

  # Returns true if the +vendor+ test repository is configured
  def self.repository_configured?(vendor)
    File.directory?(repository_path(vendor))
  end

  # Shoulda macros
  def self.should_render_404
    should_respond_with :not_found
    should_render_template 'common/404'
  end

  def self.should_have_before_filter(expected_method, options = {})
    should_have_filter('before', expected_method, options)
  end

  def self.should_have_after_filter(expected_method, options = {})
    should_have_filter('after', expected_method, options)
  end

  def self.should_have_filter(filter_type, expected_method, options)
    description = "have #{filter_type}_filter :#{expected_method}"
    description << " with #{options.inspect}" unless options.empty?

    should description do
      klass = "action_controller/filters/#{filter_type}_filter".classify.constantize
      expected = klass.new(:filter, expected_method.to_sym, options)
      assert_equal 1, @controller.class.filter_chain.select { |filter|
        filter.method == expected.method && filter.kind == expected.kind &&
        filter.options == expected.options && filter.class == expected.class
      }.size
    end
  end

  def self.should_show_the_old_and_new_values_for(prop_key, model, &block)
    context "" do
      setup do
        if block_given?
          instance_eval &block
        else
          @old_value = model.generate!
          @new_value = model.generate!
        end
      end

      should "use the new value's name" do
        @detail = IssueJournal.generate(:version => 1)
        @detail.update_attribute(:changes, {prop_key => [@old_value.id, @new_value.id]}.to_yaml)

        assert_match @new_value.name, @detail.render_detail(prop_key, true)
      end

      should "use the old value's name" do
        @detail = IssueJournal.generate(:version => 1)
        @detail.update_attribute(:changes, {prop_key => [@old_value.id, @new_value.id]}.to_yaml)

        assert_match @old_value.name, @detail.render_detail(prop_key, true)
      end
    end
  end

  def self.should_create_a_new_user(&block)
    should "create a new user" do
      user = instance_eval &block
      assert user
      assert_kind_of User, user
      assert !user.new_record?
    end
  end
end
