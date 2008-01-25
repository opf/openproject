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

class RepositoriesSubversionControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :repositories, :issues, :issue_statuses, :changesets, :changes, :issue_categories, :enumerations, :custom_fields, :custom_values, :trackers

  # No '..' in the repository path for svn
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/subversion_repository'

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
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
      get :browse, :id => 1
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      entry = assigns(:entries).detect {|e| e.name == 'subversion_test'}
      assert_equal 'dir', entry.kind
    end
    
    def test_browse_directory
      get :browse, :id => 1, :path => ['subversion_test']
      assert_response :success
      assert_template 'browse'
      assert_not_nil assigns(:entries)
      entry = assigns(:entries).detect {|e| e.name == 'helloworld.c'}
      assert_equal 'file', entry.kind
      assert_equal 'subversion_test/helloworld.c', entry.path
    end
  
    def test_entry
      get :entry, :id => 1, :path => ['subversion_test', 'helloworld.c']
      assert_response :success
      assert_template 'entry'
    end
    
    def test_entry_not_found
      get :entry, :id => 1, :path => ['subversion_test', 'zzz.c']
      assert_tag :tag => 'div', :attributes => { :class => /error/ },
                                :content => /Entry and\/or revision doesn't exist/
    end
  
    def test_entry_download
      get :entry, :id => 1, :path => ['subversion_test', 'helloworld.c'], :format => 'raw'
      assert_response :success
    end
    
    def test_diff
      get :diff, :id => 1, :rev => 3
      assert_response :success
      assert_template 'diff'
    end
    
    def test_annotate
      get :annotate, :id => 1, :path => ['subversion_test', 'helloworld.c']
      assert_response :success
      assert_template 'annotate'
    end
  else
    puts "Subversion test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
