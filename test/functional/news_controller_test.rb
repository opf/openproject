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
    Setting.notified_events << 'news_added'

    @request.session[:user_id] = 2
    post :create, :project_id => 1, :news => { :title => 'NewsControllerTest',
                                            :description => 'This is the description',
                                            :summary => '' }
    assert_redirected_to 'projects/ecookbook/news'
    
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
  
  def test_post_edit
    @request.session[:user_id] = 2
    post :edit, :id => 1, :news => { :description => 'Description changed by test_post_edit' }
    assert_redirected_to 'news/1'
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
  
  def test_add_comment
    @request.session[:user_id] = 2
    post :add_comment, :id => 1, :comment => { :comments => 'This is a NewsControllerTest comment' }
    assert_redirected_to 'news/1'
    
    comment = News.find(1).comments.find(:first, :order => 'created_on DESC')
    assert_not_nil comment
    assert_equal 'This is a NewsControllerTest comment', comment.comments
    assert_equal User.find(2), comment.author
  end
  
  def test_empty_comment_should_not_be_added
    @request.session[:user_id] = 2
    assert_no_difference 'Comment.count' do
      post :add_comment, :id => 1, :comment => { :comments => '' }
      assert_response :success
      assert_template 'show'
    end
  end
  
  def test_destroy_comment
    comments_count = News.find(1).comments.size
    @request.session[:user_id] = 2
    post :destroy_comment, :id => 1, :comment_id => 2
    assert_redirected_to 'news/1'
    assert_nil Comment.find_by_id(2)
    assert_equal comments_count - 1, News.find(1).comments.size
  end
  
  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1
    assert_redirected_to 'projects/ecookbook/news'
    assert_nil News.find_by_id(1)
  end
  
  def test_preview
    get :preview, :project_id => 1,
                  :news => {:title => '',
                            :description => 'News description',
                            :summary => ''}
    assert_response :success
    assert_template 'common/_preview'
    assert_tag :tag => 'fieldset', :attributes => { :class => 'preview' },
                                   :content => /News description/
  end
end
