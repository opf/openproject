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

class RepositoriesMercurialControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/mercurial_repository'
  CHAR_1_HEX = "\xc3\x9c"
  PRJ_ID = 3

  ruby19_non_utf8_pass = (RUBY_VERSION >= '1.9' && Encoding.default_external.to_s != 'UTF-8')

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @repository = Repository::Mercurial.create(
                      :project => Project.find(PRJ_ID),
                      :url     => REPOSITORY_PATH,
                      :path_encoding => 'ISO-8859-1'
                      )
    assert @repository
    @diff_c_support = true
    @char_1        = CHAR_1_HEX.dup
    @tag_char_1    = "tag-#{CHAR_1_HEX}-00"
    @branch_char_0 = "branch-#{CHAR_1_HEX}-00"
    @branch_char_1 = "branch-#{CHAR_1_HEX}-01"
    if @char_1.respond_to?(:force_encoding)
      @char_1.force_encoding('UTF-8')
      @tag_char_1.force_encoding('UTF-8')
      @branch_char_0.force_encoding('UTF-8')
      @branch_char_1.force_encoding('UTF-8')
    end
  end

  if ruby19_non_utf8_pass
    puts "TODO: Mercurial functional test fails in Ruby 1.9 " +
         "and Encoding.default_external is not UTF-8. " +
         "Current value is '#{Encoding.default_external.to_s}'" 
    def test_fake; assert true end
  elsif File.directory?(REPOSITORY_PATH)
    def test_show_root
      @repository.fetch_changesets
      @repository.reload
      get :show, :id => PRJ_ID
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:entries)
      assert_equal 4, assigns(:entries).size
      assert assigns(:entries).detect {|e| e.name == 'images'  && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'sources' && e.kind == 'dir'}
      assert assigns(:entries).detect {|e| e.name == 'README'  && e.kind == 'file'}
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end

    def test_show_directory
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
      assert_not_nil assigns(:changesets)
      assigns(:changesets).size > 0
    end

    def test_show_at_given_revision
      @repository.fetch_changesets
      @repository.reload
      [0, '0', '0885933ad4f6'].each do |r1|
        get :show, :id => PRJ_ID, :path => ['images'], :rev => r1
        assert_response :success
        assert_template 'show'
        assert_not_nil assigns(:entries)
        assert_equal ['delete.png'], assigns(:entries).collect(&:name)
        assert_not_nil assigns(:changesets)
        assigns(:changesets).size > 0
      end
    end

    def test_show_directory_sql_escape_percent
      @repository.fetch_changesets
      @repository.reload
      [13, '13', '3a330eb32958'].each do |r1|
        get :show, :id => PRJ_ID, :path => ['sql_escape', 'percent%dir'], :rev => r1
        assert_response :success
        assert_template 'show'

        assert_not_nil assigns(:entries)
        assert_equal ['percent%file1.txt', 'percentfile1.txt'], assigns(:entries).collect(&:name)
        changesets = assigns(:changesets)
        assert_not_nil changesets
        assigns(:changesets).size > 0
        assert_equal %w(13 11 10 9), changesets.collect(&:revision)
      end
    end

    def test_show_directory_latin_1
      @repository.fetch_changesets
      @repository.reload
      [21, '21', 'adf805632193'].each do |r1|
        get :show, :id => PRJ_ID, :path => ['latin-1-dir'], :rev => r1
        assert_response :success
        assert_template 'show'

        assert_not_nil assigns(:entries)
        assert_equal ["make-latin-1-file.rb",
                      "test-#{@char_1}-1.txt",
                      "test-#{@char_1}-2.txt",
                      "test-#{@char_1}.txt"], assigns(:entries).collect(&:name)
        changesets = assigns(:changesets)
        assert_not_nil changesets
        assert_equal %w(21 20 19 18 17), changesets.collect(&:revision)
      end
    end

    def test_show_branch
      @repository.fetch_changesets
      @repository.reload
       [
          'default',
          @branch_char_1,
          'branch (1)[2]&,%.-3_4',
          @branch_char_0,
          'test_branch.latin-1',
          'test-branch-00',
      ].each do |bra|
        get :show, :id => PRJ_ID, :rev => bra
        assert_response :success
        assert_template 'show'
        assert_not_nil assigns(:entries)
        assert assigns(:entries).size > 0
        assert_not_nil assigns(:changesets)
        assigns(:changesets).size > 0
      end
    end

    def test_show_tag
      @repository.fetch_changesets
      @repository.reload
       [
        @tag_char_1,
        'tag_test.00',
        'tag-init-revision'
      ].each do |tag|
        get :show, :id => PRJ_ID, :rev => tag
        assert_response :success
        assert_template 'show'
        assert_not_nil assigns(:entries)
        assert assigns(:entries).size > 0
        assert_not_nil assigns(:changesets)
        assigns(:changesets).size > 0
      end
    end

    def test_changes
      get :changes, :id => PRJ_ID, :path => ['images', 'edit.png']
      assert_response :success
      assert_template 'changes'
      assert_tag :tag => 'h2', :content => 'edit.png'
    end
    
    def test_entry_show
      get :entry, :id => PRJ_ID, :path => ['sources', 'watchers_controller.rb']
      assert_response :success
      assert_template 'entry'
      # Line 10
      assert_tag :tag => 'th',
                 :content => '10',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td', :content => /WITHOUT ANY WARRANTY/ }
    end

    def test_entry_show_latin_1
      [21, '21', 'adf805632193'].each do |r1|
        get :entry, :id => PRJ_ID, :path => ['latin-1-dir', "test-#{@char_1}-2.txt"], :rev => r1
        assert_response :success
        assert_template 'entry'
        assert_tag :tag => 'th',
                 :content => '1',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td',
                               :content => /Mercurial is a distributed version control system/ }
      end
    end
    
    def test_entry_download
      get :entry, :id => PRJ_ID, :path => ['sources', 'watchers_controller.rb'], :format => 'raw'
      assert_response :success
      # File content
      assert @response.body.include?('WITHOUT ANY WARRANTY')
    end

    def test_entry_binary_force_download
      get :entry, :id => PRJ_ID, :rev => 1, :path => ['images', 'edit.png']
      assert_response :success
      assert_equal 'image/png', @response.content_type
    end

    def test_directory_entry
      get :entry, :id => PRJ_ID, :path => ['sources']
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
        get :diff, :id => PRJ_ID, :rev => r1
        assert_response :success
        assert_template 'diff'
        if @diff_c_support
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
          get :diff, :id => PRJ_ID, :rev    => r1,
                                    :rev_to => r2
          assert_response :success
          assert_template 'diff'

          diff = assigns(:diff)
          assert_not_nil diff
          assert_tag :tag => 'h2', :content => /4:def6d2f1254a 2:400bb8672109/
        end
      end
    end

    def test_diff_latin_1
      [21, 'adf805632193'].each do |r1|
        get :diff, :id => PRJ_ID, :rev => r1
        assert_response :success
        assert_template 'diff'
        assert_tag :tag => 'th',
                   :content => '2',
                   :sibling => { :tag => 'td', 
                               :attributes => { :class => /diff_in/ },
                               :content => /It is written in Python/ }
      end
    end

    def test_annotate
      get :annotate, :id => PRJ_ID, :path => ['sources', 'watchers_controller.rb']
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

    def test_annotate_at_given_revision
      @repository.fetch_changesets
      @repository.reload
      [2, '400bb8672109', '400', 400].each do |r1|
        get :annotate, :id => PRJ_ID, :rev => r1, :path => ['sources', 'watchers_controller.rb']
        assert_response :success
        assert_template 'annotate'
        assert_tag :tag => 'h2', :content => /@ 2:400bb8672109/
      end
    end

    def test_annotate_latin_1
      [21, '21', 'adf805632193'].each do |r1|
      get :annotate, :id => PRJ_ID, :path => ['latin-1-dir', "test-#{@char_1}-2.txt"], :rev => r1
        assert_response :success
        assert_template 'annotate'
        assert_tag :tag => 'th',
                 :content => '1',
                 :attributes => { :class => 'line-num' },
                 :sibling =>
                       {
                         :tag => 'td',
                         :attributes => { :class => 'revision' },
                         :child => { :tag => 'a', :content => '20:709858aafd1b' }
                       }
        assert_tag :tag => 'th',
                 :content => '1',
                 :attributes => { :class => 'line-num' },
                 :sibling =>
                       {
                          :tag     => 'td'    ,
                          :content => 'jsmith' ,
                          :attributes => { :class   => 'author' },
                          
                        }
        assert_tag :tag => 'th',
                 :content => '1',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td',
                               :content => /Mercurial is a distributed version control system/ }

      end
    end

    def test_empty_revision
      @repository.fetch_changesets
      @repository.reload
      ['', ' ', nil].each do |r|
        get :revision, :id => PRJ_ID, :rev => r
        assert_response 404
        assert_error_tag :content => /was not found/
      end
    end
  else
    puts "Mercurial test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
