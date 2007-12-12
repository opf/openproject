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
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :repositories, :issues, :issue_statuses, :changesets, :changes, :issue_categories, :enumerations, :custom_fields, :custom_values, :trackers
  
  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_revisions
    get :revisions, :id => 1
    assert_response :success
    assert_template 'revisions'
    assert_not_nil assigns(:changesets)
  end
  
  def test_revision_with_before_nil_and_afer_normal
    get :revision, {:id => 1, :rev => 1}
    assert_response :success
    assert_template 'revision'
    assert_no_tag :tag => "div", :attributes => { :class => "contextual" },
      :child => { :tag => "a", :attributes => { :href => '/repositories/revision/1?rev=0'}
    }
    assert_tag :tag => "div", :attributes => { :class => "contextual" },
        :child => { :tag => "a", :attributes => { :href => '/repositories/revision/1?rev=2'}
    }
  end

  def test_graph_commits_per_month
    get :graph, :id => 1, :graph => 'commits_per_month'
    assert_response :success
    assert_equal 'image/svg+xml', @response.content_type
  end
  
  def test_graph_commits_per_author
    get :graph, :id => 1, :graph => 'commits_per_author'
    assert_response :success
    assert_equal 'image/svg+xml', @response.content_type
  end
end
