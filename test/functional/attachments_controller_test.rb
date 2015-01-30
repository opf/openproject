#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)
require 'attachments_controller'

# Re-raise errors caught by the controller.
class AttachmentsController; def rescue_action(e) raise e end; end

class AttachmentsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = AttachmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    User.current = nil
  end

  def test_show_diff
    get :show, id: 14 # 060719210727_changeset_utf8.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', @response.content_type

    assert_tag 'th',
               attributes: { class: /filename/ },
               content: /issues_controller.rb\t\(révision 1484\)/
    assert_tag 'td',
               attributes: { class: /line-code/ },
               content: /Demande créée avec succès/
  end

  def test_show_diff_should_strip_non_utf8_content
    get :show, id: 5 # 060719210727_changeset_iso8859-1.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', @response.content_type

    assert_tag 'th',
               attributes: { class: /filename/ },
               content: /issues_controller.rb\t\(rvision 1484\)/
    assert_tag 'td',
               attributes: { class: /line-code/ },
               content: /Demande cre avec succs/
  end

  def test_show_text_file
    get :show, id: 4
    assert_response :success
    assert_template 'file'
    assert_equal 'text/html', @response.content_type
  end

  def test_show_text_file_should_send_if_too_big
    Setting.file_max_size_displayed = 512
    Attachment.find(4).update_attribute :filesize, 754.kilobyte

    get :show, id: 4
    assert_redirected_to 'http://test.host/attachments/4/download/source.rb'

    get :download, id: 4
    assert_response :success
    assert_equal 'text/x-ruby', @response.content_type
  end

  def test_show_other
    get :show, id: 6

    assert_redirected_to 'http://test.host/attachments/6/download/archive.zip'

    get :download, id: 6
    assert_equal 'application/zip', @response.content_type
  end

  def test_download_text_file
    get :download, id: 4
    assert_response :success
    assert_equal 'text/x-ruby', @response.content_type
  end

  def test_download_missing_file
    get :download, id: 2
    assert_response 404
  end

  def test_anonymous_on_private_private
    get :download, id: 7
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F7%2Fdownload'
  end

  def test_destroy_without_permission
    delete :destroy, id: 3
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F3'
    assert Attachment.find_by_id(3)
  end
end
