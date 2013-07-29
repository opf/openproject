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
require File.expand_path('../../../../test_helper', __FILE__)

class ThemesTest < ActionDispatch::IntegrationTest
  include MiniTest::Assertions

  fixtures :all

  def setup
    @theme = OpenProject::Themes.default_theme
    Setting.ui_theme = @theme.identifier
  end

  def teardown
    Setting.ui_theme = nil
  end

  def test_application_css
    get '/'

    assert_response :success
    assert_tag :tag => 'link',
      :attributes => {:href => '/assets/default.css'}
  end

  should_eventually 'test_without_theme_js' do
    get '/'

    assert_response :success
    assert_no_tag :tag => 'script',
      :attributes => {:src => '/assets/default.js'}
  end

  should_eventually 'test_with_theme_js' do
    begin
      # Simulates a theme.js
      @theme.javascripts << 'theme'
      get '/'

      assert_response :success
      assert_tag :tag => 'script',
        :attributes => {:src => '/assets/default.js'}
    ensure
      @theme.javascripts.delete 'theme'
    end
  end

  should_eventually 'test_with_sub_uri' do
    begin
      Redmine::Utils.relative_url_root = '/foo'
      @theme.javascripts << 'theme'
      get '/'

      assert_response :success
      assert_tag :tag => 'link',
        :attributes => {:src => '/foo/assets/default.js'}
      assert_tag :tag => 'script',
        :attributes => {:src => '/foo/assets/default.js'}
    ensure
      Redmine::Utils.relative_url_root = ''
    end
  end
end
