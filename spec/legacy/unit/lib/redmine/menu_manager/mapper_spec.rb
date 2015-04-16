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

describe Redmine::MenuManager::Mapper do
  context 'Mapper#initialize' do
    it 'should be tested'
  end

  it 'should push onto root' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}

    menu_mapper.exists?(:test_overview)
  end

  it 'should push onto parent' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_child, { controller: 'projects', action: 'show' }, parent: :test_overview

    assert menu_mapper.exists?(:test_child)
    assert_equal :test_child, menu_mapper.find(:test_child).name
  end

  it 'should push onto grandparent' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_child, { controller: 'projects', action: 'show' }, parent: :test_overview
    menu_mapper.push :test_grandchild, { controller: 'projects', action: 'show' }, parent: :test_child

    assert menu_mapper.exists?(:test_grandchild)
    grandchild = menu_mapper.find(:test_grandchild)
    assert_equal :test_grandchild, grandchild.name
    assert_equal :test_child, grandchild.parent.name
  end

  it 'should push first' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_second, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_third, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fourth, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fifth, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_first, { controller: 'projects', action: 'show' }, first: true

    root = menu_mapper.find(:root)
    assert_equal 5, root.children.size
    { 0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth }.each do |position, name|
      assert_not_nil root.children[position]
      assert_equal name, root.children[position].name
    end
  end

  it 'should push before' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_first, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_second, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fourth, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fifth, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_third, { controller: 'projects', action: 'show' }, before: :test_fourth

    root = menu_mapper.find(:root)
    assert_equal 5, root.children.size
    { 0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth }.each do |position, name|
      assert_not_nil root.children[position]
      assert_equal name, root.children[position].name
    end
  end

  it 'should push after' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_first, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_second, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_third, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fifth, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fourth, { controller: 'projects', action: 'show' }, after: :test_third

    root = menu_mapper.find(:root)
    assert_equal 5, root.children.size
    { 0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth }.each do |position, name|
      assert_not_nil root.children[position]
      assert_equal name, root.children[position].name
    end
  end

  it 'should push last' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_first, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_second, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_third, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_fifth, { controller: 'projects', action: 'show' }, last: true
    menu_mapper.push :test_fourth, { controller: 'projects', action: 'show' }, {}

    root = menu_mapper.find(:root)
    assert_equal 5, root.children.size
    { 0 => :test_first, 1 => :test_second, 2 => :test_third, 3 => :test_fourth, 4 => :test_fifth }.each do |position, name|
      assert_not_nil root.children[position]
      assert_equal name, root.children[position].name
    end
  end

  it 'should exists for child node' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}
    menu_mapper.push :test_child, { controller: 'projects', action: 'show' }, parent: :test_overview

    assert menu_mapper.exists?(:test_child)
  end

  it 'should exists for invalid node' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}

    assert !menu_mapper.exists?(:nothing)
  end

  it 'should find' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}

    item = menu_mapper.find(:test_overview)
    assert_equal :test_overview, item.name
    assert_equal({ controller: 'projects', action: 'show' }, item.url)
  end

  it 'should find missing' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}

    item = menu_mapper.find(:nothing)
    assert_equal nil, item
  end

  it 'should delete' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    menu_mapper.push :test_overview, { controller: 'projects', action: 'show' }, {}
    assert_not_nil menu_mapper.delete(:test_overview)

    assert_nil menu_mapper.find(:test_overview)
  end

  it 'should delete missing' do
    menu_mapper = Redmine::MenuManager::Mapper.new(:test_menu, {})
    assert_nil menu_mapper.delete(:test_missing)
  end

  specify 'deleting all items' do
    # Exposed by deleting :last items
    Redmine::MenuManager.map :test_menu do |menu|
      menu.push :not_last, OpenProject::Info.help_url
      menu.push :administration, { controller: 'projects', action: 'show' }, last: true
      menu.push :help, OpenProject::Info.help_url, last: true
    end

    assert_nothing_raised do
      Redmine::MenuManager.map :test_menu do |menu|
        menu.delete(:administration)
        menu.delete(:help)
        menu.push :test_overview, { controller: 'projects', action: 'show' }, {}
      end
    end
  end
end
