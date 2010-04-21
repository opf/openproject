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

require "#{File.dirname(__FILE__)}/../test_helper"

class IssuesApiTest < ActionController::IntegrationTest
  fixtures :projects,
    :users,
    :roles,
    :members,
    :member_roles,
    :issues,
    :issue_statuses,
    :versions,
    :trackers,
    :projects_trackers,
    :issue_categories,
    :enabled_modules,
    :enumerations,
    :attachments,
    :workflows,
    :custom_fields,
    :custom_values,
    :custom_fields_projects,
    :custom_fields_trackers,
    :time_entries,
    :journals,
    :journal_details,
    :queries

  def setup
    Setting.rest_api_enabled = '1'
  end
    
  def test_index
    get '/issues.xml'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
  end
  
  def test_index_with_filter
    get '/issues.xml?status_id=5'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    assert_tag :tag => 'issues',
               :children => { :count => Issue.visible.count(:conditions => {:status_id => 5}), 
                              :only => { :tag => 'issue' } }
  end
    
  def test_show
    get '/issues/1.xml'
    assert_response :success
    assert_equal 'application/xml', @response.content_type
  end
    
  def test_create
    attributes = {:project_id => 1, :subject => 'API test', :tracker_id => 2, :status_id => 3}
    assert_difference 'Issue.count' do
      post '/issues.xml', {:issue => attributes}, :authorization => credentials('jsmith')
    end
    assert_response :created
    assert_equal 'application/xml', @response.content_type
    issue = Issue.first(:order => 'id DESC')
    attributes.each do |attribute, value|
      assert_equal value, issue.send(attribute)
    end
  end
  
  def test_create_failure
    attributes = {:project_id => 1}
    assert_no_difference 'Issue.count' do
      post '/issues.xml', {:issue => attributes}, :authorization => credentials('jsmith')
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.content_type
    assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
  end
    
  def test_update
    attributes = {:subject => 'API update'}
    assert_no_difference 'Issue.count' do
      assert_difference 'Journal.count' do
        put '/issues/1.xml', {:issue => attributes}, :authorization => credentials('jsmith')
      end
    end
    assert_response :ok
    assert_equal 'application/xml', @response.content_type
    issue = Issue.find(1)
    attributes.each do |attribute, value|
      assert_equal value, issue.send(attribute)
    end
  end
  
  def test_update_failure
    attributes = {:subject => ''}
    assert_no_difference 'Issue.count' do
      assert_no_difference 'Journal.count' do
        put '/issues/1.xml', {:issue => attributes}, :authorization => credentials('jsmith')
      end
    end
    assert_response :unprocessable_entity
    assert_equal 'application/xml', @response.content_type
    assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
  end
    
  def test_destroy
    assert_difference 'Issue.count', -1 do
      delete '/issues/1.xml', {}, :authorization => credentials('jsmith')
    end
    assert_response :ok
    assert_equal 'application/xml', @response.content_type
    assert_nil Issue.find_by_id(1)
  end
  
  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
