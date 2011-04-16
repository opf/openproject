# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesDarcsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/darcs_repository'
  PRJ_ID = 3

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @project = Project.find(PRJ_ID)
    @repository = Repository::Darcs.create(
                        :project => @project, :url => REPOSITORY_PATH,
                        :log_encoding => 'UTF-8')
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_browse_root
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => PRJ_ID
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 3, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README' && e.kind == 'file'}
    end

    def test_browse_directory
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => PRJ_ID, :path => ['images']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png', 'edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'images/edit.png', entry.path
    end

    def test_browse_at_given_revision
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => PRJ_ID, :path => ['images'], :rev => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png'], assigns(:entries).collect(&:name)
    end

    def test_changes
      @repository.fetch_changesets
      @repository.reload
      get :changes, :id => PRJ_ID, :path => ['images', 'edit.png']
      assert_response :success
      assert_template 'changes'
      assert_tag :tag => 'h2', :content => 'edit.png'
    end

    def test_diff
      @repository.fetch_changesets
      @repository.reload
      # Full diff of changeset 5
      get :diff, :id => PRJ_ID, :rev => 5
      assert_response :success
      assert_template 'diff'
      # Line 22 removed
      assert_tag :tag => 'th',
                 :content => /22/,
                 :sibling => { :tag => 'td', 
                               :attributes => { :class => /diff_out/ },
                               :content => /def remove/ }
    end
  else
    puts "Darcs test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
