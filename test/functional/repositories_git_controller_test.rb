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

class RepositoriesGitControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if RUBY_PLATFORM =~ /mswin/

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    Repository::Git.create(:project => Project.find(3), :url => REPOSITORY_PATH)
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
      assert_equal 3, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README' && e.kind == 'file'}
    end
    
    def test_browse_directory
      get :browse, :id => 3, :path => ['images']
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png', 'edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'images/edit.png', entry.path
    end
    
    def test_browse_at_given_revision
      get :browse, :id => 3, :path => ['images'], :rev => '7234cb2750b63f47bff735edc50a1c0a433c2518'
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png'], assigns(:entries).collect(&:name)
    end

    def test_changes
      get :changes, :id => 3, :path => ['images', 'edit.png']
      assert_response :success
      assert_template 'changes'
      assert_tag :tag => 'h2', :content => 'edit.png'
    end
    
    def test_entry_show
      get :entry, :id => 3, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'entry'
      # Line 19
      assert_tag :tag => 'th',
                 :content => /10/,
                 :attributes => { :class => /line-num/ },
                 :sibling => { :tag => 'td', :content => /WITHOUT ANY WARRANTY/ }
    end
    
    def test_entry_download
      get :entry, :id => 3, :path => ['sources', 'watchers_controller.rb'], :format => 'raw'
      assert_response :success
      # File content
      assert @response.body.include?('WITHOUT ANY WARRANTY')
    end
  
    def test_directory_entry
      get :entry, :id => 3, :path => ['sources']
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entry)
      assert_equal 'sources', assigns(:entry).name
    end
    
    def test_diff
      # Full diff of changeset 2f9c0091
      get :diff, :id => 3, :rev => '2f9c0091c754a91af7a9c478e36556b4bde8dcf7'
      assert_response :success
      assert_template 'diff'
      # Line 22 removed
      assert_tag :tag => 'th',
                 :content => /22/,
                 :sibling => { :tag => 'td', 
                               :attributes => { :class => /diff_out/ },
                               :content => /def remove/ }
    end

    def test_annotate
      get :annotate, :id => 3, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'annotate'
      # Line 23, changeset 2f9c0091
      assert_tag :tag => 'th', :content => /23/,
                 :sibling => { :tag => 'td', :child => { :tag => 'a', :content => /2f9c0091/ } },
                 :sibling => { :tag => 'td', :content => /jsmith/ },
                 :sibling => { :tag => 'td', :content => /watcher =/ }
    end
    
    def test_annotate_binary_file
      get :annotate, :id => 3, :path => ['images', 'delete.png']
      assert_response 500
      assert_tag :tag => 'div', :attributes => { :class => /error/ },
                                :content => /can not be annotated/
    end
  else
    puts "Git test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
