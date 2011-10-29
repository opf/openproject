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
require File.expand_path('../../../../test_helper', __FILE__)

class MenuManagerTest < ActionController::IntegrationTest
  include Redmine::I18n

  fixtures :all

  def test_project_menu_with_specific_locale
    get 'projects/ecookbook/issues', { }, 'Accept-Language' => 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3'

    assert_tag :div, :attributes => { :id => 'main-menu' },
                     :descendant => { :tag => 'li', :child => { :tag => 'a', :content => ll('fr', :label_activity),
                                                                             :attributes => { :href => '/projects/ecookbook/activity',
                                                                                              :class => 'activity' } } }
    assert_tag :div, :attributes => { :id => 'main-menu' },
                     :descendant => { :tag => 'li', :child => { :tag => 'a', :content => ll('fr', :label_issue_plural),
                                                                             :attributes => { :href => '/projects/ecookbook/issues',
                                                                                              :class => 'issues selected' } } }
  end

  def test_project_menu_with_additional_menu_items
    Setting.default_language = 'en'
    assert_no_difference 'Redmine::MenuManager.items(:project_menu).size' do
      Redmine::MenuManager.map :project_menu do |menu|
        menu.push :foo, { :controller => 'projects', :action => 'show' }, :caption => 'Foo'
        menu.push :bar, { :controller => 'projects', :action => 'show' }, :before => :activity
        menu.push :hello, { :controller => 'projects', :action => 'show' }, :caption => Proc.new {|p| p.name.upcase }, :after => :bar
      end

      get 'projects/ecookbook'
      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'Foo',
                                                                               :attributes => { :class => 'foo' } } }

      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'Bar',
                                                                               :attributes => { :class => 'bar' } },
                                                      :before => { :tag => 'li', :child => { :tag => 'a', :content => 'ECOOKBOOK' } } }

      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'ECOOKBOOK',
                                                                               :attributes => { :class => 'hello' } },
                                                      :before => { :tag => 'li', :child => { :tag => 'a', :content => 'Activity' } } }

      # Remove the menu items
      Redmine::MenuManager.map :project_menu do |menu|
        menu.delete :foo
        menu.delete :bar
        menu.delete :hello
      end
    end
  end
end
