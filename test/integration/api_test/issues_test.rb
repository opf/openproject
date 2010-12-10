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

class ApiTest::IssuesTest < ActionController::IntegrationTest
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

  # Use a private project to make sure auth is really working and not just
  # only showing public issues.
  context "/index.xml" do
    should_allow_api_authentication(:get, "/projects/private-child/issues.xml")
  end

  context "/index.json" do
    should_allow_api_authentication(:get, "/projects/private-child/issues.json")
  end

  context "/index.xml with filter" do
    should_allow_api_authentication(:get, "/projects/private-child/issues.xml?status_id=5")

    should "show only issues with the status_id" do
      get '/issues.xml?status_id=5'
      assert_tag :tag => 'issues',
                 :children => { :count => Issue.visible.count(:conditions => {:status_id => 5}), 
                                :only => { :tag => 'issue' } }
    end
  end

  context "/index.json with filter" do
    should_allow_api_authentication(:get, "/projects/private-child/issues.json?status_id=5")

    should "show only issues with the status_id" do
      get '/issues.json?status_id=5'

      json = ActiveSupport::JSON.decode(response.body)
      status_ids_used = json['issues'].collect {|j| j['status']['id'] }
      assert_equal 3, status_ids_used.length
      assert status_ids_used.all? {|id| id == 5 }
    end

  end

  # Issue 6 is on a private project
  context "/issues/6.xml" do
    should_allow_api_authentication(:get, "/issues/6.xml")
  end

  context "/issues/6.json" do
    should_allow_api_authentication(:get, "/issues/6.json")
  end
  
  context "GET /issues/:id" do
    context "with custom fields" do
      context ".xml" do
        should "display custom fields" do
          get '/issues/3.xml'
          
          assert_tag :tag => 'issue', 
            :child => {
              :tag => 'custom_fields',
              :attributes => { :type => 'array' },
              :child => {
                :tag => 'custom_field',
                :attributes => { :id => '1'},
                :child => {
                  :tag => 'value',
                  :content => 'MySQL'
                }
              }
            }
            
          assert_nothing_raised do
            Hash.from_xml(response.body).to_xml
          end
        end
      end
    end
    
    context "with subtasks" do
      setup do
        @c1 = Issue.generate!(:status_id => 1, :subject => "child c1", :tracker_id => 1, :project_id => 1, :parent_issue_id => 1)
        @c2 = Issue.generate!(:status_id => 1, :subject => "child c2", :tracker_id => 1, :project_id => 1, :parent_issue_id => 1)
        @c3 = Issue.generate!(:status_id => 1, :subject => "child c3", :tracker_id => 1, :project_id => 1, :parent_issue_id => @c1.id)
      end
      
      context ".xml" do
        should "display children" do
          get '/issues/1.xml'
          
          assert_tag :tag => 'issue', 
            :child => {
              :tag => 'children',
              :children => {:count => 2},
              :child => {
                :tag => 'issue',
                :attributes => {:id => @c1.id.to_s},
                :child => {
                  :tag => 'subject',
                  :content => 'child c1',
                  :sibling => {
                    :tag => 'children',
                    :children => {:count => 1},
                    :child => {
                      :tag => 'issue',
                      :attributes => {:id => @c3.id.to_s}
                    }
                  }
                }
              }
            }
        end
        
        context ".json" do
          should "display children" do
            get '/issues/1.json'
            
            json = ActiveSupport::JSON.decode(response.body)
            assert_equal([
              {
                'id' => @c1.id, 'subject' => 'child c1', 'tracker' => {'id' => 1, 'name' => 'Bug'},
                'children' => [{ 'id' => @c3.id, 'subject' => 'child c3', 'tracker' => {'id' => 1, 'name' => 'Bug'} }]
              },
              { 'id' => @c2.id, 'subject' => 'child c2', 'tracker' => {'id' => 1, 'name' => 'Bug'} }
              ],
              json['issue']['children'])
          end
        end
      end
    end
  end

  context "POST /issues.xml" do
    should_allow_api_authentication(:post,
                                    '/issues.xml',
                                    {:issue => {:project_id => 1, :subject => 'API test', :tracker_id => 2, :status_id => 3}},
                                    {:success_code => :created})

    should "create an issue with the attributes" do
      assert_difference('Issue.count') do
        post '/issues.xml', {:issue => {:project_id => 1, :subject => 'API test', :tracker_id => 2, :status_id => 3}}, :authorization => credentials('jsmith')
      end
        
      issue = Issue.first(:order => 'id DESC')
      assert_equal 1, issue.project_id
      assert_equal 2, issue.tracker_id
      assert_equal 3, issue.status_id
      assert_equal 'API test', issue.subject
  
      assert_response :created
      assert_equal 'application/xml', @response.content_type
      assert_tag 'issue', :child => {:tag => 'id', :content => issue.id.to_s}
    end
  end
  
  context "POST /issues.xml with failure" do
    should_allow_api_authentication(:post,
                                    '/issues.xml',
                                    {:issue => {:project_id => 1}},
                                    {:success_code => :unprocessable_entity})

    should "have an errors tag" do
      assert_no_difference('Issue.count') do
        post '/issues.xml', {:issue => {:project_id => 1}}, :authorization => credentials('jsmith')
      end

      assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
    end
  end

  context "POST /issues.json" do
    should_allow_api_authentication(:post,
                                    '/issues.json',
                                    {:issue => {:project_id => 1, :subject => 'API test', :tracker_id => 2, :status_id => 3}},
                                    {:success_code => :created})

    should "create an issue with the attributes" do
      assert_difference('Issue.count') do
        post '/issues.json', {:issue => {:project_id => 1, :subject => 'API test', :tracker_id => 2, :status_id => 3}}, :authorization => credentials('jsmith')
      end
        
      issue = Issue.first(:order => 'id DESC')
      assert_equal 1, issue.project_id
      assert_equal 2, issue.tracker_id
      assert_equal 3, issue.status_id
      assert_equal 'API test', issue.subject
    end
    
  end
  
  context "POST /issues.json with failure" do
    should_allow_api_authentication(:post,
                                    '/issues.json',
                                    {:issue => {:project_id => 1}},
                                    {:success_code => :unprocessable_entity})

    should "have an errors element" do
      assert_no_difference('Issue.count') do
        post '/issues.json', {:issue => {:project_id => 1}}, :authorization => credentials('jsmith')
      end

      json = ActiveSupport::JSON.decode(response.body)
      assert json['errors'].include?(['subject', "can't be blank"])
    end
  end

  # Issue 6 is on a private project
  context "PUT /issues/6.xml" do
    setup do
      @parameters = {:issue => {:subject => 'API update', :notes => 'A new note'}}
      @headers = { :authorization => credentials('jsmith') }
    end
    
    should_allow_api_authentication(:put,
                                    '/issues/6.xml',
                                    {:issue => {:subject => 'API update', :notes => 'A new note'}},
                                    {:success_code => :ok})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/issues/6.xml', @parameters, @headers
      end
    end

    should "create a new journal" do
      assert_difference('Journal.count') do
        put '/issues/6.xml', @parameters, @headers
      end
    end

    should "add the note to the journal" do
      put '/issues/6.xml', @parameters, @headers
      
      journal = Journal.last
      assert_equal "A new note", journal.notes
    end

    should "update the issue" do
      put '/issues/6.xml', @parameters, @headers
      
      issue = Issue.find(6)
      assert_equal "API update", issue.subject
    end
    
  end
  
  context "PUT /issues/6.xml with failed update" do
    setup do
      @parameters = {:issue => {:subject => ''}}
      @headers = { :authorization => credentials('jsmith') }
    end

    should_allow_api_authentication(:put,
                                    '/issues/6.xml',
                                    {:issue => {:subject => ''}}, # Missing subject should fail
                                    {:success_code => :unprocessable_entity})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/issues/6.xml', @parameters, @headers
      end
    end

    should "not create a new journal" do
      assert_no_difference('Journal.count') do
        put '/issues/6.xml', @parameters, @headers
      end
    end

    should "have an errors tag" do
      put '/issues/6.xml', @parameters, @headers

      assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
    end
  end

  context "PUT /issues/6.json" do
    setup do
      @parameters = {:issue => {:subject => 'API update', :notes => 'A new note'}}
      @headers = { :authorization => credentials('jsmith') }
    end
    
    should_allow_api_authentication(:put,
                                    '/issues/6.json',
                                    {:issue => {:subject => 'API update', :notes => 'A new note'}},
                                    {:success_code => :ok})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/issues/6.json', @parameters, @headers
      end
    end

    should "create a new journal" do
      assert_difference('Journal.count') do
        put '/issues/6.json', @parameters, @headers
      end
    end

    should "add the note to the journal" do
      put '/issues/6.json', @parameters, @headers
      
      journal = Journal.last
      assert_equal "A new note", journal.notes
    end

    should "update the issue" do
      put '/issues/6.json', @parameters, @headers
      
      issue = Issue.find(6)
      assert_equal "API update", issue.subject
    end
    
  end
  
  context "PUT /issues/6.json with failed update" do
    setup do
      @parameters = {:issue => {:subject => ''}}
      @headers = { :authorization => credentials('jsmith') }
    end

    should_allow_api_authentication(:put,
                                    '/issues/6.json',
                                    {:issue => {:subject => ''}}, # Missing subject should fail
                                    {:success_code => :unprocessable_entity})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/issues/6.json', @parameters, @headers
      end
    end

    should "not create a new journal" do
      assert_no_difference('Journal.count') do
        put '/issues/6.json', @parameters, @headers
      end
    end

    should "have an errors attribute" do
      put '/issues/6.json', @parameters, @headers

      json = ActiveSupport::JSON.decode(response.body)
      assert json['errors'].include?(['subject', "can't be blank"])
    end
  end

  context "DELETE /issues/1.xml" do
    should_allow_api_authentication(:delete,
                                    '/issues/6.xml',
                                    {},
                                    {:success_code => :ok})

    should "delete the issue" do
      assert_difference('Issue.count',-1) do
        delete '/issues/6.xml', {}, :authorization => credentials('jsmith')
      end
      
      assert_nil Issue.find_by_id(6)
    end
  end

  context "DELETE /issues/1.json" do
    should_allow_api_authentication(:delete,
                                    '/issues/6.json',
                                    {},
                                    {:success_code => :ok})

    should "delete the issue" do
      assert_difference('Issue.count',-1) do
        delete '/issues/6.json', {}, :authorization => credentials('jsmith')
      end
      
      assert_nil Issue.find_by_id(6)
    end
  end

  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
