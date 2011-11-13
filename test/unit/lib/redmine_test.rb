#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

module RedmineMenuTestHelper
  # Assertions
  def assert_number_of_items_in_menu(menu_name, count)
    assert Redmine::MenuManager.items(menu_name).size >= count, "Menu has less than #{count} items"
  end

  def assert_menu_contains_item_named(menu_name, item_name)
    assert Redmine::MenuManager.items(menu_name).collect(&:name).include?(item_name.to_sym), "Menu did not have an item named #{item_name}"
  end

  # Helpers
  def get_menu_item(menu_name, item_name)
    Redmine::MenuManager.items(menu_name).find {|item| item.name == item_name.to_sym}
  end
end

class RedmineTest < ActiveSupport::TestCase
  include RedmineMenuTestHelper

  def test_top_menu
    assert_number_of_items_in_menu :top_menu, 5
    assert_menu_contains_item_named :top_menu, :home
    assert_menu_contains_item_named :top_menu, :my_page
    assert_menu_contains_item_named :top_menu, :projects
    assert_menu_contains_item_named :top_menu, :administration
    assert_menu_contains_item_named :top_menu, :help
  end

  def test_account_menu
    assert_number_of_items_in_menu :account_menu, 2
    assert_menu_contains_item_named :account_menu, :my_account
    assert_menu_contains_item_named :account_menu, :logout
  end

  def test_application_menu
    assert_number_of_items_in_menu :application_menu, 0
  end

  def test_admin_menu
    assert_number_of_items_in_menu :admin_menu, 0
  end

  def test_project_menu
    assert_number_of_items_in_menu :project_menu, 14
    assert_menu_contains_item_named :project_menu, :overview
    assert_menu_contains_item_named :project_menu, :activity
    assert_menu_contains_item_named :project_menu, :roadmap
    assert_menu_contains_item_named :project_menu, :issues
    assert_menu_contains_item_named :project_menu, :new_issue
    assert_menu_contains_item_named :project_menu, :calendar
    assert_menu_contains_item_named :project_menu, :gantt
    assert_menu_contains_item_named :project_menu, :news
    assert_menu_contains_item_named :project_menu, :documents
    assert_menu_contains_item_named :project_menu, :wiki
    assert_menu_contains_item_named :project_menu, :boards
    assert_menu_contains_item_named :project_menu, :files
    assert_menu_contains_item_named :project_menu, :repository
    assert_menu_contains_item_named :project_menu, :settings
  end

  def test_new_issue_should_have_root_as_a_parent
    new_issue = get_menu_item(:project_menu, :new_issue)
    assert_equal :root, new_issue.parent.name
  end
end
