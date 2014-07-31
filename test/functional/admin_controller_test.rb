#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_no_tag :tag => 'div',
                  :attributes => { :class => /nodata/ }
  end

  def test_index_with_no_configuration_data
    delete_configuration_data
    get :projects
    assert_tag :tag => 'div',
               :attributes => { :class => /nodata/ }
  end

  def test_projects
    get :projects
    assert_response :success
    assert_template 'projects'
    assert_not_nil assigns(:projects)
    # active projects only
    assert_nil assigns(:projects).detect {|u| !u.active?}
  end

  def test_projects_with_name_filter
    get :projects, :name => 'store', :status => ''
    assert_response :success
    assert_template 'projects'
    projects = assigns(:projects)
    assert_not_nil projects
    assert_equal 1, projects.size
    assert_equal 'OnlineStore', projects.first.name
  end

  def test_load_default_configuration_data
    Setting.available_languages = [:de]
    delete_configuration_data
    post :default_configuration, :lang => 'de'
    assert_response :redirect
    assert_nil flash[:error]
    assert Status.find_by_name('neu')
  end

  def test_test_email
    get :test_email
    assert_redirected_to '/settings/edit?tab=notifications'
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of Mail::Message, mail
    user = User.find(1)
    assert_equal [user.mail], mail.to
  end

  def test_no_plugins
    Redmine::Plugin.clear

    get :plugins
    assert_response :success
    assert_template 'plugins'
  end

  def test_plugins
    # Register a few plugins
    Redmine::Plugin.register :foo do
      name 'Foo plugin'
      author 'John Smith'
      description 'This is a test plugin'
      version '0.0.1'
      settings :default => {'sample_setting' => 'value', 'foo'=>'bar'}, :partial => 'foo/settings'
    end
    Redmine::Plugin.register :bar do
    end

    get :plugins
    assert_response :success
    assert_template 'plugins'

    assert_tag :td, :child => { :tag => 'span', :content => 'Foo plugin' }
    assert_tag :td, :child => { :tag => 'span', :content => 'Bar' }
  end

  def test_info
    get :info
    assert_response :success
    assert_template 'info'
  end

  def test_admin_menu_plugin_extension
    Redmine::MenuManager.map :admin_menu do |menu|
      menu.push :test_admin_menu_plugin_extension,
                { :controller => 'projects', :action => 'index' },
                :caption => 'Test'
    end

    User.current = User.find(1)

    get :projects
    assert_response :success
    assert_tag :a, :attributes => { :href => '/projects' },
                   :content => 'Test'

    Redmine::MenuManager.map :admin_menu do |menu|
      menu.delete :test_admin_menu_plugin_extension
    end
  end

  private

  def delete_configuration_data
    Role.delete_all('builtin = 0')
    Type.delete_all
    Status.delete_all
    Enumeration.delete_all
  end
end
