# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'
require 'timelog_controller'

# Re-raise errors caught by the controller.
class TimelogController; def rescue_action(e) raise e end; end

class TimelogControllerTest < Test::Unit::TestCase
  fixtures :time_entries, :issues

  def setup
    @controller = TimelogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_report_no_criteria
    get :report, :project_id => 1
    assert_response :success
    assert_template 'report'
  end
  
  def test_report_one_criteria
    get :report, :project_id => 1, :period => "month", :date_from => "2007-01-01", :date_to => "2007-12-31", :criterias => ["member"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:hours)
  end
  
  def test_report_two_criterias
    get :report, :project_id => 1, :period => "week", :date_from => "2007-01-01", :date_to => "2007-12-31", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:hours)
  end
end
