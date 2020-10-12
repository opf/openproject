#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require_relative '../legacy_spec_helper'
require 'enumerations_controller'

describe EnumerationsController, type: :controller do
  fixtures :all

  before do
    session[:user_id] = 1 # admin
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
  end

  it 'should destroy enumeration not in use' do
    post :destroy, params: { id: 7 }
    assert_redirected_to enumerations_path
    assert_nil Enumeration.find_by(id: 7)
  end

  it 'should destroy enumeration in use' do
    post :destroy, params: { id: 4 }
    assert_response :success
    assert_template 'destroy'
    refute_nil Enumeration.find_by(id: 4)
  end

  it 'should destroy enumeration in use with reassignment' do
    issue = WorkPackage.find_by(priority_id: 4)
    post :destroy, params: { id: 4, reassign_to_id: 6 }
    assert_redirected_to enumerations_path
    assert_nil Enumeration.find_by(id: 4)
    # check that the issue was reassign
    assert_equal 6, issue.reload.priority_id
  end
end
