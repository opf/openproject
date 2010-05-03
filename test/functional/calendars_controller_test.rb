require 'test_helper'

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
  
end
