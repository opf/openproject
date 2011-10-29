#-- encoding: UTF-8
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

class ApiTest::TimeEntriesTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /time_entries.xml" do
    should "return time entries" do
      get '/time_entries.xml', {}, :authorization => credentials('jsmith')
      assert_response :success
      assert_equal 'application/xml', @response.content_type
      assert_tag :tag => 'time_entries',
        :child => {:tag => 'time_entry', :child => {:tag => 'id', :content => '2'}}
    end
  end

  context "GET /time_entries/2.xml" do
    should "return requested time entry" do
      get '/time_entries/2.xml', {}, :authorization => credentials('jsmith')
      assert_response :success
      assert_equal 'application/xml', @response.content_type
      assert_tag :tag => 'time_entry',
        :child => {:tag => 'id', :content => '2'}
    end
  end

  context "POST /time_entries.xml" do
    context "with issue_id" do
      should "return create time entry" do
        assert_difference 'TimeEntry.count' do
          post '/time_entries.xml', {:time_entry => {:issue_id => '1', :spent_on => '2010-12-02', :hours => '3.5', :activity_id => '11'}}, :authorization => credentials('jsmith')
        end
        assert_response :created
        assert_equal 'application/xml', @response.content_type

        entry = TimeEntry.first(:order => 'id DESC')
        assert_equal 'jsmith', entry.user.login
        assert_equal Issue.find(1), entry.issue
        assert_equal Project.find(1), entry.project
        assert_equal Date.parse('2010-12-02'), entry.spent_on
        assert_equal 3.5, entry.hours
        assert_equal TimeEntryActivity.find(11), entry.activity
      end
    end

    context "with project_id" do
      should "return create time entry" do
        assert_difference 'TimeEntry.count' do
          post '/time_entries.xml', {:time_entry => {:project_id => '1', :spent_on => '2010-12-02', :hours => '3.5', :activity_id => '11'}}, :authorization => credentials('jsmith')
        end
        assert_response :created
        assert_equal 'application/xml', @response.content_type

        entry = TimeEntry.first(:order => 'id DESC')
        assert_equal 'jsmith', entry.user.login
        assert_nil entry.issue
        assert_equal Project.find(1), entry.project
        assert_equal Date.parse('2010-12-02'), entry.spent_on
        assert_equal 3.5, entry.hours
        assert_equal TimeEntryActivity.find(11), entry.activity
      end
    end

    context "with invalid parameters" do
      should "return errors" do
        assert_no_difference 'TimeEntry.count' do
          post '/time_entries.xml', {:time_entry => {:project_id => '1', :spent_on => '2010-12-02', :activity_id => '11'}}, :authorization => credentials('jsmith')
        end
        assert_response :unprocessable_entity
        assert_equal 'application/xml', @response.content_type

        assert_tag 'errors', :child => {:tag => 'error', :content => "Hours can't be blank"}
      end
    end
  end

  context "PUT /time_entries/2.xml" do
    context "with valid parameters" do
      should "update time entry" do
        assert_no_difference 'TimeEntry.count' do
          put '/time_entries/2.xml', {:time_entry => {:comments => 'API Update'}}, :authorization => credentials('jsmith')
        end
        assert_response :ok
        assert_equal 'API Update', TimeEntry.find(2).comments
      end
    end

    context "with invalid parameters" do
      should "return errors" do
        assert_no_difference 'TimeEntry.count' do
          put '/time_entries/2.xml', {:time_entry => {:hours => '', :comments => 'API Update'}}, :authorization => credentials('jsmith')
        end
        assert_response :unprocessable_entity
        assert_equal 'application/xml', @response.content_type

        assert_tag 'errors', :child => {:tag => 'error', :content => "Hours can't be blank"}
      end
    end
  end

  context "DELETE /time_entries/2.xml" do
    should "destroy time entry" do
      assert_difference 'TimeEntry.count', -1 do
        delete '/time_entries/2.xml', {}, :authorization => credentials('jsmith')
      end
      assert_response :ok
      assert_nil TimeEntry.find_by_id(2)
    end
  end

  def credentials(user, password=nil)
    ActionController::HttpAuthentication::Basic.encode_credentials(user, password || user)
  end
end
