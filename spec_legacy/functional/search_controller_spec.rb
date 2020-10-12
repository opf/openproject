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
require 'search_controller'

describe SearchController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should search without searchable custom fields' do
    CustomField.update_all "searchable = #{ActiveRecord::Base.connection.quoted_false}"

    get :index, params: { project_id: 1 }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:project)

    get :index, params: { project_id: 1, q: 'can' }
    assert_response :success
    assert_template 'index'
  end

  it 'should search with searchable custom fields' do
    get :index, params: { project_id: 1, q: 'stringforcustomfield' }
    assert_response :success
    results = assigns(:results)
    refute_nil results
    assert_equal 1, results.size
    assert results.include?(WorkPackage.find(7))
  end

  it 'should search with invalid project id' do
    get :index, params: { project_id: 195, q: 'recipe' }
    assert_response 404
    assert_nil assigns(:results)
  end

  it 'should not jump to an invisible WP' do
    get :index, params: { q: '4' }
    assert_response :success
    assert_template 'index'
  end
end
