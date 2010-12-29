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

class RepositoriesCvsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/cvs_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?
  # CVS module
  MODULE_NAME = 'test'
  
  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Setting.default_language = 'en'
    User.current = nil

    @project = Project.find(1)
    @project.repository = Repository::Cvs.create(:root_url => REPOSITORY_PATH,
                                                 :url => MODULE_NAME)
  end
  
  if File.directory?(REPOSITORY_PATH)
    def test_show
      get :show, :id => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_not_nil assigns(:changesets)
    end
    
    def test_browse_root
      get :show, :id => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 3, assigns(:entries).size
      
      entry = assigns(:entries).detect {|e| e.name == 'images'}
      assert_equal 'dir', entry.kind

      entry = assigns(:entries).detect {|e| e.name == 'README'}
      assert_equal 'file', entry.kind
    end
    
    def test_browse_directory
      get :show, :id => 1, :path => ['images']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['add.png', 'delete.png', 'edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'images/edit.png', entry.path
    end
    
    def test_browse_at_given_revision
      Project.find(1).repository.fetch_changesets
      get :show, :id => 1, :path => ['images'], :rev => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png', 'edit.png'], assigns(:entries).collect(&:name)
    end
  
    def test_entry
      get :entry, :id => 1, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'entry'
      assert_no_tag :tag => 'td', :attributes => { :class => /line-code/},
                                  :content => /before_filter/
    end
    
    def test_entry_at_given_revision
      # changesets must be loaded
      Project.find(1).repository.fetch_changesets
      get :entry, :id => 1, :path => ['sources', 'watchers_controller.rb'], :rev => 2
      assert_response :success
      assert_template 'entry'
      # this line was removed in r3
      assert_tag :tag => 'td', :attributes => { :class => /line-code/},
                               :content => /before_filter/
    end
    
    def test_entry_not_found
      get :entry, :id => 1, :path => ['sources', 'zzz.c']
      assert_tag :tag => 'p', :attributes => { :id => /errorExplanation/ },
                                :content => /The entry or revision was not found in the repository/
    end
  
    def test_entry_download
      get :entry, :id => 1, :path => ['sources', 'watchers_controller.rb'], :format => 'raw'
      assert_response :success
    end

    def test_directory_entry
      get :entry, :id => 1, :path => ['sources']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entry)
      assert_equal 'sources', assigns(:entry).name
    end
    
    def test_diff
      Project.find(1).repository.fetch_changesets
      get :diff, :id => 1, :rev => 3, :type => 'inline'
      assert_response :success
      assert_template 'diff'
      assert_tag :tag => 'td', :attributes => { :class => 'line-code diff_out' },
                               :content => /watched.remove_watcher/
      assert_tag :tag => 'td', :attributes => { :class => 'line-code diff_in' },
                               :content => /watched.remove_all_watcher/
    end

    def test_annotate
      Project.find(1).repository.fetch_changesets
      get :annotate, :id => 1, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'annotate'
      # 1.1 line
      assert_tag :tag => 'th', :attributes => { :class => 'line-num' },
                               :content => '18',
                               :sibling => { :tag => 'td', :attributes => { :class => 'revision' },
                                             :content => /1.1/,
                                             :sibling => { :tag => 'td', :attributes => { :class => 'author' },
                                                           :content => /LANG/
                                           }
                               }
      # 1.2 line
      assert_tag :tag => 'th', :attributes => { :class => 'line-num' },
                               :content => '32',
                               :sibling => { :tag => 'td', :attributes => { :class => 'revision' },
                                             :content => /1.2/,
                                             :sibling => { :tag => 'td', :attributes => { :class => 'author' },
                                                           :content => /LANG/
                                           }
                               }
    end
  else
    puts "CVS test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
