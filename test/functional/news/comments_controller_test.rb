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

class News::CommentsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules, :news, :comments

  def setup
    User.current = nil
  end

  def test_add_comment
    @request.session[:user_id] = 2
    post :create, :news_id => 1, :comment => { :comments => 'This is a test comment' }
    assert_redirected_to '/news/1'

    comment = News.find(1).comments.reorder('created_on DESC').first
    assert_not_nil comment
    assert_equal 'This is a test comment', comment.comments
    assert_equal User.find(2), comment.author
  end

  def test_empty_comment_should_not_be_added
    @request.session[:user_id] = 2
    assert_no_difference 'Comment.count' do
      post :create, :news_id => 1, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to '/news/1'
    end
  end

  def test_destroy_comment
    @request.session[:user_id] = 2
    news = News.find(1)
    assert_difference 'Comment.count', -1 do
      delete :destroy, :id => 2
    end

    assert_redirected_to '/news/1'
    assert_nil Comment.find_by_id(2)
  end
end
