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
require 'wiki_controller'

# Re-raise errors caught by the controller.
class WikiController; def rescue_action(e) raise e end; end

class WikiControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :enabled_modules, :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions
  
  def setup
    @controller = WikiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show_start_page
    get :index, :id => 1
    assert_response :success
    assert_template 'show'
    assert_tag :tag => 'h1', :content => /CookBook documentation/
  end
  
  def test_show_page_with_name
    get :index, :id => 1, :page => 'Another_page'
    assert_response :success
    assert_template 'show'
    assert_tag :tag => 'h1', :content => /Another page/
  end
  
  def test_show_unexistent_page_without_edit_right
    get :index, :id => 1, :page => 'Unexistent page'
    assert_response 404
  end
  
  def test_show_unexistent_page_with_edit_right
    @request.session[:user_id] = 2
    get :index, :id => 1, :page => 'Unexistent page'
    assert_response :success
    assert_template 'edit'
  end
  
  def test_create_page
    @request.session[:user_id] = 2
    post :edit, :id => 1,
                :page => 'New page',
                :content => {:comments => 'Created the page',
                             :text => "h1. New page\n\nThis is a new page",
                             :version => 0}
    assert_redirected_to 'wiki/1/New_page'
    page = Project.find(1).wiki.find_page('New page')
    assert !page.new_record?
    assert_not_nil page.content
    assert_equal 'Created the page', page.content.comments
  end
  
  def test_preview
    @request.session[:user_id] = 2
    xhr :post, :preview, :id => 1, :page => 'CookBook_documentation',
                                   :content => { :comments => '',
                                                 :text => 'this is a *previewed text*',
                                                 :version => 3 }
    assert_response :success
    assert_template 'common/_preview'
    assert_tag :tag => 'strong', :content => /previewed text/
  end
  
  def test_history
    get :history, :id => 1, :page => 'CookBook_documentation'
    assert_response :success
    assert_template 'history'
    assert_not_nil assigns(:versions)
    assert_equal 3, assigns(:versions).size
  end
  
  def test_diff
    get :diff, :id => 1, :page => 'CookBook_documentation', :version => 2, :version_from => 1
    assert_response :success
    assert_template 'diff'
    assert_tag :tag => 'span', :attributes => { :class => 'diff_in'},
                               :content => /updated/
  end
  
  def test_rename_with_redirect
    @request.session[:user_id] = 2
    post :rename, :id => 1, :page => 'Another_page',
                            :wiki_page => { :title => 'Another renamed page',
                                            :redirect_existing_links => 1 }
    assert_redirected_to 'wiki/1/Another_renamed_page'
    wiki = Project.find(1).wiki
    # Check redirects
    assert_not_nil wiki.find_page('Another page')
    assert_nil wiki.find_page('Another page', :with_redirect => false)
  end

  def test_rename_without_redirect
    @request.session[:user_id] = 2
    post :rename, :id => 1, :page => 'Another_page',
                            :wiki_page => { :title => 'Another renamed page',
                                            :redirect_existing_links => "0" }
    assert_redirected_to 'wiki/1/Another_renamed_page'
    wiki = Project.find(1).wiki
    # Check that there's no redirects
    assert_nil wiki.find_page('Another page')
  end
  
  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1, :page => 'CookBook_documentation'
    assert_redirected_to 'wiki/1/Page_index/special'
  end
  
  def test_page_index
    get :special, :id => 1, :page => 'Page_index'
    assert_response :success
    assert_template 'special_page_index'
    pages = assigns(:pages)
    assert_not_nil pages
    assert_equal 2, pages.size
    assert_tag :tag => 'a', :attributes => { :href => '/wiki/1/CookBook_documentation' },
                            :content => /CookBook documentation/
  end
  
  def test_not_found
    get :index, :id => 999
    assert_response 404
  end
end
