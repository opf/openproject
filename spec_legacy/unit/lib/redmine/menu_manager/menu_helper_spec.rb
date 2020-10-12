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

require_relative '../../../../legacy_spec_helper'

describe Redmine::MenuManager::MenuHelper, type: :helper do
  include Redmine::MenuManager::MenuHelper
  include ::Rails::Dom::Testing::Assertions::SelectorAssertions
  fixtures :all

  # Used by assert_select
  def html_document
    Nokogiri::HTML(@response.body)
  end

  before do
    @response = ActionDispatch::TestResponse.new
    # Stub the current menu item in the controller
    def @controller.current_menu_item
      :index
    end
  end

  it 'should render single menu node' do
    node = Redmine::MenuManager::MenuItem.new(:testing, '/test', caption: 'This is a test')
    @response.body = render_single_menu_node(node)

    html_node = Nokogiri::HTML(@response.body)
    assert_select(html_node.root, 'a.testing-menu-item', 'This is a test')
  end

  it 'should render menu node' do
    single_node = Redmine::MenuManager::MenuItem.new(:single_node, '/test', {})
    @response.body = render_menu_node(single_node, nil)

    html_node = Nokogiri::HTML(@response.body)
    assert_select(html_node.root, 'li') do
      assert_select('a.single-node-menu-item', 'Single node')
    end
  end

  it 'should render menu node with nested items' do
    parent_node = Redmine::MenuManager::MenuItem.new(:parent_node, '/test', {})
    parent_node << Redmine::MenuManager::MenuItem.new(:child_one_node, '/test', {})
    parent_node << Redmine::MenuManager::MenuItem.new(:child_two_node, '/test', {})
    parent_node <<
      Redmine::MenuManager::MenuItem.new(:child_three_node, '/test', {}) <<
      Redmine::MenuManager::MenuItem.new(:child_three_inner_node, '/test', {})

    @response.body = render_menu_node(parent_node, nil)

    html_node = Nokogiri::HTML(@response.body)
    assert_select(html_node.root, 'li') do
      assert_select('a.parent-node-menu-item', 'Parent node')
      assert_select('ul') do
        assert_select('li a.child-one-node-menu-item', 'Child one node')
        assert_select('li a.child-two-node-menu-item', 'Child two node')
        assert_select('li') do
          assert_select('a.child-three-node-menu-item', 'Child three node')
          assert_select('ul') do
            assert_select('li a.child-three-inner-node-menu-item', 'Child three inner node')
          end
        end
      end
    end
  end

  it 'should render menu node with children' do
    User.current = User.find(1)

    parent_node = Redmine::MenuManager::MenuItem.new(:parent_node,
                                                     { controller: 'work_packages', action: 'index' },

                                                     children: Proc.new {|_p|
                                                       children = []
                                                       3.times do |time|
                                                         children << Redmine::MenuManager::MenuItem.new("test_child_#{time}",
                                                                                                        { controller: 'work_packages', action: 'index' },
                                                                                                        {})
                                                       end
                                                       children
                                                     }
                                                    )
    @response.body = render_menu_node(parent_node, Project.find(1))

    html_node = Nokogiri::HTML(@response.body)
    assert_select(html_node.root, 'li') do
      assert_select('a.parent-node-menu-item', 'Parent node')
      assert_select('ul') do
        assert_select('li a.test-child-0-menu-item', 'Test child 0')
        assert_select('li a.test-child-1-menu-item', 'Test child 1')
        assert_select('li a.test-child-2-menu-item', 'Test child 2')
      end
    end
  end

  it 'should render menu node with nested items and children' do
    User.current = User.find(1)

    parent_node = Redmine::MenuManager::MenuItem.new(:parent_node,
                                                     { controller: 'work_packages', action: 'index' },

                                                     children: Proc.new {|_p|
                                                       children = []
                                                       3.times do |time|
                                                         children << Redmine::MenuManager::MenuItem.new("test_child_#{time}", { controller: 'work_packages', action: 'index' }, {})
                                                       end
                                                       children
                                                     }
                                                    )

    parent_node << Redmine::MenuManager::MenuItem.new(:child_node,
                                                      { controller: 'work_packages', action: 'index' },

                                                      children: Proc.new {|_p|
                                                        children = []
                                                        6.times do |time|
                                                          children << Redmine::MenuManager::MenuItem.new("test_dynamic_child_#{time}", { controller: 'work_packages', action: 'index' }, {})
                                                        end
                                                        children
                                                      }
                                                     )

    @response.body = render_menu_node(parent_node, Project.find(1))

    html_node = Nokogiri::HTML(@response.body)
    assert_select(html_node.root, 'li') do
      assert_select('a.parent-node-menu-item', 'Parent node')
      assert_select('ul') do
        assert_select('li a.child-node-menu-item', 'Child node')
        assert_select('ul') do
          assert_select('li a.test-dynamic-child-0-menu-item', 'Test dynamic child 0')
          assert_select('li a.test-dynamic-child-1-menu-item', 'Test dynamic child 1')
          assert_select('li a.test-dynamic-child-2-menu-item', 'Test dynamic child 2')
          assert_select('li a.test-dynamic-child-3-menu-item', 'Test dynamic child 3')
          assert_select('li a.test-dynamic-child-4-menu-item', 'Test dynamic child 4')
          assert_select('li a.test-dynamic-child-5-menu-item', 'Test dynamic child 5')
        end
        assert_select('li a.test-child-0-menu-item', 'Test child 0')
        assert_select('li a.test-child-1-menu-item', 'Test child 1')
        assert_select('li a.test-child-2-menu-item', 'Test child 2')
      end
    end
  end

  it 'should render menu node with children without an array' do
    parent_node = Redmine::MenuManager::MenuItem.new(:parent_node,
                                                     { controller: 'work_packages', action: 'index' },

                                                     children: Proc.new { |_p| Redmine::MenuManager::MenuItem.new('test_child', { controller: 'work_packages', action: 'index' }, {}) },
                                                    )

    assert_raises Redmine::MenuManager::MenuError, ':children must be an array of MenuItems' do
      @response.body = render_menu_node(parent_node, Project.find(1))
    end
  end

  it 'should render menu node with incorrect children' do
    parent_node = Redmine::MenuManager::MenuItem.new(:parent_node,
                                                     { controller: 'work_packages', action: 'index' },

                                                     children: Proc.new { |_p| ['a string'] }
                                                    )

    assert_raises Redmine::MenuManager::MenuError, ':children must be an array of MenuItems' do
      @response.body = render_menu_node(parent_node, Project.find(1))
    end
  end

  it 'should first level menu items for should yield all items if passed a block' do
    menu_name = :test_first_level_menu_items_for_should_yield_all_items_if_passed_a_block
    Redmine::MenuManager.map menu_name do |menu|
      menu.push(:a_menu, '/', {})
      menu.push(:a_menu_2, '/', {})
      menu.push(:a_menu_3, '/', {})
    end

    items_yielded = []
    first_level_menu_items_for(menu_name) do |item|
      items_yielded << item
    end

    assert_equal 3, items_yielded.size
  end

  it 'should first level menu items for should return all items' do
    menu_name = :test_first_level_menu_items_for_should_return_all_items
    Redmine::MenuManager.map menu_name do |menu|
      menu.push(:a_menu, '/', {})
      menu.push(:a_menu_2, '/', {})
      menu.push(:a_menu_3, '/', {})
    end

    items = first_level_menu_items_for(menu_name)
    assert_equal 3, items.size
  end

  it 'should first level menu items for should skip unallowed items on a project' do
    menu_name = :test_first_level_menu_items_for_should_skip_unallowed_items_on_a_project
    Redmine::MenuManager.map menu_name do |menu|
      menu.push(:a_menu, { controller: 'work_packages', action: 'index' }, {})
      menu.push(:a_menu_2, { controller: 'work_packages', action: 'index' }, {})
      menu.push(:unallowed, { controller: 'work_packages', action: 'unallowed' }, {})
    end

    User.current = User.find(1)

    items = first_level_menu_items_for(menu_name, Project.find(1))
    assert_equal 2, items.size
  end

  it 'should first level menu items for should skip items that fail the conditions' do
    menu_name = :test_first_level_menu_items_for_should_skip_items_that_fail_the_conditions
    Redmine::MenuManager.map menu_name do |menu|
      menu.push(:a_menu, { controller: 'work_packages', action: 'index' }, {})
      menu.push(:unallowed,
                { controller: 'work_packages', action: 'index' },
                if: Proc.new { false })
    end

    User.current = User.find(1)

    items = first_level_menu_items_for(menu_name, Project.find(1))
    assert_equal 1, items.size
  end
end
