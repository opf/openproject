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

class RepositoriesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :issues, :issue_statuses, :changesets, :changes, :issue_categories, :enumerations, :custom_fields, :custom_values, :trackers
  
  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show_routing
    assert_routing(
      {:method => :get, :path => '/projects/redmine/repository'},
      :controller => 'repositories', :action => 'show', :id => 'redmine'
    )
  end
  
  def test_edit_routing
    assert_routing(
      {:method => :get, :path => '/projects/world_domination/repository/edit'},
      :controller => 'repositories', :action => 'edit', :id => 'world_domination'
    )
    assert_routing(
      {:method => :post, :path => '/projects/world_domination/repository/edit'},
      :controller => 'repositories', :action => 'edit', :id => 'world_domination'
    )
  end
  
  def test_revisions_routing
    assert_routing(
      {:method => :get, :path => '/projects/redmine/repository/revisions'},
      :controller => 'repositories', :action => 'revisions', :id => 'redmine'
    )
  end
  
  def test_revisions_atom_routing
    assert_routing(
      {:method => :get, :path => '/projects/redmine/repository/revisions.atom'},
      :controller => 'repositories', :action => 'revisions', :id => 'redmine', :format => 'atom'
    )
  end
  
  def test_revisions
    get :revisions, :id => 1
    assert_response :success
    assert_template 'revisions'
    assert_not_nil assigns(:changesets)
  end

  def test_revision_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/revisions/2457'},
      :controller => 'repositories', :action => 'revision', :id => 'restmine', :rev => '2457'
    )
  end
  
  def test_revision_with_before_nil_and_afer_normal
    get :revision, {:id => 1, :rev => 1}
    assert_response :success
    assert_template 'revision'
    assert_no_tag :tag => "div", :attributes => { :class => "contextual" },
      :child => { :tag => "a", :attributes => { :href => '/projects/ecookbook/repository/revisions/0'}
    }
    assert_tag :tag => "div", :attributes => { :class => "contextual" },
        :child => { :tag => "a", :attributes => { :href => '/projects/ecookbook/repository/revisions/2'}
    }
  end
  
  def test_diff_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/revisions/2457/diff'},
      :controller => 'repositories', :action => 'diff', :id => 'restmine', :rev => '2457'
    )
  end
  
  def test_unified_diff_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/revisions/2457/diff.diff'},
      :controller => 'repositories', :action => 'diff', :id => 'restmine', :rev => '2457', :format => 'diff'
    )
  end
  
  def test_diff_path_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/diff/path/to/file.c'},
      :controller => 'repositories', :action => 'diff', :id => 'restmine', :path => %w[path to file.c]
    )
  end

  def test_diff_path_routing_with_revision
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/revisions/2/diff/path/to/file.c'},
      :controller => 'repositories', :action => 'diff', :id => 'restmine', :path => %w[path to file.c], :rev => '2'
    )
  end
  
  def test_browse_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/browse/path/to/dir'},
      :controller => 'repositories', :action => 'browse', :id => 'restmine', :path => %w[path to dir]
    )
  end
  
  def test_entry_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/entry/path/to/file.c'},
      :controller => 'repositories', :action => 'entry', :id => 'restmine', :path => %w[path to file.c]
    )
  end
  
  def test_entry_routing_with_revision
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/revisions/2/entry/path/to/file.c'},
      :controller => 'repositories', :action => 'entry', :id => 'restmine', :path => %w[path to file.c], :rev => '2'
    )
  end
  
  def test_annotate_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/annotate/path/to/file.c'},
      :controller => 'repositories', :action => 'annotate', :id => 'restmine', :path => %w[path to file.c]
    )
  end
  
  def test_changesrouting
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/changes/path/to/file.c'},
      :controller => 'repositories', :action => 'changes', :id => 'restmine', :path => %w[path to file.c]
    )
  end
  
  def test_statistics_routing
    assert_routing(
      {:method => :get, :path => '/projects/restmine/repository/statistics'},
      :controller => 'repositories', :action => 'stats', :id => 'restmine'
    )
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
  
  def test_committers
    @request.session[:user_id] = 2
    # add a commit with an unknown user
    Changeset.create!(:repository => Project.find(1).repository, :committer => 'foo', :committed_on => Time.now, :revision => 100, :comments => 'Committed by foo.')
    
    get :committers, :id => 1
    assert_response :success
    assert_template 'committers'
    
    assert_tag :td, :content => 'dlopper',
                    :sibling => { :tag => 'td',
                                  :child => { :tag => 'select', :attributes => { :name => %r{^committers\[\d+\]\[\]$} },
                                                                :child => { :tag => 'option', :content => 'Dave Lopper',
                                                                                              :attributes => { :value => '3', :selected => 'selected' }}}}
    assert_tag :td, :content => 'foo',
                    :sibling => { :tag => 'td',
                                  :child => { :tag => 'select', :attributes => { :name => %r{^committers\[\d+\]\[\]$} }}}
    assert_no_tag :td, :content => 'foo',
                       :sibling => { :tag => 'td',
                                     :descendant => { :tag => 'option', :attributes => { :selected => 'selected' }}}
  end

  def test_map_committers
    @request.session[:user_id] = 2
    # add a commit with an unknown user
    c = Changeset.create!(:repository => Project.find(1).repository, :committer => 'foo', :committed_on => Time.now, :revision => 100, :comments => 'Committed by foo.')
    
    assert_no_difference "Changeset.count(:conditions => 'user_id = 3')" do
      post :committers, :id => 1, :committers => { '0' => ['foo', '2'], '1' => ['dlopper', '3']}
      assert_redirected_to 'projects/ecookbook/repository/committers'
      assert_equal User.find(2), c.reload.user
    end
  end
end
