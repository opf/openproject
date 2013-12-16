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

class News::CommentsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    User.current = nil
  end

  def test_add_comment
    @request.session[:user_id] = 2
    post :create, :news_id => 1, :comment => { :comments => 'This is a test comment' }
    news = News.find(1)
    assert_redirected_to news_path(news)

    comment = News.find(1).comments.reorder('created_on DESC').first
    assert_not_nil comment
    assert_equal 'This is a test comment', comment.comments
    assert_equal User.find(2), comment.author
  end

  def test_empty_comment_should_not_be_added
    @request.session[:user_id] = 2
    assert_no_difference 'Comment.count' do
      post :create, :news_id => 1, :comment => { :comments => '' }
      news = News.find(1)
      assert_response :redirect
      assert_redirected_to news_path(news)
    end
  end

  def test_destroy_comment
    @request.session[:user_id] = 2
    news = News.find(1)
    assert_difference 'Comment.count', -1 do
      delete :destroy, :id => 2
    end

    news = News.find(1)
    assert_redirected_to news_path(news)
    assert_nil Comment.find_by_id(2)
  end
end
