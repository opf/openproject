#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesGitControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/git_repository'
  REPOSITORY_PATH.gsub!(/\//, "\\") if Redmine::Platform.mswin?

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @repository = Repository::Git.create(
                      :project => Project.find(3),
                      :url     => REPOSITORY_PATH,
                      :path_encoding => 'ISO-8859-1'
                      )
    assert @repository
  end

  if File.directory?(REPOSITORY_PATH)
    def test_browse_root
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => 3
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 9, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'this_is_a_really_long_and_verbose_directory_name' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == 'copied_README' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == 'new_file.txt' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == 'renamed_test.txt' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == 'filemane with spaces.txt' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == ' filename with a leading space.txt ' && e.kind == 'file'}
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end

    def test_browse_branch
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => 3, :rev => 'test_branch'
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 4, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README' && e.kind == 'file'}
      assert assigns(:entries).detect {|e| e.name == 'test.txt' && e.kind == 'file'}
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end

    def test_browse_tag
      @repository.fetch_changesets
      @repository.reload
       [
        "tag00.lightweight",
        "tag01.annotated",
       ].each do |t1|
        get :show, :id => 3, :rev => t1
        assert_response :success
        assert_template 'show'
        assert_not_nil assigns(:entries)
        assigns(:entries).size > 0
        assert_not_nil assigns(:changesets)
        assigns(:changesets).size > 0
      end
    end

    def test_browse_directory
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => 3, :path => ['images']
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['edit.png'], assigns(:entries).collect(&:name)
      entry = assigns(:entries).detect {|e| e.name == 'edit.png'}
      assert_not_nil entry
      assert_equal 'file', entry.kind
      assert_equal 'images/edit.png', entry.path
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end

    def test_browse_at_given_revision
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => 3, :path => ['images'], :rev => '7234cb2750b63f47bff735edc50a1c0a433c2518'
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal ['delete.png'], assigns(:entries).collect(&:name)
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
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
                 :content => /11/,
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
      assert_template 'show'
      assert_not_nil assigns(:entry)
      assert_equal 'sources', assigns(:entry).name
    end

    def test_diff
      @repository.fetch_changesets
      @repository.reload

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
      assert_tag :tag => 'h2', :content => /2f9c0091/
    end

    def test_diff_two_revs
      @repository.fetch_changesets
      @repository.reload

      get :diff, :id => 3, :rev    => '61b685fbe55ab05b5ac68402d5720c1a6ac973d1',
                           :rev_to => '2f9c0091c754a91af7a9c478e36556b4bde8dcf7'
      assert_response :success
      assert_template 'diff'

      diff = assigns(:diff)
      assert_not_nil diff
      assert_tag :tag => 'h2', :content => /2f9c0091:61b685fb/
    end

    def test_annotate
      get :annotate, :id => 3, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'annotate'
      # Line 23, changeset 2f9c0091
      assert_tag :tag => 'th', :content => /24/,
                 :sibling => { :tag => 'td', :child => { :tag => 'a', :content => /2f9c0091/ } },
                 :sibling => { :tag => 'td', :content => /jsmith/ },
                 :sibling => { :tag => 'td', :content => /watcher =/ }
    end

    def test_annotate_at_given_revision
      @repository.fetch_changesets
      @repository.reload
      get :annotate, :id => 3, :rev => 'deff7', :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'annotate'
      assert_tag :tag => 'h2', :content => /@ deff712f/
    end

    def test_annotate_binary_file
      get :annotate, :id => 3, :path => ['images', 'edit.png']
      assert_response 500
      assert_tag :tag => 'p', :attributes => { :id => /errorExplanation/ },
                              :content => /cannot be annotated/
    end

    def test_revision
      @repository.fetch_changesets
      @repository.reload
      ['61b685fbe55ab05b5ac68402d5720c1a6ac973d1', '61b685f'].each do |r|
        get :revision, :id => 3, :rev => r
        assert_response :success
        assert_template 'revision'
      end
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
    puts "Git test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
