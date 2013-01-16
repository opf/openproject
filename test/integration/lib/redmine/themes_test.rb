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

class ThemesTest < ActionDispatch::IntegrationTest
  include MiniTest::Assertions

  fixtures :all

  def setup
    @theme = Redmine::Themes.default_theme
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

  def test_without_theme_js
    pending "no custom javascript for themes currently"

    get '/'

    assert_response :success
    assert_no_tag :tag => 'script',
      :attributes => {:src => '/assets/default.js'}
  end

  def test_with_theme_js
    pending "no custom javascript for themes currently"

    # Simulates a theme.js
    @theme.javascripts << 'theme'
    get '/'

    assert_response :success
    assert_tag :tag => 'script',
      :attributes => {:src => '/assets/default.js'}

  ensure
    # @theme.javascripts.delete 'theme'
  end

  def test_with_sub_uri
    pending "no relative url root for themes currently"

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
