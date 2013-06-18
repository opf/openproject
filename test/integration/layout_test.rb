#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class LayoutTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "browsing to a missing page should render the base layout" do
    get "/users/100000000"

    assert_response :not_found

    # UsersController uses the admin layout by default
    assert_select "#main-menu", :count => 0
  end

  test "browsing to an unauthorized page should render the base layout" do
    change_user_password('miscuser9', 'testTestTest!')

    log_user('miscuser9','testTestTest!')

    get "/admin"
    assert_response :forbidden
    assert_select "#main-menu", :count => 0
  end

  def test_top_menu_navigation_not_visible_when_login_required
    with_settings :login_required => '1' do
      get '/'
      assert_select "#account-nav", 0
    end
  end

  def test_top_menu_navigation_visible_when_login_not_required
    with_settings :login_required => '0' do
      get '/'
      assert_select "#account-nav"
    end
  end

  test "page titles should be properly escaped" do
    project = Project.generate(:name => "C&A")

    with_settings :app_title => '<3' do
      get "/projects/#{project.to_param}"

      html_node = HTML::Document.new(@response.body)

      assert_select html_node.root, "title", /C&amp;A/
      assert_select html_node.root, "title", /&lt;3/
    end
  end
end
