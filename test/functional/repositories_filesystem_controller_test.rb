#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
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

class RepositoriesFilesystemControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :repositories, :enabled_modules

  # No '..' in the repository path
  REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/filesystem_repository'
  PRJ_ID = 3

  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    Setting.enabled_scm = Setting.enabled_scm.dup << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')
    @repository = Repository::Filesystem.create(
                      :project => Project.find(PRJ_ID),
                      :url     => REPOSITORY_PATH,
                      :path_encoding => nil
                      )
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
      assert assigns(:entries).size > 0
      assert_not_nil assigns(:changesets)
      assert assigns(:changesets).size == 0
    end

    def test_show_no_extension
      get :entry, :id => PRJ_ID, :path => ['test']
      assert_response :success
      assert_template 'entry'
      assert_tag :tag => 'th',
                 :content => '1',
                 :attributes => { :class => 'line-num' },
                 :sibling => { :tag => 'td', :content => /TEST CAT/ }
    end

    def test_entry_download_no_extension
      get :entry, :id => PRJ_ID, :path => ['test'], :format => 'raw'
      assert_response :success
      assert_equal 'application/octet-stream', @response.content_type
    end

    def test_show_non_ascii_contents
      with_settings :repositories_encodings => 'UTF-8,EUC-JP' do
        get :entry, :id => PRJ_ID, :path => ['japanese', 'euc-jp.txt']
        assert_response :success
        assert_template 'entry'
        assert_tag :tag => 'th',
                   :content => '2',
                   :attributes => { :class => 'line-num' },
                   :sibling => { :tag => 'td', :content => /japanese/ }
      end
    end

    def test_show_utf16
      with_settings :repositories_encodings => 'UTF-16' do
        get :entry, :id => PRJ_ID, :path => ['japanese', 'utf-16.txt']
        assert_response :success

        assert_select "tr" do
          assert_select "th.line-num" do
            assert_select "a", :text => /2/
          end
          assert_select "td", :content => /japanese/
        end

      end
    end

    def test_show_text_file_should_send_if_too_big
      with_settings :file_max_size_displayed => 1 do
        get :entry, :id => PRJ_ID, :path => ['japanese', 'big-file.txt']
        assert_response :success
        assert_equal 'text/plain', @response.content_type
      end
    end
  else
    puts "Filesystem test repository NOT FOUND. Skipping functional tests !!!"
    def test_fake; assert true end
  end
end
