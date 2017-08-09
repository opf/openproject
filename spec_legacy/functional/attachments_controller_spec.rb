#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require_relative '../legacy_spec_helper'
require 'attachments_controller'

describe AttachmentsController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should download other' do
    get :download, params: { id: 6 }
    assert_equal 'application/zip', response.content_type
  end

  it 'should download text file' do
    get :download, params: { id: 4 }
    assert_response :success
    assert_equal 'text/x-ruby', response.content_type
  end

  it 'should download missing file' do
    get :download, params: { id: 2 }
    assert_response 404
  end

  it 'should anonymous on private private' do
    get :download, params: { id: 7 }
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F7'
  end

  it 'should destroy without permission' do
    delete :destroy, params: { id: 3 }
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Fattachments%2F3'
    assert Attachment.find_by(id: 3)
  end
end
