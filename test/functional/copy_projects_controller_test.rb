#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require 'copy_projects_controller'

# Re-raise errors caught by the controller.
class CopyProjectsController; def rescue_action(e) raise e end; end

class CopyProjectsControllerTest < ActionController::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  def setup
    super
    @controller = CopyProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end

  def test_copy_with_project
    @request.session[:user_id] = 1 # admin
    get :copy_project, :id => 1, :coming_from => "settings"
    assert_response :success
    assert_template 'copy_from_settings'
    assert assigns(:project)
    assert_equal Project.find(1).description, assigns(:project).description
    assert_nil assigns(:copy_project).id
  end

  def test_copy_without_project
    @request.session[:user_id] = 1 # admin
    get :copy_project
    assert_response 404
  end

  context "POST :copy" do
    should "TODO: test the rest of the method"

    should "redirect to the project settings when successful" do
      @request.session[:user_id] = 1 # admin
      post :copy, :id => 1, :project => {:name => 'Copy', :identifier => 'unique-copy'}
      assert_response :redirect
      assert_redirected_to :controller => 'projects', :action => 'settings', :id => 'unique-copy'
    end
  end
end