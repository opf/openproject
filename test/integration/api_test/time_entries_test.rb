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

class ApiTest::TimeEntriesTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
  end

  context "GET /api/v1/time_entries.xml" do
    should "return time entries" do
      get '/api/v1/time_entries.xml', {}, credentials('jsmith')
      assert_response :success
      assert_equal 'application/xml', @response.content_type
      assert_tag :tag => 'time_entries',
        :child => {:tag => 'time_entry', :child => {:tag => 'id', :content => '2'}}
    end
  end

  context "GET /api/v1/time_entries/2.xml" do
    should "return requested time entry" do
      get '/api/v1/time_entries/2.xml', {}, credentials('jsmith')
      assert_response :success
      assert_equal 'application/xml', @response.content_type
      assert_tag :tag => 'time_entry',
        :child => {:tag => 'id', :content => '2'}
    end
  end

  context "POST /api/v1/time_entries.xml" do
    context "with work_package_id" do
      should "return create time entry" do
        assert_difference 'TimeEntry.count' do
          post '/api/v1/time_entries.xml', {:time_entry => {:work_package_id => '1', :spent_on => '2010-12-02', :hours => '3.5', :activity_id => '11'}}, credentials('jsmith')
        end
        assert_response :created
        assert_equal 'application/xml', @response.content_type

        entry = TimeEntry.first(:order => 'id DESC')
        assert_equal 'jsmith', entry.user.login
        assert_equal WorkPackage.find(1), entry.work_package
        assert_equal Project.find(1), entry.project
        assert_equal Date.parse('2010-12-02'), entry.spent_on
        assert_equal 3.5, entry.hours
        assert_equal TimeEntryActivity.find(11), entry.activity
      end
    end

    context "with project_id" do
      should "return create time entry" do
        assert_difference 'TimeEntry.count' do
          post '/api/v1/time_entries.xml', {:time_entry => {:project_id => '1', :spent_on => '2010-12-02', :hours => '3.5', :activity_id => '11'}}, credentials('jsmith')
        end
        assert_response :created
        assert_equal 'application/xml', @response.content_type

        entry = TimeEntry.first(:order => 'id DESC')
        assert_equal 'jsmith', entry.user.login
        assert_nil entry.work_package
        assert_equal Project.find(1), entry.project
        assert_equal Date.parse('2010-12-02'), entry.spent_on
        assert_equal 3.5, entry.hours
        assert_equal TimeEntryActivity.find(11), entry.activity
      end
    end

    context "with invalid parameters" do
      should "return errors" do
        assert_no_difference 'TimeEntry.count' do
          post '/api/v1/time_entries.xml', {:time_entry => {:project_id => '1', :spent_on => '2010-12-02', :activity_id => '11'}}, credentials('jsmith')
        end
        assert_response :unprocessable_entity
        assert_equal 'application/xml', @response.content_type

        assert_tag 'errors', :child => {:tag => 'error', :content => "Hours can't be blank"}
      end
    end
  end

  context "PUT /api/v1/time_entries/2.xml" do
    context "with valid parameters" do
      should "update time entry" do
        assert_no_difference 'TimeEntry.count' do
          put '/api/v1/time_entries/2.xml', {:time_entry => {:comments => 'API Update'}}, credentials('jsmith')
        end
        assert_response :ok
        assert_equal 'API Update', TimeEntry.find(2).comments
      end
    end

    context "with invalid parameters" do
      should "return errors" do
        assert_no_difference 'TimeEntry.count' do
          put '/api/v1/time_entries/2.xml', {:time_entry => {:hours => '', :comments => 'API Update'}}, credentials('jsmith')
        end
        assert_response :unprocessable_entity
        assert_equal 'application/xml', @response.content_type

        assert_tag 'errors', :child => {:tag => 'error', :content => "Hours can't be blank"}
      end
    end
  end

  context "DELETE /api/v1/time_entries/2.xml" do
    should "destroy time entry" do
      assert_difference 'TimeEntry.count', -1 do
        delete '/api/v1/time_entries/2.xml', {}, credentials('jsmith')
      end
      assert_response :ok
      assert_nil TimeEntry.find_by_id(2)
    end
  end
end
