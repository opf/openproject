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
require 'legacy_spec_helper'

module RedmineMenuTestHelper
  # Helpers
  def get_menu_item(menu_name, item_name)
    Redmine::MenuManager.items(menu_name).find { |item| item.name == item_name.to_sym }
  end
end

describe Redmine::MenuManager::MenuItem do
  include RedmineMenuTestHelper

  Redmine::MenuManager.map :test_menu do |menu|
    menu.push(:parent, '/test', {})
    menu.push(:child_menu, '/test',  parent: :parent)
    menu.push(:child2_menu, '/test',  parent: :parent)
  end

  # context new menu item
  it 'should new menu item should require a name' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new
    end
  end

  it 'should new menu item should require an url' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_missing_url)
    end
  end

  it 'should new menu item should require the options' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_missing_options, '/test')
    end
  end

  it 'should new menu item with all required parameters' do
    assert Redmine::MenuManager::MenuItem.new(:test_good_menu, '/test', {})
  end

  it 'should new menu item should require a proc to use for the if condition' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_error, '/test',

                                         if: ['not_a_proc']
                                        )
    end

    assert Redmine::MenuManager::MenuItem.new(:test_good_if, '/test',

                                              if: Proc.new {}
                                             )
  end

  it 'should new menu item should allow a hash for extra html options' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_error, '/test',

                                         html: ['not_a_hash']
                                        )
    end

    assert Redmine::MenuManager::MenuItem.new(:test_good_html, '/test',

                                              html: { onclick: 'doSomething' }
                                             )
  end

  it 'should new menu item should require a proc to use the children option' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_error, '/test',

                                         children: ['not_a_proc']
                                        )
    end

    assert Redmine::MenuManager::MenuItem.new(:test_good_children, '/test',

                                              children: Proc.new {}
                                             )
  end

  it 'should new should not allow setting the parent item to the current item' do
    assert_raises ArgumentError do
      Redmine::MenuManager::MenuItem.new(:test_error, '/test',  parent: :test_error)
    end
  end

  it 'should has children' do
    parent_item = get_menu_item(:test_menu, :parent)
    assert parent_item.has_children?
    assert_equal 2, parent_item.children.size
    assert_equal get_menu_item(:test_menu, :child_menu).name, parent_item.children[0].name
    assert_equal get_menu_item(:test_menu, :child2_menu).name, parent_item.children[1].name
  end
end
