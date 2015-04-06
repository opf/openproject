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
require 'search_controller'

describe SearchController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should search all projects' do
    get :index, q: 'recipe subproject commit', submit: 'Search'
    assert_response :success
    assert_template 'index'

    assert assigns(:results).include?(WorkPackage.find(2))
    assert assigns(:results).include?(WorkPackage.find(5))
    assert assigns(:results).include?(Changeset.find(101))

    assert assigns(:results_by_type).is_a?(Hash)
    assert_equal 5, assigns(:results_by_type)['changesets']
    assert_tag :a, content: 'Changesets (5)'
  end

  it 'should search project and subprojects' do
    get :index, project_id: 1, q: 'recipe subproject', scope: 'subprojects', submit: 'Search'
    assert_response :success
    assert_template 'index'
    assert assigns(:results).include?(WorkPackage.find(1))
    assert assigns(:results).include?(WorkPackage.find(5))
  end

  it 'should search without searchable custom fields' do
    CustomField.update_all "searchable = #{ActiveRecord::Base.connection.quoted_false}"

    get :index, project_id: 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:project)

    get :index, project_id: 1, q: 'can'
    assert_response :success
    assert_template 'index'
  end

  it 'should search with searchable custom fields' do
    get :index, project_id: 1, q: 'stringforcustomfield'
    assert_response :success
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(WorkPackage.find(7))
  end

  it 'should search all words' do
    # 'all words' is on by default
    get :index, project_id: 1, q: 'recipe updating saving'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(WorkPackage.find(3))
  end

  it 'should search one of the words' do
    get :index, project_id: 1, q: 'recipe updating saving', submit: 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 3, results.size
    assert results.include?(WorkPackage.find(3))
  end

  it 'should search titles only without result' do
    get :index, project_id: 1, q: 'recipe updating saving', all_words: '1', titles_only: '1', submit: 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 0, results.size
  end

  it 'should search titles only' do
    get :index, project_id: 1, q: 'recipe', titles_only: '1', submit: 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 2, results.size
  end

  it 'should search with invalid project id' do
    get :index, project_id: 195, q: 'recipe'
    assert_response 404
    assert_nil assigns(:results)
  end

  it 'should quick jump to work packages' do
    # work_package of a public project
    get :index, q: '3'
    assert_redirected_to '/work_packages/3'

    # work_package of a private project
    get :index, q: '4'
    assert_response :success
    assert_template 'index'
  end

  it 'should large integer' do
    get :index, q: '4615713488'
    assert_response :success
    assert_template 'index'
  end

  it 'should tokens with quotes' do
    get :index, project_id: 1, q: '"good bye" hello "bye bye"'
    assert_equal ['good bye', 'hello', 'bye bye'], assigns(:tokens)
  end
end
