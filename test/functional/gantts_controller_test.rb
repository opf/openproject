require 'test_helper'

class GanttsControllerTest < ActionController::TestCase
  fixtures :all

  context "#gantt" do
    should "work" do
      get :show, :project_id => 1
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      events = assigns(:gantt).events
      assert_not_nil events
      # Issue with start and due dates
      i = Issue.find(1)
      assert_not_nil i.due_date
      assert events.include?(Issue.find(1))
      # Issue with without due date but targeted to a version with date
      i = Issue.find(2)
      assert_nil i.due_date
      assert events.include?(i)
    end

    should "work cross project" do
      get :show
      assert_response :success
      assert_template 'show.html.erb'
      assert_not_nil assigns(:gantt)
      events = assigns(:gantt).events
      assert_not_nil events
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
