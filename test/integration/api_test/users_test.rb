#-- encoding: UTF-8
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
require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::UsersTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /api/v1/users" do
    should_allow_api_authentication(:get, "/api/v1/users.xml")
    should_allow_api_authentication(:get, "/api/v1/users.json")
  end

  context "GET /api/v1/users/2" do
    context ".xml" do
      should "return requested user" do
        get '/api/v1/users/2.xml', {}, credentials('admin')

        assert_tag :tag => 'user',
          :child => {:tag => 'id', :content => '2'}
      end
    end

    context ".json" do
      should "return requested user" do
        get '/api/v1/users/2.json', {}, credentials('admin')

        json = ActiveSupport::JSON.decode(@response.body)
        assert_kind_of Hash, json
        assert_kind_of Hash, json['user']
        assert_equal 2, json['user']['id']
      end
    end
  end

  context "GET /api/v1/users/current" do
    context ".xml" do
      should "require authentication" do
        get '/api/v1/users/current.xml'

        assert_response 401
      end

      should "return current user" do
        get '/api/v1/users/current.xml', {}, credentials('jsmith')

        assert_tag :tag => 'user',
          :child => {:tag => 'id', :content => '2'}
      end
    end
  end

  context "POST /api/v1/users" do
    context "with valid parameters" do
      setup do
        @parameters = {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net', :password => 'adminADMIN!', :mail_notification => 'only_assigned'}}
      end

      context ".xml" do
        should_allow_api_authentication(:post,
          '/api/v1/users.xml',
          {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net', :password => 'adminADMIN!'}},
          {:success_code => :created})

        should "create a user with the attributes" do
          assert_difference('User.count') do
            post '/api/v1/users.xml', @parameters, credentials('admin')
          end

          user = User.first(:order => 'id DESC')
          assert_equal 'foo', user.login
          assert_equal 'Firstname', user.firstname
          assert_equal 'Lastname', user.lastname
          assert_equal 'foo@example.net', user.mail
          assert_equal 'only_assigned', user.mail_notification
          assert !user.admin?
          assert user.check_password?('adminADMIN!')

          assert_response :created
          assert_equal 'application/xml', @response.content_type
          assert_tag 'user', :child => {:tag => 'id', :content => user.id.to_s}
        end
      end

      context ".json" do
        should_allow_api_authentication(:post,
          '/api/v1/users.json',
          {:user => {:login => 'foo', :firstname => 'Firstname', :lastname => 'Lastname', :mail => 'foo@example.net'}},
          {:success_code => :created})

        should "create a user with the attributes" do
          assert_difference('User.count') do
            post '/api/v1/users.json', @parameters, credentials('admin')
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
            post '/api/v1/users.xml', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "First name can't be blank"}
        end
      end

      context ".json" do
        should "return errors" do
          assert_no_difference('User.count') do
            post '/api/v1/users.json', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/json', @response.content_type
          json = ActiveSupport::JSON.decode(response.body)
          assert_kind_of Hash, json
          assert json.has_key?('errors')
          assert_equal({ "firstname" => ["can't be blank"], "mail" => ["is invalid"] }, json['errors'])
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
          '/api/v1/users/2.xml',
          {:user => {:login => 'jsmith', :firstname => 'John', :lastname => 'Renamed', :mail => 'jsmith@somenet.foo'}},
          {:success_code => :ok})

        should "update user with the attributes" do
          assert_no_difference('User.count') do
            put '/api/v1/users/2.xml', @parameters, credentials('admin')
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
          '/api/v1/users/2.json',
          {:user => {:login => 'jsmith', :firstname => 'John', :lastname => 'Renamed', :mail => 'jsmith@somenet.foo'}},
          {:success_code => :ok})

        should "update user with the attributes" do
          assert_no_difference('User.count') do
            put '/api/v1/users/2.json', @parameters, credentials('admin')
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
            put '/api/v1/users/2.xml', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "First name can't be blank"}
        end
      end

      context ".json" do
        should "return errors" do
          assert_no_difference('User.count') do
            put '/api/v1/users/2.json', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/json', @response.content_type
          json = ActiveSupport::JSON.decode(response.body)
          assert_kind_of Hash, json
          assert json.has_key?('errors')
          assert_equal({ "firstname" => ["can't be blank"], "mail" => ["is invalid"] }, json['errors'])
        end
      end
    end
  end

  context "DELETE /api/v1/users/2" do
    setup do
      Setting.users_deletable_by_admins = "1"
      # setup deleted user to not tamper with the count
      # as the deleted user gets created lazily when it is required
      # which it is for the first time when deleting a user
      DeletedUser.first
    end

    context ".xml" do
      should_allow_api_authentication(:delete,
                                      '/api/v1/users/2.xml',
                                      {},
                                      {:success_code => :ok})


      should "delete user" do
        assert_difference('User.count', -1) do
          delete '/api/v1/users/2.xml', {}, credentials('admin')
        end

        assert_response :ok
        assert_equal ' ', @response.body
      end
    end


    context ".json" do
      should_allow_api_authentication(:delete,
                                      '/api/v1/users/2.json',
                                      {},
                                      {:success_code => :ok})

      should "delete user" do
        assert_difference('User.count', -1) do
          delete '/api/v1/users/2.json', {}, credentials('admin')
        end

        assert_response :ok
        assert_equal ' ', @response.body
      end
    end
  end
end
