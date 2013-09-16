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

class Issues::CalendarsControllerTest < ActionController::TestCase
  fixtures :all

  def test_calendar
    get :index, :project_id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  def test_cross_project_calendar
    get :index
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  context "GET :show" do
    should "run custom queries" do
      @query = Query.generate_default!

      get :index, :query_id => @query.id
      assert_response :success
    end

  end

  def test_week_number_calculation
    Setting.start_of_week = 7

    get :index, :month => '1', :year => '2010'
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
    get :index, :month => '1', :year => '2010'
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
