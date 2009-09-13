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

class RepositoriesSubversionControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :repositories, :issues, :issue_statuses, :changesets, :changes,
           :issue_categories, :enumerations, :custom_fields, :custom_values, :trackers

  # No '..' in the repository path for svn
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/subversion_repository'

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Setting.default_language = 'en'
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
      get :show, :id => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      entry = assigns(:entries).detect {|e| e.name == 'subversion_test'}
      assert_equal 'dir', entry.kind
    end
    
    def test_browse_directory
      get :show, :id => 1, :path => ['subversion_test']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['folder', '.project', 'helloworld.c', 'textfile.txt'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'helloworld.c'}
      assert_equal 'file', entry.kind
      assert_equal 'subversion_test/helloworld.c', entry.path
      assert_tag :a, :content => 'helloworld.c', :attributes => { :class => /text\-x\-c/ }
    end

    def test_browse_at_given_revision
      get :show, :id => 1, :path => ['subversion_test'], :rev => 4
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['folder', '.project', 'helloworld.c', 'helloworld.rb', 'textfile.txt'], assigns(:entries).collect(&:name)
    end
    
    def test_file_changes
      get :changes, :id => 1, :path => ['subversion_test', 'folder', 'helloworld.rb' ]
      assert_response :success
      assert_template 'changes'
      
      changesets = assigns(:changesets)
      assert_not_nil changesets
      assert_equal %w(6 3 2), changesets.collect(&:revision)
      
      # svn properties displayed with svn >= 1.5 only
      if Redmine::Scm::Adapters::SubversionAdapter.client_version_above?([1, 5, 0])
        assert_not_nil assigns(:properties)
        assert_equal 'native', assigns(:properties)['svn:eol-style']
        assert_tag :ul,
                   :child => { :tag => 'li',
                               :child => { :tag => 'b', :content => 'svn:eol-style' },
                               :child => { :tag => 'span', :content => 'native' } }
      end
    end

    def test_directory_changes
      get :changes, :id => 1, :path => ['subversion_test', 'folder' ]
      assert_response :success
      assert_template 'changes'
      
      changesets = assigns(:changesets)
      assert_not_nil changesets
      assert_equal %w(7 6 5 2), changesets.collect(&:revision)
    end
      
    def test_entry
      get :entry, :id => 1, :path => ['subversion_test', 'helloworld.c']
      assert_response :success
      assert_template 'entry'
    end
      
    def test_entry_should_send_if_too_big
      # no files in the test repo is larger than 1KB...
      with_settings :file_max_size_displayed => 0 do
        get :entry, :id => 1, :path => ['subversion_test', 'helloworld.c']
        assert_response :success
        assert_template ''
        assert_equal 'attachment; filename="helloworld.c"', @response.headers['Content-Disposition']
      end
    end
    
    def test_entry_at_given_revision
      get :entry, :id => 1, :path => ['subversion_test', 'helloworld.rb'], :rev => 2
      assert_response :success
      assert_template 'entry'
      # this line was removed in r3 and file was moved in r6
      assert_tag :tag => 'td', :attributes => { :class => /line-code/},
                               :content => /Here's the code/
    end
    
    def test_entry_not_found
      get :entry, :id => 1, :path => ['subversion_test', 'zzz.c']
      assert_tag :tag => 'div', :attributes => { :class => /error/ },
                                :content => /The entry or revision was not found in the repository/
    end
  
    def test_entry_download
      get :entry, :id => 1, :path => ['subversion_test', 'helloworld.c'], :format => 'raw'
      assert_response :success
      assert_template ''
      assert_equal 'attachment; filename="helloworld.c"', @response.headers['Content-Disposition']
    end
    
    def test_directory_entry
      get :entry, :id => 1, :path => ['subversion_test', 'folder']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entry)
      assert_equal 'folder', assigns(:entry).name
    end
    
    def test_revision
      get :revision, :id => 1, :rev => 2
      assert_response :success
      assert_template 'revision'
      assert_tag :tag => 'ul',
                 :child => { :tag => 'li',
                             # link to the entry at rev 2
                             :child => { :tag => 'a', 
                                         :attributes => {:href => '/projects/ecookbook/repository/revisions/2/entry/test/some/path/in/the/repo'},
                                         :content => 'repo',
                                         # link to partial diff
                                         :sibling =>  { :tag => 'a', 
                                                        :attributes => { :href => '/projects/ecookbook/repository/revisions/2/diff/test/some/path/in/the/repo' } 
                                                       }
                                        }
                            }
    end
    
    def test_revision_with_repository_pointing_to_a_subdirectory
      r = Project.find(1).repository
      # Changes repository url to a subdirectory
      r.update_attribute :url, (r.url + '/test/some')
      
      get :revision, :id => 1, :rev => 2
      assert_response :success
      assert_template 'revision'
      assert_tag :tag => 'ul',
                 :child => { :tag => 'li',
                             # link to the entry at rev 2
                             :child => { :tag => 'a', 
                                         :attributes => {:href => '/projects/ecookbook/repository/revisions/2/entry/path/in/the/repo'},
                                         :content => 'repo',
                                         # link to partial diff
                                         :sibling =>  { :tag => 'a', 
                                                        :attributes => { :href => '/projects/ecookbook/repository/revisions/2/diff/path/in/the/repo' } 
                                                       }
                                        }
                            }
    end
    
    def test_revision_diff
      get :diff, :id => 1, :rev => 3
      assert_response :success
      assert_template 'diff'
    end

    def test_directory_diff
      get :diff, :id => 1, :rev => 6, :rev_to => 2, :path => ['subversion_test', 'folder']
      assert_response :success
      assert_template 'diff'
      
      diff = assigns(:diff)
      assert_not_nil diff
      # 2 files modified
      assert_equal 2, Redmine::UnifiedDiff.new(diff).size
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
