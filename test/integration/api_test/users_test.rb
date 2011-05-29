#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)
require 'pp'
class ApiTest::UsersTest < ActionController::IntegrationTest
  fixtures :users

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /users" do
    should_allow_api_authentication(:get, "/users.xml")
    should_allow_api_authentication(:get, "/users.json")
  end

  context "GET /users/2" do
    context ".xml" do
      should "return requested user" do
        get '/users/2.xml'
        
        assert_tag :tag => 'user',
          :child => {:tag => 'id', :content => '2'}
      end
    end

    context ".json" do
      should "return requested user" do
        get '/users/2.json'
        
        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Hash, json['user']
        assert_equal 2, json['user']['id']
      end
    end
  end
  
  context "GET /users/current" do
    context ".xml" do
      should "require authentication" do
        get '/users/current.xml'
        
        assert_response 401
      end
      
      should "return current user" do
        get '/users/current.xml', {}, :authorization => credentials('jsmith')
        
        assert_tag :tag => 'user',
          :child => {:tag => 'id', :content => '2'}
      end
    end
  end

  context "POST /users" do
    context "with valid parameters" do
      setup do
        @parameters = {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net', :password => 'secret', :mail_notification => 'only_assigned'}}
      end
      
      context ".xml" do
        should_allow_api_authentication(:post,
          '/users.xml',
          {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net', :password => 'secret'}},
          {:success_code => :created})
        
        should "create a user with the attributes" do
          assert_difference('User.count') do
            post '/users.xml', @parameters, :authorization => credentials('admin')
          end
          
          user = User.first(:order => 'id DESC')
          assert_equal 'foo', user.login
          assert_equal 'Firstname', user.firstname
          assert_equal 'Lastname', user.lastname
          assert_equal 'foo@example.net', user.mail
          assert_equal 'only_assigned', user.mail_notification
          assert !user.admin?
          assert user.check_password?('secret')
          
          assert_response :created
          assert_equal 'application/xml', @response.content_type
          assert_tag 'user', :child => {:tag => 'id', :content => user.id.to_s}
        end
      end
      
      context ".json" do
        should_allow_api_authentication(:post,
          '/users.json',
          {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net'}},
          {:success_code => :created})
        
        should "create a user with the attributes" do
          assert_difference('User.count') do
            post '/users.json', @parameters, :authorization => credentials('admin')
          end
          
          user = User.first(:order => 'id DESC')
          assert_equal 'foo', user.login
          assert_equal 'Firstname', user.firstname
          assert_equal 'Lastname', user.lastname
          assert_equal 'foo@example.net', user.mail
          assert !user.admin?
          
          assert_response :created
          assert_equal 'application/json', @response.content_type
          json = ActiveSupport::JSON.decode(response.body)
          assert_kind_of Hash, json
          assert_kind_of Hash, json['user']
          assert_equal user.id, json['user']['id']
        end
      end
    end
    
    context "with invalid parameters" do
      setup do
        @parameters = {:user => {:login => 'foo', :lastname => 'Lastname', :mail => 'foo'}}
      end
      
      context ".xml" do
        should "return errors" do
          assert_no_difference('User.count') do
            post '/users.xml', @parameters, :authorization => credentials('admin')
          end
            
          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "First name can't be blank"}
        end
      end
      
      context ".json" do
        should "return errors" do
          assert_no_difference('User.count') do
            post '/users.json', @parameters, :authorization => credentials('admin')
          end
            
          assert_response :unprocessable_entity
          assert_equal 'application/json', @response.content_type
          json = ActiveSupport::JSON.decode(response.body)
          assert_kind_of Hash, json
          assert json.has_key?('errors')
          assert_kind_of Array, json['errors']
        end
      end
    end
  end

  context "PUT /users/2" do
    context "with valid parameters" do
      setup do
        @parameters = {:user => {:login => 'jsmith', :firstname => 'John', :lastname => 'Renamed', :mail => 'jsmith@somenet.foo'}}
      end
      
      context ".xml" do
        should_allow_api_authentication(:put,
          '/users/2.xml',
          {:user => {:login => 'jsmith', :firstname => 'John', :lastname => 'Renamed', :mail => 'jsmith@somenet.foo'}},
          {:success_code => :ok})
        
        should "update user with the attributes" do
          assert_no_difference('User.count') do
            put '/users/2.xml', @parameters, :authorization => credentials('admin')
          end
          
          user = User.find(2)
          assert_equal 'jsmith', user.login
          assert_equal 'John', user.firstname
          assert_equal 'Renamed', user.lastname
          assert_equal 'jsmith@somenet.foo', user.mail
          assert !user.admin?
          
          assert_response :ok
        end
      end
      
      context ".json" do
        should_allow_api_authentication(:put,
          '/users/2.json',
          {:user => {:login => 'jsmith', :firstname => 'John', :lastname => 'Renamed', :mail => 'jsmith@somenet.foo'}},
          {:success_code => :ok})
        
        should "update user with the attributes" do
          assert_no_difference('User.count') do
            put '/users/2.json', @parameters, :authorization => credentials('admin')
          end
          
          user = User.find(2)
          assert_equal 'jsmith', user.login
          assert_equal 'John', user.firstname
          assert_equal 'Renamed', user.lastname
          assert_equal 'jsmith@somenet.foo', user.mail
          assert !user.admin?
          
          assert_response :ok
        end
      end
    end
    
    context "with invalid parameters" do
      setup do
        @parameters = {:user => {:login => 'jsmith', :firstname => '', :lastname => 'Lastname', :mail => 'foo'}}
      end
      
      context ".xml" do
        should "return errors" do
          assert_no_difference('User.count') do
            put '/users/2.xml', @parameters, :authorization => credentials('admin')
          end
            
          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "First name can't be blank"}
        end
      end
      
      context ".json" do
        should "return errors" do
          assert_no_difference('User.count') do
            put '/users/2.json', @parameters, :authorization => credentials('admin')
          end
            
          assert_response :unprocessable_entity
          assert_equal 'application/json', @response.content_type
          json = ActiveSupport::JSON.decode(response.body)
          assert_kind_of Hash, json
          assert json.has_key?('errors')
          assert_kind_of Array, json['errors']
        end
      end
    end
    
    context "DELETE /users/2" do
      context ".xml" do
        should "not be allowed" do
          assert_no_difference('User.count') do
            delete '/users/2.xml'
          end
          
          assert_response :method_not_allowed
        end
      end
      
      context ".json" do
        should "not be allowed" do
          assert_no_difference('User.count') do
            delete '/users/2.json'
          end
          
          assert_response :method_not_allowed
        end
      end
    end
  end
  
  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
