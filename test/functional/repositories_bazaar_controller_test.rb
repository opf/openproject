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

require File.dirname(__FILE__) + '/../test_helper'
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesBazaarControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/bazaar_repository'

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    Repository::Bazaar.create(:project => Project.find(3), :url => REPOSITORY_PATH)
  end
  
  if File.directory?(REPOSITORY_PATH)
    def test_show
      get :show, :id => 3
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_not_nil assigns(:changesets)
    end
    
    def test_browse_root
      get :browse, :id => 3
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      assert_equal 2, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'directory' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'doc-mkdir.txt' && e.kind == 'file'}
    end
    
    def test_browse_directory
      get :browse, :id => 3, :path => ['directory']
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      assert_equal ['doc-ls.txt', 'document.txt', 'edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'directory/edit.png', entry.path
    end
    
    def test_browse_at_given_revision
      get :browse, :id => 3, :path => [], :rev => 3
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      assert_equal ['directory', 'doc-deleted.txt', 'doc-ls.txt', 'doc-mkdir.txt'], assigns(:entries).collect(&:name)
    end
    
    def test_changes
      get :changes, :id => 3, :path => ['doc-mkdir.txt']
      assert_response :success
      assert_template 'changes'
      assert_tag :tag => 'h2', :content => 'doc-mkdir.txt'
    end
    
    def test_entry_show
      get :entry, :id => 3, :path => ['directory', 'doc-ls.txt']
      assert_response :success
      assert_template 'entry'
      # Line 19
      assert_tag :tag => 'th',
                 :content => /29/,
                 :attributes => { :class => /line-num/ },
                 :sibling => { :tag => 'td', :content => /Show help message/ }
    end
    
    def test_entry_download
      get :entry, :id => 3, :path => ['directory', 'doc-ls.txt'], :format => 'raw'
      assert_response :success
      # File content
      assert @response.body.include?('Show help message')
    end
  
    def test_diff
      # Full diff of changeset 3
      get :diff, :id => 3, :rev => 3
      assert_response :success
      assert_template 'diff'
      # Line 22 removed
      assert_tag :tag => 'th',
                 :content => /2/,
                 :sibling => { :tag => 'td', 
                               :attributes => { :class => /diff_in/ },
                               :content => /Main purpose/ }
    end
    
    def test_annotate
      get :annotate, :id => 3, :path => ['doc-mkdir.txt']
      assert_response :success
      assert_template 'annotate'
      # Line 2, revision 3
      assert_tag :tag => 'th', :content => /2/,
                 :sibling => { :tag => 'td', :child => { :tag => 'a', :content => /3/ } },
                 :sibling => { :tag => 'td', :content => /jsmith/ },
                 :sibling => { :tag => 'td', :content => /Main purpose/ }
    end
  else
    puts "Bazaar test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
