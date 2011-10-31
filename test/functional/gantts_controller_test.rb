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

require File.expand_path('../../test_helper', __FILE__)

class GanttsControllerTest < ActionController::TestCase
  fixtures :all

  context "#gantt" do
    should "work" do
      i2 = Issue.find(2)
      i2.update_attribute(:due_date, 1.month.from_now)

      get :show, :project_id => 1
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      # Issue with start and due dates
      i = Issue.find(1)
      assert_not_nil i.due_date
      assert_select "div a.issue", /##{i.id}/
      # Issue with on a targeted version should not be in the events but loaded in the html
      i = Issue.find(2)
      assert_select "div a.issue", /##{i.id}/
    end

    should "work without issue due dates" do
      Issue.update_all("due_date = NULL")

      get :show, :project_id => 1
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
    end

    should "work without issue and version due dates" do
      Issue.update_all("due_date = NULL")
      Version.update_all("effective_date = NULL")

      get :show, :project_id => 1
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
    end

    should "work cross project" do
      get :show
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      assert_not_nil assigns(:gantt).query
      assert_nil assigns(:gantt).project
    end

    should "not disclose private projects" do
      get :show
      assert_response :success
      assert_template 'show.html.erb'

      assert_tag 'a', :content => /eCookbook/
      # Root private project
      assert_no_tag 'a', {:content => /OnlineStore/}
      # Private children of a public project
      assert_no_tag 'a', :content => /Private child of eCookbook/
    end

    should "export to pdf" do
      get :show, :project_id => 1, :format => 'pdf'
      assert_response :success
      assert_equal 'application/pdf', @response.content_type
      assert @response.body.starts_with?('%PDF')
      assert_not_nil assigns(:gantt)
    end

    should "export to pdf cross project" do
      get :show, :format => 'pdf'
      assert_response :success
      assert_equal 'application/pdf', @response.content_type
      assert @response.body.starts_with?('%PDF')
      assert_not_nil assigns(:gantt)
    end

    should "export to png" do
      get :show, :project_id => 1, :format => 'png'
      assert_response :success
      assert_equal 'image/png', @response.content_type
    end if Object.const_defined?(:Magick)

  end
end
