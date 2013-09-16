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
require 'members_controller'

# Re-raise errors caught by the controller.
class MembersController; def rescue_action(e) raise e end; end


class MembersControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = MembersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2
  end

  def test_create
    assert_difference 'Member.count' do
      post :create, :id => 1, :member => {:role_ids => [1], :user_id => 7}
   end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert User.find(7).member_of?(Project.find(1))
  end

  def test_create_multiple
    assert_difference 'Member.count', 3 do
      post :create, :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert User.find(7).member_of?(Project.find(1))
  end

  context "post :create in JS format" do
    context "with successful saves" do
      should "add membership for each user" do
        post :create, :format => "js", :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}

        assert User.find(7).member_of?(Project.find(1))
        assert User.find(8).member_of?(Project.find(1))
        assert User.find(9).member_of?(Project.find(1))
      end

      should "replace the tab with RJS" do
        post :create, :format => "js", :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}

        assert_select_rjs :replace_html, 'tab-content-members'
      end

    end

    context "with a failed save" do
      should "not replace the tab with RJS" do
        post :create, :format => "js", :id => 1, :member => {:role_ids => [], :user_ids => [7, 8, 9]}

        assert_select '#tab-content-members', 0
      end

      should "show an error message" do
        post :create, :format => "js", :id => 1, :member => {:role_ids => [], :user_ids => [7, 8, 9]}

        assert_select_rjs :insert_html, :top do
          assert_select '#errorExplanation'
        end
      end
    end

  end

  def test_update
    assert_no_difference 'Member.count' do
      put :update, :id => 2, :member => {:role_ids => [1], :user_id => 3}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
  end

  def test_destroy
    assert_difference 'Member.count', -1 do
      delete :destroy, :id => 2
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert !User.find(3).member_of?(Project.find(1))
  end
end
