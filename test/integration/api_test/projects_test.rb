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

class ApiTest::ProjectsTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /api/v1/projects" do
    context ".xml" do
      should "return projects" do
        get '/api/v1/projects.xml'
        assert_response :success
        assert_equal 'application/xml', @response.content_type

        assert_tag :tag => 'projects',
          :child => {:tag => 'project', :child => {:tag => 'id', :content => '1'}}
      end
    end

    context ".json" do
      should "return projects" do
        get '/api/v1/projects.json'
        assert_response :success
        assert_equal 'application/json', @response.content_type

        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Array, json['projects']
        assert_kind_of Hash, json['projects'].first
        assert json['projects'].first.has_key?('id')
      end
    end
  end

  context "GET /api/v1/projects/:id" do
    context ".xml" do
      # TODO: A private project is needed because should_allow_api_authentication
      # actually tests that authentication is *required*, not just allowed
      should_allow_api_authentication(:get, "/api/v1/projects/2.xml")

      should "return requested project" do
        get '/api/v1/projects/1.xml'
        assert_response :success
        assert_equal 'application/xml', @response.content_type

        assert_tag :tag => 'project',
          :child => {:tag => 'id', :content => '1'}
        assert_tag :tag => 'custom_field',
          :attributes => {:name => 'Development status'}, :content => 'Stable'
      end

      context "with hidden custom fields" do
        setup do
          ProjectCustomField.find_by_name('Development status').update_attribute :visible, false
        end

        should "not display hidden custom fields" do
          get '/api/v1/projects/1.xml'
          assert_response :success
          assert_equal 'application/xml', @response.content_type

          assert_no_tag 'custom_field',
            :attributes => {:name => 'Development status'}
        end
      end
    end

    context ".json" do
      should_allow_api_authentication(:get, "/api/v1/projects/2.json")

      should "return requested project" do
        get '/api/v1/projects/1.json'

        json = ActiveSupport::JSON.decode(response.body)
        assert_kind_of Hash, json
        assert_kind_of Hash, json['project']
        assert_equal 1, json['project']['id']
      end
    end
  end

  context "POST /api/v1/projects" do
    context "with valid parameters" do
      setup do
        Setting.default_projects_modules = ['issue_tracking', 'repository']
        @parameters = {:project => {:name => 'API test', :identifier => 'api-test'}}
      end

      context ".xml" do
        should_allow_api_authentication(:post,
                                        '/api/v1/projects.xml',
                                        {:project => {:name => 'API test', :identifier => 'api-test'}},
                                        {:success_code => :created})


        should "create a project with the attributes" do
          assert_difference('Project.count') do
            post '/api/v1/projects.xml', @parameters, credentials('admin')
          end

          project = Project.first(:order => 'id DESC')
          assert_equal 'API test', project.name
          assert_equal 'api-test', project.identifier
          assert_equal ['issue_tracking', 'repository'], project.enabled_module_names.sort
          assert_equal Type.all.size, project.types.size

          assert_response :created
          assert_equal 'application/xml', @response.content_type
          assert_tag 'project', :child => {:tag => 'id', :content => project.id.to_s}
        end

        should "accept enabled_module_names attribute" do
          @parameters[:project].merge!({:enabled_module_names => ['issue_tracking', 'news', 'time_tracking']})

          assert_difference('Project.count') do
            post '/api/v1/projects.xml', @parameters, credentials('admin')
          end

          project = Project.first(:order => 'id DESC')
          assert_equal ['issue_tracking', 'news', 'time_tracking'], project.enabled_module_names.sort
        end

        should "accept type_ids attribute" do
          @parameters[:project].merge!({:type_ids => [1, 3]})

          assert_difference('Project.count') do
            post '/api/v1/projects.xml', @parameters, credentials('admin')
          end

          project = Project.first(:order => 'id DESC')
          assert_equal [1, 3], project.types.map(&:id).sort
        end
      end
    end

    context "with invalid parameters" do
      setup do
        @parameters = {:project => {:name => 'API test'}}
      end

      context ".xml" do
        should "return errors" do
          assert_no_difference('Project.count') do
            post '/api/v1/projects.xml', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "Identifier can't be blank"}
        end
      end
    end
  end

  context "PUT /api/v1/projects/:id" do
    context "with valid parameters" do
      setup do
        @parameters = {:project => {:name => 'API update'}}
      end

      context ".xml" do
        should_allow_api_authentication(:put,
                                        '/api/v1/projects/2.xml',
                                        {:project => {:name => 'API update'}},
                                        {:success_code => :ok})

        should "update the project" do
          assert_no_difference 'Project.count' do
            put '/api/v1/projects/2.xml', @parameters, credentials('jsmith')
          end
          assert_response :ok
          assert_equal 'application/xml', @response.content_type
          project = Project.find(2)
          assert_equal 'API update', project.name
        end

        should "accept enabled_module_names attribute" do
          @parameters[:project].merge!({:enabled_module_names => ['issue_tracking', 'news', 'time_tracking']})

          assert_no_difference 'Project.count' do
            put '/api/v1/projects/2.xml', @parameters, credentials('admin')
          end
          assert_response :ok
          project = Project.find(2)
          assert_equal ['issue_tracking', 'news', 'time_tracking'], project.enabled_module_names.sort
        end

        should "accept type_ids attribute" do
          @parameters[:project].merge!({:type_ids => [1, 3]})

          assert_no_difference 'Project.count' do
            put '/api/v1/projects/2.xml', @parameters, credentials('admin')
          end
          assert_response :ok
          project = Project.find(2)
          assert_equal [1, 3], project.types.map(&:id).sort
        end
      end
    end

    context "with invalid parameters" do
      setup do
        @parameters = {:project => {:name => ''}}
      end

      context ".xml" do
        should "return errors" do
          assert_no_difference('Project.count') do
            put '/api/v1/projects/2.xml', @parameters, credentials('admin')
          end

          assert_response :unprocessable_entity
          assert_equal 'application/xml', @response.content_type
          assert_tag 'errors', :child => {:tag => 'error', :content => "Name can't be blank"}
        end
      end
    end
  end

  context "DELETE /api/v1/projects/:id" do
    context ".xml" do
      should_allow_api_authentication(:delete,
                                      '/api/v1/projects/2.xml',
                                      {},
                                      {:success_code => :ok})

      should "delete the project" do
        assert_difference('Project.count',-1) do
          delete '/api/v1/projects/2.xml', {}, credentials('admin')
        end
        assert_response :ok
        assert_nil Project.find_by_id(2)
      end
    end
  end
end
