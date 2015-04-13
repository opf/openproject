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

require 'legacy_spec_helper'
require 'attachments_controller'

describe AttachmentsController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should show diff' do
    get :show, id: 14 # 060719210727_changeset_utf8.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', response.content_type

    assert_tag 'th',
               attributes: { class: /filename/ },
               content: /issues_controller.rb\t\(révision 1484\)/
    assert_tag 'td',
               attributes: { class: /line-code/ },
               content: /Demande créée avec succès/
  end

  it 'should show diff should strip non utf8 content' do
    get :show, id: 5 # 060719210727_changeset_iso8859-1.diff
    assert_response :success
    assert_template 'diff'
    assert_equal 'text/html', response.content_type

    assert_tag 'th',
               attributes: { class: /filename/ },
               content: /issues_controller.rb\t\(rvision 1484\)/
    assert_tag 'td',
               attributes: { class: /line-code/ },
               content: /Demande cre avec succs/
  end

  it 'should show text file' do
    get :show, id: 4
    assert_response :success
    assert_template 'file'
    assert_equal 'text/html', response.content_type
  end

  it 'should show text file should send if too big' do
    Setting.file_max_size_displayed = 512
    Attachment.find(4).update_attribute :filesize, 754.kilobyte

    get :show, id: 4
    assert_redirected_to 'http://test.host/attachments/4/download/source.rb'

    get :download, id: 4
    assert_response :success
    assert_equal 'text/x-ruby', response.content_type
  end

  it 'should show other' do
    get :show, id: 6

    assert_redirected_to 'http://test.host/attachments/6/download/archive.zip'

    get :download, id: 6
    assert_equal 'application/zip', response.content_type
  end

  it 'should download text file' do
    get :download, id: 4
    assert_response :success
    assert_equal 'text/x-ruby', response.content_type
  end

  it 'should download missing file' do
    get :download, id: 2
    assert_response 404
  end

  it 'should anonymous on private private' do
    get :download, id: 7
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F7%2Fdownload'
  end

  it 'should destroy without permission' do
    delete :destroy, id: 3
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F3'
    assert Attachment.find_by_id(3)
  end
end
