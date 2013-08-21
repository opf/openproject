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
require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::IssuesTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "/index.xml" do
    # Use a private project to make sure auth is really working and not just
    # only showing public issues.
    should_allow_api_authentication(:get, "/api/v1/projects/private-child/issues.xml")

    should "contain metadata" do
      get '/api/v1/issues.xml'

      assert_tag :tag => 'issues',
        :attributes => {
          :type => 'array',
          :total_count => assigns(:issues).total_entries,
          :limit => 100,
          :offset => 0
        }
    end

    context "with offset and limit" do
      should "use the params" do
        with_settings :per_page_options => '1,2,3' do
          get '/api/v1/issues.xml?offset=4&limit=3'

          assert_equal 3, assigns(:issues).per_page
          # We only allow for offsets that are multiples of
          # per_page
          assert_equal 3, assigns(:issues).offset
          assert_tag :tag => 'issues', :children => {:count => 3, :only => {:tag => 'issue'}}
        end
      end
    end

    context "with nometa param" do
      should "not contain metadata" do
        get '/api/v1/issues.xml?nometa=1'

        assert_tag :tag => 'issues',
          :attributes => {
            :type => 'array',
            :total_count => nil,
            :limit => nil,
            :offset => nil
          }
      end
    end

    context "with nometa header" do
      should "not contain metadata" do
        get '/api/v1/issues.xml', {}, {'X-OpenProject-Nometa' => '1'}

        assert_tag :tag => 'issues',
          :attributes => {
            :type => 'array',
            :total_count => nil,
            :limit => nil,
            :offset => nil
          }
      end
    end
  end

  context "/index.json" do
    should_allow_api_authentication(:get, "/api/v1/projects/private-child/issues.json")
  end

  context "/index.xml with filter" do
    should_allow_api_authentication(:get, "/api/v1/projects/private-child/issues.xml?status_id=5")

    should "show only issues with the status_id" do
      get '/api/v1/issues.xml?status_id=5'
      assert_tag :tag => 'issues',
                 :children => { :count => Issue.visible.count(:conditions => {:status_id => 5}),
                                :only => { :tag => 'issue' } }
    end
  end

  context "/index.json with filter" do
    should_allow_api_authentication(:get, "/api/v1/projects/private-child/issues.json?status_id=5")

    should "show only issues with the status_id" do
      get '/api/v1/issues.json?status_id=5'

      json = ActiveSupport::JSON.decode(response.body)
      status_ids_used = json['issues'].collect {|j| j['status']['id'] }
      assert_equal 3, status_ids_used.length
      assert status_ids_used.all? {|id| id == 5 }
    end

  end

  # Issue 6 is on a private project
  context "/api/v1/issues/6.xml" do
    should_allow_api_authentication(:get, "/api/v1/issues/6.xml")
  end

  context "/api/v1/issues/6.json" do
    should_allow_api_authentication(:get, "/api/v1/issues/6.json")
  end

  context "GET /api/v1/issues/:id" do
    context "with journals" do
      context ".xml" do

        setup do
          Journal.delete_all

          FactoryGirl.create :work_package_journal,
                             journable_id: 1,
                             data: FactoryGirl.build(:journal_work_package_journal,
                                                     status_id: 1)
          @journal_to = FactoryGirl.create :work_package_journal,
                                           journable_id: 1,
                                           data: FactoryGirl.build(:journal_work_package_journal,
                                                                   status_id: 2)
        end

        should "display journals" do
          get '/api/v1/issues/1.xml?include=journals'

          assert_tag :tag => 'issue',
            :child => {
              :tag => 'journals',
              :attributes => { :type => 'array' },
              :child => {
                :tag => 'journal',
                :attributes => { :id => @journal_to.id },
                :child => {
                  :tag => 'details',
                  :attributes => { :type => 'array' },
                  :child => {
                    :tag => 'detail',
                    :attributes => { :name => 'status_id' },
                    :child => {
                      :tag => 'old_value',
                      :content => '1',
                      :sibling => {
                        :tag => 'new_value',
                        :content => '2'
                      }
                    }
                  }
                }
              }
            }
        end
      end
    end

    context "with custom fields" do
      context ".xml" do
        should "display custom fields" do
          get '/api/v1/issues/3.xml'

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
        @c1 = Issue.generate!(:status_id => 1, :subject => "child c1", :type_id => 1, :project_id => 1, :parent_id => 1)
        @c2 = Issue.generate!(:status_id => 1, :subject => "child c2", :type_id => 1, :project_id => 1, :parent_id => 1)
        @c3 = Issue.generate!(:status_id => 1, :subject => "child c3", :type_id => 1, :project_id => 1, :parent_id => @c1.id)
      end

      context ".xml" do
        should "display children" do
          get '/api/v1/issues/1.xml?include=children'

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
            get '/api/v1/issues/1.json?include=children'

            json = ActiveSupport::JSON.decode(response.body)
            assert_equal([
              {
                'id' => @c1.id, 'subject' => 'child c1', 'type' => {'id' => 1, 'name' => 'Bug'},
                'children' => [{ 'id' => @c3.id, 'subject' => 'child c3', 'type' => {'id' => 1, 'name' => 'Bug'} }]
              },
              { 'id' => @c2.id, 'subject' => 'child c2', 'type' => {'id' => 1, 'name' => 'Bug'} }
              ],
              json['issue']['children'])
          end
        end
      end
    end
  end

  context "POST /api/v1/issues.xml" do
    should_allow_api_authentication(:post,
                                    '/api/v1/issues.xml',
                                    {:issue => {:project_id => 1, :subject => 'API test', :type_id => 2, :status_id => 3}},
                                    {:success_code => :created})

    should "create an issue with the attributes" do
      assert_difference('Issue.count') do
        post '/api/v1/issues.xml', {:issue => {:project_id => 1, :subject => 'API test', :type_id => 2, :status_id => 3}}, credentials('jsmith')
      end

      issue = Issue.first(:order => 'id DESC')
      assert_equal 1, issue.project_id
      assert_equal 2, issue.type_id
      assert_equal 3, issue.status_id
      assert_equal 'API test', issue.subject

      assert_response :created
      assert_equal 'application/xml', @response.content_type
      assert_tag 'issue', :child => {:tag => 'id', :content => issue.id.to_s}
    end
  end

  context "POST /api/v1/issues.xml with failure" do
    should_allow_api_authentication(:post,
                                    '/api/v1/issues.xml',
                                    {:issue => {:project_id => 1}},
                                    {:success_code => :unprocessable_entity})

    should "have an errors tag" do
      assert_no_difference('Issue.count') do
        post '/api/v1/issues.xml', {:issue => {:project_id => 1}}, credentials('jsmith')
      end

      assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
    end
  end

  context "POST /api/v1/issues.json" do
    should_allow_api_authentication(:post,
                                    '/api/v1/issues.json',
                                    {:issue => {:project_id => 1, :subject => 'API test', :type_id => 2, :status_id => 3}},
                                    {:success_code => :created})

    should "create an issue with the attributes" do
      assert_difference('Issue.count') do
        post '/api/v1/issues.json', {:issue => {:project_id => 1, :subject => 'API test', :type_id => 2, :status_id => 3}}, credentials('jsmith')
      end

      issue = Issue.first(:order => 'id DESC')
      assert_equal 1, issue.project_id
      assert_equal 2, issue.type_id
      assert_equal 3, issue.status_id
      assert_equal 'API test', issue.subject
    end

  end

  context "POST /api/v1/issues.json with failure" do
    should_allow_api_authentication(:post,
                                    '/api/v1/issues.json',
                                    {:issue => {:project_id => 1}},
                                    {:success_code => :unprocessable_entity})

    should "have an errors element" do
      assert_no_difference('Issue.count') do
        post '/api/v1/issues.json', {:issue => {:project_id => 1}}, credentials('jsmith')
      end

      json = ActiveSupport::JSON.decode(response.body)
      assert_equal json['errors'], { "subject" => ["can't be blank"] }
    end
  end

  # Issue 6 is on a private project
  context "PUT /api/v1/issues/6.xml" do
    setup do
      @parameters = {:issue => {:subject => 'API update', :notes => 'A new note'}}
      @headers = credentials('jsmith')
    end

    should_allow_api_authentication(:put,
                                    '/api/v1/issues/6.xml',
                                    {:issue => {:subject => 'API update', :notes => 'A new note'}},
                                    {:success_code => :ok})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/api/v1/issues/6.xml', @parameters, @headers
      end
    end

    should "create a new journal" do
      assert_difference('Journal.count') do
        put '/api/v1/issues/6.xml', @parameters, @headers
      end
    end

    should "add the note to the journal" do
      put '/api/v1/issues/6.xml', @parameters, @headers

      journal = Journal.last
      assert_equal "A new note", journal.notes
    end

    should "update the issue" do
      put '/api/v1/issues/6.xml', @parameters, @headers

      issue = Issue.find(6)
      assert_equal "API update", issue.subject
    end

  end

  context "PUT /api/v1/issues/3.xml with custom fields" do
    setup do
      @parameters = {:issue => {:custom_fields => [{'id' => '1', 'value' => 'PostgreSQL' }, {'id' => '2', 'value' => '150'}]}}
      @headers = credentials('jsmith')
    end

    should "update custom fields" do
      assert_no_difference('Issue.count') do
        put '/api/v1/issues/3.xml', @parameters, @headers
      end

      issue = Issue.find(3)
      assert_equal '150', issue.custom_value_for(2).value
      assert_equal 'PostgreSQL', issue.custom_value_for(1).value
    end
  end

  context "PUT /api/v1/issues/6.xml with failed update" do
    setup do
      @parameters = {:issue => {:subject => ''}}
      @headers = credentials('jsmith')
    end

    should_allow_api_authentication(:put,
                                    '/api/v1/issues/6.xml',
                                    {:issue => {:subject => ''}}, # Missing subject should fail
                                    {:success_code => :unprocessable_entity})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/api/v1/issues/6.xml', @parameters, @headers
      end
    end

    should "not create a new journal" do
      assert_no_difference('Journal.count') do
        put '/api/v1/issues/6.xml', @parameters, @headers
      end
    end

    should "have an errors tag" do
      put '/api/v1/issues/6.xml', @parameters, @headers

      assert_tag :errors, :child => {:tag => 'error', :content => "Subject can't be blank"}
    end
  end

  context "PUT /api/v1/issues/6.json" do
    setup do
      @parameters = {:issue => {:subject => 'API update', :notes => 'A new note'}}
      @headers = credentials('jsmith')
    end

    should_allow_api_authentication(:put,
                                    '/api/v1/issues/6.json',
                                    {:issue => {:subject => 'API update', :notes => 'A new note'}},
                                    {:success_code => :ok})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/api/v1/issues/6.json', @parameters, @headers
      end
    end

    should "create a new journal" do
      assert_difference('Journal.count') do
        put '/api/v1/issues/6.json', @parameters, @headers
      end
    end

    should "add the note to the journal" do
      put '/api/v1/issues/6.json', @parameters, @headers

      journal = Journal.last
      assert_equal "A new note", journal.notes
    end

    should "update the issue" do
      put '/api/v1/issues/6.json', @parameters, @headers

      issue = Issue.find(6)
      assert_equal "API update", issue.subject
    end

  end

  context "PUT /api/v1/issues/6.json with failed update" do
    setup do
      @parameters = {:issue => {:subject => ''}}
      @headers = credentials('jsmith')
    end

    should_allow_api_authentication(:put,
                                    '/api/v1/issues/6.json',
                                    {:issue => {:subject => ''}}, # Missing subject should fail
                                    {:success_code => :unprocessable_entity})

    should "not create a new issue" do
      assert_no_difference('Issue.count') do
        put '/api/v1/issues/6.json', @parameters, @headers
      end
    end

    should "not create a new journal" do
      assert_no_difference('Journal.count') do
        put '/api/v1/issues/6.json', @parameters, @headers
      end
    end

    should "have an errors attribute" do
      put '/api/v1/issues/6.json', @parameters, @headers

      json = ActiveSupport::JSON.decode(response.body)
      assert_equal json['errors'], { "subject" => ["can't be blank"] }
    end
  end

  context "DELETE /api/v1/issues/1.xml" do
    should_allow_api_authentication(:delete,
                                    '/api/v1/issues/6.xml',
                                    {},
                                    {:success_code => :ok})

    should "delete the issue" do
      assert_difference('Issue.count',-1) do
        delete '/api/v1/issues/6.xml', {}, credentials('jsmith')
      end

      assert_nil Issue.find_by_id(6)
    end
  end

  context "DELETE /api/v1/issues/1.json" do
    should_allow_api_authentication(:delete,
                                    '/api/v1/issues/6.json',
                                    {},
                                    {:success_code => :ok})

    should "delete the issue" do
      assert_difference('Issue.count',-1) do
        delete '/api/v1/issues/6.json', {}, credentials('jsmith')
      end

      assert_nil Issue.find_by_id(6)
    end
  end
end
