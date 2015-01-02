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
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_search_all_projects
    get :index, :q => 'recipe subproject commit', :submit => 'Search'
    assert_response :success
    assert_template 'index'

    assert assigns(:results).include?(WorkPackage.find(2))
    assert assigns(:results).include?(WorkPackage.find(5))
    assert assigns(:results).include?(Changeset.find(101))

    assert assigns(:results_by_type).is_a?(Hash)
    assert_equal 5, assigns(:results_by_type)['changesets']
    assert_tag :a, :content => 'Changesets (5)'
  end

  def test_search_project_and_subprojects
    get :index, :project_id => 1, :q => 'recipe subproject', :scope => 'subprojects', :submit => 'Search'
    assert_response :success
    assert_template 'index'
    assert assigns(:results).include?(WorkPackage.find(1))
    assert assigns(:results).include?(WorkPackage.find(5))
  end

  def test_search_without_searchable_custom_fields
    CustomField.update_all "searchable = #{ActiveRecord::Base.connection.quoted_false}"

    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:project)

    get :index, :project_id => 1, :q => "can"
    assert_response :success
    assert_template 'index'
  end

  def test_search_with_searchable_custom_fields
    get :index, :project_id => 1, :q => "stringforcustomfield"
    assert_response :success
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(WorkPackage.find(7))
  end

  def test_search_all_words
    # 'all words' is on by default
    get :index, :project_id => 1, :q => 'recipe updating saving'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(WorkPackage.find(3))
  end

  def test_search_one_of_the_words
    get :index, :project_id => 1, :q => 'recipe updating saving', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 3, results.size
    assert results.include?(WorkPackage.find(3))
  end

  def test_search_titles_only_without_result
    get :index, :project_id => 1, :q => 'recipe updating saving', :all_words => '1', :titles_only => '1', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 0, results.size
  end

  def test_search_titles_only
    get :index, :project_id => 1, :q => 'recipe', :titles_only => '1', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 2, results.size
  end

  def test_search_with_invalid_project_id
    get :index, :project_id => 195, :q => 'recipe'
    assert_response 404
    assert_nil assigns(:results)
  end

  def test_quick_jump_to_work_packages
    # work_package of a public project
    get :index, :q => "3"
    assert_redirected_to '/work_packages/3'

    # work_package of a private project
    get :index, :q => "4"
    assert_response :success
    assert_template 'index'
  end

  def test_large_integer
    get :index, :q => '4615713488'
    assert_response :success
    assert_template 'index'
  end

  def test_tokens_with_quotes
    get :index, :project_id => 1, :q => '"good bye" hello "bye bye"'
    assert_equal ["good bye", "hello", "bye bye"], assigns(:tokens)
  end
end
