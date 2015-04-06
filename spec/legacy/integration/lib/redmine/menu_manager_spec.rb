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

describe 'MenuManager' do
  include Redmine::I18n

  fixtures :all

  around do |example|
    with_settings login_required: '0' do
      example.run
    end
  end

  it 'project menu with specific locale' do
    Setting.available_languages = [:de, :en]
    get 'projects/ecookbook', {}, 'HTTP_ACCEPT_LANGUAGE' => 'de,de-de;q=0.8,en-us;q=0.5,en;q=0.3'

    assert_tag :div, attributes: { id: 'main-menu' },
                     descendant: { tag: 'li', child: { tag: 'a', content: ll('de', :label_activity),
                                                       attributes: { href: '/projects/ecookbook/activity',
                                                                     class: 'icon2 icon-yes activity-menu-item ellipsis' } } }
    assert_tag :div, attributes: { id: 'main-menu' },
                     descendant: { tag: 'li', child: { tag: 'a', content: ll('de', :label_overview),
                                                       attributes: { href: '/projects/ecookbook',
                                                                     class: 'icon2 icon-list-view2 overview-menu-item ellipsis selected' } } }
  end

  it 'project menu with additional menu items' do
    Setting.default_language = 'en'
    assert_no_difference 'Redmine::MenuManager.items(:project_menu).size' do
      Redmine::MenuManager.map :project_menu do |menu|
        menu.push :foo, { controller: 'projects', action: 'show' }, caption: 'Foo'
        menu.push :bar, { controller: 'projects', action: 'show' }, before: :activity
        menu.push :hello, { controller: 'projects', action: 'show' }, caption: Proc.new { |p| p.name.upcase }, after: :bar
      end

      get 'projects/ecookbook'
      assert_tag :div, attributes: { id: 'main-menu' },
                       descendant: { tag: 'li', child: { tag: 'a', content: 'Foo',
                                                         attributes: { class: 'foo-menu-item ellipsis' } } }

      assert_tag :div, attributes: { id: 'main-menu' },
                       descendant: { tag: 'li', child: { tag: 'a', content: 'Bar',
                                                         attributes: { class: 'bar-menu-item ellipsis' } },
                                     before: { tag: 'li', child: { tag: 'a', content: 'ECOOKBOOK' } } }

      assert_tag :div, attributes: { id: 'main-menu' },
                       descendant: { tag: 'li', child: { tag: 'a', content: 'ECOOKBOOK',
                                                         attributes: { class: 'hello-menu-item ellipsis' } },
                                     before: { tag: 'li', child: { tag: 'a', content: 'Activity' } } }

      # Remove the menu items
      Redmine::MenuManager.map :project_menu do |menu|
        menu.delete :foo
        menu.delete :bar
        menu.delete :hello
      end
    end
  end

  it 'dynamic menu' do
    list = []
    Redmine::MenuManager.map :some_menu do |menu|
      list.each do |item|
        menu.push item[:name], item[:url], item[:options]
      end
    end

    base_size = Redmine::MenuManager.items(:some_menu).size
    list.push(name: :foo, url: { controller: 'projects', action: 'show' }, options: { caption: 'Foo' })
    assert_equal base_size + 1, Redmine::MenuManager.items(:some_menu).size
    list.push(name: :bar, url: { controller: 'projects', action: 'show' }, options: { caption: 'Bar' })
    assert_equal base_size + 2, Redmine::MenuManager.items(:some_menu).size
    list.push(name: :hello, url: { controller: 'projects', action: 'show' }, options: { caption: 'Hello' })
    assert_equal base_size + 3, Redmine::MenuManager.items(:some_menu).size
    list.pop
    assert_equal base_size + 2, Redmine::MenuManager.items(:some_menu).size
  end

  it 'dynamic menu map deferred' do
    assert_no_difference 'Redmine::MenuManager.items(:some_menu).size' do
      Redmine::MenuManager.map(:some_other_menu).push :baz, { controller: 'projects', action: 'show' }, caption: 'Baz'
      Redmine::MenuManager.map(:some_other_menu).delete :baz
    end
  end
end
