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

class RepositoriesMercurialControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/mercurial_repository'

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @repository = Repository::Mercurial.create(:project => Project.find(3), :url => REPOSITORY_PATH)
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_show
      get :show, :id => 3
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_not_nil assigns(:changesets)
    end

    def test_show_root
      get :show, :id => 3
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 4, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images'  && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README'  && e.kind == 'file'}
    end

    def test_show_directory
      get :show, :id => 3, :path => ['images']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png', 'edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'images/edit.png', entry.path
    end

    def test_show_at_given_revision
      [0, '0', '0885933ad4f6'].each do |r1|
        get :show, :id => 3, :path => ['images'], :rev => r1
        assert_response :success
        assert_template 'show'
        assert_not_nil assigns(:entries)
        assert_equal ['delete.png'], assigns(:entries).collect(&:name)
      end
    end

    def test_show_directory_sql_escape_percent
      [13, '13', '3a330eb32958'].each do |r1|
        get :show, :id => 3, :path => ['sql_escape', 'percent%dir'], :rev => r1
        assert_response :success
        assert_template 'show'

        assert_not_nil assigns(:entries)
        assert_equal ['percent%file1.txt', 'percentfile1.txt'], assigns(:entries).collect(&:name)
        changesets = assigns(:changesets)

        ## This is not yet implemented.
        # assert_not_nil changesets
        # assert_equal %w(13 11 10 9), changesets.collect(&:revision)
      end
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
      # Line 10
      assert_tag :tag => 'th',
                 :content => '10',
                 :attributes => { :class => 'line-num' },
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
      assert_template 'show'
      assert_not_nil assigns(:entry)
      assert_equal 'sources', assigns(:entry).name
    end
    
    def test_diff
      @repository.fetch_changesets
      @repository.reload

      [4, '4', 'def6d2f1254a'].each do |r1|
        # Full diff of changeset 4
        get :diff, :id => 3, :rev => r1
        assert_response :success
        assert_template 'diff'

        if @repository.scm.class.client_version_above?([1, 2])
          # Line 22 removed
          assert_tag :tag => 'th',
                     :content => '22',
                     :sibling => { :tag => 'td', 
                                   :attributes => { :class => /diff_out/ },
                                   :content => /def remove/ }
          assert_tag :tag => 'h2', :content => /4:def6d2f1254a/
        end
      end
    end

    def test_diff_two_revs
      @repository.fetch_changesets
      @repository.reload

      [2, '400bb8672109', '400', 400].each do |r1|
        [4, 'def6d2f1254a'].each do |r2|
          get :diff, :id => 3, :rev    => r1,
                               :rev_to => r2
          assert_response :success
          assert_template 'diff'

          diff = assigns(:diff)
          assert_not_nil diff
          assert_tag :tag => 'h2', :content => /4:def6d2f1254a 2:400bb8672109/
        end
      end
    end

    def test_annotate
      get :annotate, :id => 3, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'annotate'
      # Line 23, revision 4:def6d2f1254a
      assert_tag :tag => 'th',
                 :content => '23',
                 :attributes => { :class => 'line-num' },
                 :sibling =>
                       {
                         :tag => 'td',
                         :attributes => { :class => 'revision' },
                         :child => { :tag => 'a', :content => '4:def6d2f1254a' }
                       }
      assert_tag :tag => 'th',
                 :content => '23',
                 :attributes => { :class => 'line-num' },
                 :sibling =>
                       {
                          :tag     => 'td'    ,
                          :content => 'jsmith' ,
                          :attributes => { :class   => 'author' },
                        }
      assert_tag :tag => 'th',
                 :content => '23',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td', :content => /watcher =/ }
    end

    def test_empty_revision
      @repository.fetch_changesets
      @repository.reload
      ['', ' ', nil].each do |r|
        get :revision, :id => 3, :rev => r
        assert_response 404
        assert_error_tag :content => /was not found/
      end
    end
  else
    puts "Mercurial test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
