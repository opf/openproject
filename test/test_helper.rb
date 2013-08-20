#-- encoding: UTF-8
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

ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'fileutils'

require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')
require Rails.root.join('test/mocks/open_id_authentication_mock.rb')

require File.expand_path(File.dirname(__FILE__) + '/object_daddy_helpers')
include ObjectDaddyHelpers


class ActionDispatch::IntegrationTest
  include Shoulda::Matchers::ActionController
  extend Shoulda::Matchers::ActionController

  def subject
    @controller
  end
end

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

  # included in order to use #fixture_file_upload
  include ActionDispatch::TestProcess

  # Add more helper methods to be used by all tests here...
  def setup
    super
    Rails.cache.clear
    # Ugly H4X to convince postgresql to update its sequences after bulk loading fixtures
    # TODO: remove this when we got rid of the fixtures
    ActiveRecord::Base.descendants.each do |model|
      if model.table_name \
         and defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) \
         and ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
      end
    end
  end

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
    # Shortcut for ActionController::TestUploadedFile.new(ActionController::TestCase.fixture_path + path, type):
    fixture_file_upload("/files/#{name}", mime, true)
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

  def save_and_open_page
    body = @response.body

    body.gsub!('/assets', '../../public/assets')

    FileUtils.mkdir_p(Rails.root.join('tmp/pages'))

    page_path = Rails.root.join("tmp/pages/#{SecureRandom.hex(16)}.html").to_s
    File.open(page_path, 'w') { |f| f.write(body) }

    Launchy.open(page_path)

    begin
      binding.pry
    rescue NoMethodError
      debugger
    end

    FileUtils.rm(page_path)
  end

  # Use a temporary directory for attachment related tests
  def set_tmp_attachments_directory
    attachments_path = Rails.root.join('tmp/test/attachments')
    FileUtils.mkdir_p(attachments_path)
    Attachment.storage_path = attachments_path.to_s
  end

  def with_settings(options, &block)
    saved_settings = options.keys.inject({}) {|h, k| h[k] = Setting[k].dup; h}
    options.each {|k, v| Setting[k] = v}
    yield
  ensure
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
    File.join(Rails.root.to_s.gsub(%r{config\/\.\.}, ''), "/tmp/test/#{vendor.downcase}_repository")
  end

  # Returns the url of the subversion test repository
  def self.subversion_repository_url
    path = repository_path('subversion')
    path = '/' + path unless path.starts_with?('/')
    "file://#{path}"
  end

  # Returns true if the +vendor+ test repository is configured
  def self.repository_configured?(vendor)
    File.directory?(repository_path(vendor))
  end

  def assert_error_tag(options={})
    assert_tag({:attributes => { :id => 'errorExplanation' }}.merge(options))
  end

  # Shoulda macros
  def self.should_assign_to(variable, &block)
    should "assign the instance variable '#{variable}'" do
      assert @controller.instance_variables.map(&:to_s).include?("@#{variable}")
      if block
        expected_result = instance_eval(&block)
        assert_equal @controller.instance_variable_get('@' + variable.to_s), expected_result
      end
    end
  end

  def self.should_render_404
    should respond_with :not_found
    should render_template 'common/error'
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
        FactoryGirl.create :issue if Issue.count == 0 # some tests use Issue.last
        if block_given?
          instance_eval &block
        else
          @old_value = model.generate!
          @new_value = model.generate!
        end
      end

      should "use the new value's name" do
        journal = FactoryGirl.build :work_package_journal

        journal.stubs(:journable).returns(Issue.last)
        journal.stubs(:details).returns({prop_key => [@old_value.id, @new_value.id]})

        assert_match @new_value.class.find(@new_value.id).name, journal.render_detail(prop_key, :no_html => true)
      end

      should "use the old value's name" do
        journal = FactoryGirl.build :work_package_journal

        journal.stubs(:journable).returns(Issue.last)
        journal.stubs(:details).returns({prop_key => [@old_value.id, @new_value.id]})

        assert_match @old_value.class.find(@old_value.id).name, journal.render_detail(prop_key, :no_html => true)
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

  def self.should_respond_with_content_type(content_type)
    should "respond with content type '#{content_type}'" do
      assert_equal @response.content_type, content_type
    end
  end

  def credentials(login, password = nil)
    if password.nil?
      password = (login == 'admin' ? 'adminADMIN!' : login)
    end
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(login, password) }
  end


  # Test that a request allows the three types of API authentication
  #
  # * HTTP Basic with username and password
  # * HTTP Basic with an api key for the username
  # * Key based with the key=X parameter
  #
  # @param [Symbol] http_method the HTTP method for request (:get, :post, :put, :delete)
  # @param [String] url the request url
  # @param [optional, Hash] parameters additional request parameters
  # @param [optional, Hash] options additional options
  # @option options [Symbol] :success_code Successful response code (:success)
  # @option options [Symbol] :failure_code Failure response code (:unauthorized)
  def self.should_allow_api_authentication(http_method, url, parameters={}, options={})
    should_allow_http_basic_auth_with_username_and_password(http_method, url, parameters, options)
    should_allow_http_basic_auth_with_key(http_method, url, parameters, options)
    should_allow_key_based_auth(http_method, url, parameters, options)
  end

  # Test that a request allows the username and password for HTTP BASIC
  #
  # @param [Symbol] http_method the HTTP method for request (:get, :post, :put, :delete)
  # @param [String] url the request url
  # @param [optional, Hash] options additional options
  # @option options [Symbol] :success_code Successful response code (:success)
  # @option options [Symbol] :failure_code Failure response code (:unauthorized)
  def self.should_send_correct_authentication_scheme_when_header_authentication_scheme_is_session(http_method, url, options = {}, parameters = {})
    success_code = options[:success_code] || :success
    failure_code = options[:failure_code] || :unauthorized

    context "should not send www authenticate when header accept auth is session #{http_method} #{url}" do
      context "without credentials" do
        setup do
          send(http_method, url, parameters, { "X-Authentication-Scheme" => "Session" })
        end

        should respond_with failure_code
        should_respond_with_content_type_based_on_url(url)
        should "include correct www_authenticate_header" do
          # the 3.0.9 implementation of head leads to Www as the method capitalizes each
          # word split by a hyphen.
          # this is fixed in 3.1.0 http://apidock.com/rails/v3.1.0/ActionController/Head/head
          # remove this switch once on 3.1.0
          if ::Rails::VERSION::MAJOR == 3 && ::Rails::VERSION::MINOR == 0
            assert @controller.response.headers.has_key?('Www-Authenticate')
            assert_equal 'Session realm="OpenProject API"', @controller.response.headers['Www-Authenticate']
          else
            assert @controller.response.headers.has_key?('WWW-Authenticate')
            assert_equal 'Session realm="OpenProject API"', @controller.response.headers['WWW-Authenticate']
          end
        end
      end
    end

  end

  # Test that a request allows the username and password for HTTP BASIC
  #
  # @param [Symbol] http_method the HTTP method for request (:get, :post, :put, :delete)
  # @param [String] url the request url
  # @param [optional, Hash] parameters additional request parameters
  # @param [optional, Hash] options additional options
  # @option options [Symbol] :success_code Successful response code (:success)
  # @option options [Symbol] :failure_code Failure response code (:unauthorized)
  def self.should_allow_http_basic_auth_with_username_and_password(http_method, url, parameters={}, options={})
    success_code = options[:success_code] || :success
    failure_code = options[:failure_code] || :unauthorized

    context "should allow http basic auth using a username and password for #{http_method} #{url}" do
      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'adminADMIN!', :password_confirmation => 'adminADMIN!', :admin => true) # Admin so they can access the project

          send(http_method, url, parameters, credentials(@user.login, 'adminADMIN!'))
        end

        should respond_with success_code
        should_respond_with_content_type_based_on_url(url)
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!

          send(http_method, url, parameters, credentials(@user.login, 'wrong_password'))
        end

        should respond_with failure_code
        should_respond_with_content_type_based_on_url(url)
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "without credentials" do
        setup do
          send(http_method, url, parameters)
        end

        should respond_with failure_code
        should_respond_with_content_type_based_on_url(url)
        should "include_www_authenticate_header" do
          # the 3.0.9 implementation of head leads to Www as the method capitalizes each
          # word split by a hyphen.
          # this is fixed in 3.1.0 http://apidock.com/rails/v3.1.0/ActionController/Head/head
          # remove this switch once on 3.1.0
          if ::Rails::VERSION::MAJOR == 3 && ::Rails::VERSION::MINOR == 0
            assert @controller.response.headers.has_key?('Www-Authenticate')
          else
            assert @controller.response.headers.has_key?('WWW-Authenticate')
          end
        end
      end
    end

  end

  # Test that a request allows the API key with HTTP BASIC
  #
  # @param [Symbol] http_method the HTTP method for request (:get, :post, :put, :delete)
  # @param [String] url the request url
  # @param [optional, Hash] parameters additional request parameters
  # @param [optional, Hash] options additional options
  # @option options [Symbol] :success_code Successful response code (:success)
  # @option options [Symbol] :failure_code Failure response code (:unauthorized)
  def self.should_allow_http_basic_auth_with_key(http_method, url, parameters={}, options={})
    success_code = options[:success_code] || :success
    failure_code = options[:failure_code] || :unauthorized

    context "should allow http basic auth with a key for #{http_method} #{url}" do
      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!(:admin => true)
          @token = Token.generate!(:user => @user, :action => 'api')

          send(http_method, url, parameters, credentials(@token.value, 'X'))
        end

        should respond_with success_code
        should_respond_with_content_type_based_on_url(url)
        should_be_a_valid_response_string_based_on_url(url)
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'feeds')

          send(http_method, url, parameters, credentials(@token.value, 'X'))
        end

        should respond_with failure_code
        should_respond_with_content_type_based_on_url(url)
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end
    end
  end

  # Test that a request allows full key authentication
  #
  # @param [Symbol] http_method the HTTP method for request (:get, :post, :put, :delete)
  # @param [String] url the request url, without the key=ZXY parameter
  # @param [optional, Hash] parameters additional request parameters
  # @param [optional, Hash] options additional options
  # @option options [Symbol] :success_code Successful response code (:success)
  # @option options [Symbol] :failure_code Failure response code (:unauthorized)
  def self.should_allow_key_based_auth(http_method, url, parameters={}, options={})
    success_code = options[:success_code] || :success
    failure_code = options[:failure_code] || :unauthorized

    context "should allow key based auth using key=X for #{http_method} #{url}" do
      context "with a valid api token" do
        setup do
          @user = User.generate_with_protected!(:admin => true)
          @token = Token.generate!(:user => @user, :action => 'api')
          # Simple url parse to add on ?key= or &key=
          request_url = if url.match(/\?/)
                          url + "&key=#{@token.value}"
                        else
                          url + "?key=#{@token.value}"
                        end
          send(http_method, request_url, parameters)
        end

        should respond_with success_code
        should_respond_with_content_type_based_on_url(url)
        should_be_a_valid_response_string_based_on_url(url)
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'feeds')
          # Simple url parse to add on ?key= or &key=
          request_url = if url.match(/\?/)
                          url + "&key=#{@token.value}"
                        else
                          url + "?key=#{@token.value}"
                        end
          send(http_method, request_url, parameters)
        end

        should respond_with failure_code
        should_respond_with_content_type_based_on_url(url)
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end
    end

    context "should allow key based auth using X-OpenProject-API-Key header for #{http_method} #{url}" do
      setup do
        @user = User.generate_with_protected!(:admin => true)
        @token = Token.generate!(:user => @user, :action => 'api')
        send(http_method, url, parameters, {'X-OpenProject-API-Key' => @token.value.to_s})
      end

      should respond_with success_code
      should_respond_with_content_type_based_on_url(url)
      should_be_a_valid_response_string_based_on_url(url)
      should "login as the user" do
        assert_equal @user, User.current
      end
    end
  end

  # Uses should_respond_with_content_type based on what's in the url:
  #
  # '/project/issues.xml' => should_respond_with_content_type :xml
  # '/project/issues.json' => should_respond_with_content_type :json
  #
  # @param [String] url Request
  def self.should_respond_with_content_type_based_on_url(url)
    case
    when url.match(/xml/i)
      should_respond_with_content_type 'application/xml'
    when url.match(/json/i)
      should_respond_with_content_type 'application/json'
    else
      raise "Unknown content type for should_respond_with_content_type_based_on_url: #{url}"
    end
  end

  # Uses the url to assert which format the response should be in
  #
  # '/project/issues.xml' => should_be_a_valid_xml_string
  # '/project/issues.json' => should_be_a_valid_json_string
  #
  # @param [String] url Request
  def self.should_be_a_valid_response_string_based_on_url(url)
    case
    when url.match(/xml/i)
      should_be_a_valid_xml_string
    when url.match(/json/i)
      should_be_a_valid_json_string
    else
      raise "Unknown content type for should_be_a_valid_response_based_on_url: #{url}"
    end

  end

  # Checks that the response is a valid JSON string
  def self.should_be_a_valid_json_string
    should "be a valid JSON string (or empty)" do
      assert(response.body.blank? || ActiveSupport::JSON.decode(response.body))
    end
  end

  # Checks that the response is a valid XML string
  def self.should_be_a_valid_xml_string
    should "be a valid XML string" do
      assert REXML::Document.new(response.body)
    end
  end

end

# Simple module to "namespace" all of the API tests
module ApiTest
end
