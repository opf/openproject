# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

require "#{File.dirname(__FILE__)}/../../test_helper"

class ApiTest::ProjectsTest < ActionController::IntegrationTest
  fixtures :projects, :versions, :users, :roles, :members, :member_roles, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses, :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries

  def setup
    Setting.rest_api_enabled = '1'
  end
    
  def test_index
    get '/projects.xml'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
  end
    
  def test_show
    get '/projects/1.xml'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    assert_tag 'custom_field', :attributes => {:name => 'Development status'}, :content => 'Stable'
  end
    
  def test_show_should_not_display_hidden_custom_fields
    ProjectCustomField.find_by_name('Development status').update_attribute :visible, false
    get '/projects/1.xml'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    assert_no_tag 'custom_field', :attributes => {:name => 'Development status'}
  end
  
  context "POST /projects.xml" do
    should_allow_api_authentication(:post,
                                    '/projects.xml',
                                    {:project => {:name => 'API test', :identifier => 'api-test'}},
                                    {:success_code => :created})

    should "create a project with the attributes" do
      assert_difference('Project.count') do
        post '/projects.xml', {:project => {:name => 'API test', :identifier => 'api-test'}}, :authorization => credentials('admin')
      end
  
      project = Project.first(:order => 'id DESC')
      assert_equal 'API test', project.name
      assert_equal 'api-test', project.identifier
  
      assert_response :created
      assert_equal 'application/xml', @response.content_type
      assert_tag 'project', :child => {:tag => 'id', :content => project.id.to_s}
    end
  end
  
  def test_create_failure
    attributes = {:name => 'API test'}
    assert_no_difference 'Project.count' do
      post '/projects.xml', {:project => attributes}, :authorization => credentials('admin')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.content_type
    assert_tag :errors, :child => {:tag => 'error', :content => "Identifier can't be blank"}
  end
    
  def test_update
    attributes = {:name => 'API update'}
    assert_no_difference 'Project.count' do
      put '/projects/1.xml', {:project => attributes}, :authorization => credentials('jsmith')
    end
    assert_response :ok
    assert_equal 'application/xml', @response.content_type
    project = Project.find(1)
    attributes.each do |attribute, value|
      assert_equal value, project.send(attribute)
    end
  end
  
  def test_update_failure
    attributes = {:name => ''}
    assert_no_difference 'Project.count' do
      put '/projects/1.xml', {:project => attributes}, :authorization => credentials('jsmith')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.content_type
    assert_tag :errors, :child => {:tag => 'error', :content => "Name can't be blank"}
  end
    
  def test_destroy
    assert_difference 'Project.count', -1 do
      delete '/projects/2.xml', {}, :authorization => credentials('admin')
    end
    assert_response :ok
    assert_equal 'application/xml', @response.content_type
    assert_nil Project.find_by_id(2)
  end
  
  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
