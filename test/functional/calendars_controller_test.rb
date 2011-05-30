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

class CalendarsControllerTest < ActionController::TestCase
  fixtures :all

  def test_calendar
    get :show, :project_id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  def test_cross_project_calendar
    get :show
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  context "GET :show" do
    should "run custom queries" do
      @query = Query.generate_default!

      get :show, :query_id => @query.id
      assert_response :success
    end

  end

  def test_week_number_calculation
    Setting.start_of_week = 7

    get :show, :month => '1', :year => '2010'
    assert_response :success

    assert_tag :tag => 'tr',
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'week-number'}, :content => '53'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'odd'}, :content => '27'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '2'}

    assert_tag :tag => 'tr',
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'week-number'}, :content => '1'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'odd'}, :content => '3'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '9'}


    Setting.start_of_week = 1
    get :show, :month => '1', :year => '2010'
    assert_response :success

    assert_tag :tag => 'tr',
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'week-number'}, :content => '53'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '28'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '3'}

    assert_tag :tag => 'tr',
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'week-number'}, :content => '1'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '4'},
      :descendant => {:tag => 'td',
                      :attributes => {:class => 'even'}, :content => '10'}

  end
end
