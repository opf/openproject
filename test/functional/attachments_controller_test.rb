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
require 'attachments_controller'

# Re-raise errors caught by the controller.
class AttachmentsController; def rescue_action(e) raise e end; end


class AttachmentsControllerTest < ActionController::TestCase
  fixtures :users, :projects, :roles, :members, :member_roles, :enabled_modules, :issues, :trackers, :attachments,
           :versions, :wiki_pages, :wikis, :documents

  def setup
    @controller = AttachmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Attachment.storage_path = "#{RAILS_ROOT}/test/fixtures/files"
    User.current = nil
  end

  def test_show_diff
    get :show, :id => 14 # 060719210727_changeset_utf8.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', @response.content_type

    assert_tag 'th',
      :attributes => {:class => /filename/},
      :content => /issues_controller.rb\t\(révision 1484\)/
    assert_tag 'td',
      :attributes => {:class => /line-code/},
      :content => /Demande créée avec succès/
  end

  def test_show_diff_should_strip_non_utf8_content
    get :show, :id => 5 # 060719210727_changeset_iso8859-1.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', @response.content_type

    assert_tag 'th',
      :attributes => {:class => /filename/},
      :content => /issues_controller.rb\t\(rvision 1484\)/
    assert_tag 'td',
      :attributes => {:class => /line-code/},
      :content => /Demande cre avec succs/
  end

  def test_show_text_file
    get :show, :id => 4
    assert_response :success
    assert_template 'file'
    assert_equal 'text/html', @response.content_type
  end

  def test_show_text_file_should_send_if_too_big
    Setting.file_max_size_displayed = 512
    Attachment.find(4).update_attribute :filesize, 754.kilobyte

    get :show, :id => 4
    assert_response :success
    assert_equal 'application/x-ruby', @response.content_type
  end

  def test_show_other
    get :show, :id => 6
    assert_response :success
    assert_equal 'application/octet-stream', @response.content_type
  end

  def test_download_text_file
    get :download, :id => 4
    assert_response :success
    assert_equal 'application/x-ruby', @response.content_type
  end

  def test_download_should_assign_content_type_if_blank
    Attachment.find(4).update_attribute(:content_type, '')

    get :download, :id => 4
    assert_response :success
    assert_equal 'text/x-ruby', @response.content_type
  end

  def test_download_missing_file
    get :download, :id => 2
    assert_response 404
  end

  def test_anonymous_on_private_private
    get :download, :id => 7
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2Fdownload%2F7'
  end

  def test_destroy_issue_attachment
    issue = Issue.find(3)
    @request.session[:user_id] = 2

    assert_difference 'issue.attachments.count', -1 do
      post :destroy, :id => 1
    end
    # no referrer
    assert_redirected_to '/projects/ecookbook'
    assert_nil Attachment.find_by_id(1)
    j = issue.journals.find(:first, :order => 'created_at DESC')
    assert_equal ['attachments_1'], j.details.keys
    assert_equal 'error281.txt', j.details['attachments_1'].first
  end

  def test_destroy_wiki_page_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 3
      assert_response 302
    end
  end

  def test_destroy_project_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 8
      assert_response 302
    end
  end

  def test_destroy_version_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 9
      assert_response 302
    end
  end

  def test_destroy_without_permission
    post :destroy, :id => 3
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2Fdestroy%2F3'
    assert Attachment.find_by_id(3)
  end
end
