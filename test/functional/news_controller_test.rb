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
require 'news_controller'

# Re-raise errors caught by the controller.
class NewsController; def rescue_action(e) raise e end; end

class NewsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules, :news, :comments

  def setup
    @controller = NewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:newss)
    assert_nil assigns(:project)
  end

  def test_index_with_project
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:newss)
  end

  def test_show
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_tag :tag => 'h2', :content => /eCookbook first release/
  end

  def test_show_not_found
    get :show, :id => 999
    assert_response 404
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
  end

  def test_post_create
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Setting.notified_events.dup << 'news_added'

    @request.session[:user_id] = 2
    post :create, :project_id => 1, :news => { :title => 'NewsControllerTest',
                                            :description => 'This is the description',
                                            :summary => '' }
    assert_redirected_to '/projects/ecookbook/news'

    news = News.find_by_title('NewsControllerTest')
    assert_not_nil news
    assert_equal 'This is the description', news.description
    assert_equal User.find(2), news.author
    assert_equal Project.find(1), news.project
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
  end

  def test_put_update
    @request.session[:user_id] = 2
    put :update, :id => 1, :news => { :description => 'Description changed by test_post_edit' }
    assert_redirected_to '/news/1'
    news = News.find(1)
    assert_equal 'Description changed by test_post_edit', news.description
  end

  def test_post_create_with_validation_failure
    @request.session[:user_id] = 2
    post :create, :project_id => 1, :news => { :title => '',
                                            :description => 'This is the description',
                                            :summary => '' }
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:news)
    assert assigns(:news).new_record?
    assert_tag :tag => 'div', :attributes => { :id => 'errorExplanation' },
                              :content => /1 error/
  end

  def test_destroy
    @request.session[:user_id] = 2
    delete :destroy, :id => 1
    assert_redirected_to '/projects/ecookbook/news'
    assert_nil News.find_by_id(1)
  end
end
