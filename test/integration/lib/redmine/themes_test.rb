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

class ThemesTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    @theme = Redmine::Themes.themes.last
    Setting.ui_theme = @theme.id
  end

  def teardown
    Setting.ui_theme = ''
  end

  def test_application_css
    get '/'

    assert_response :success
    assert_tag :tag => 'link',
      :attributes => {:href => %r{^/themes/#{@theme.dir}/stylesheets/application.css}}
  end

  def test_without_theme_js
    get '/'

    assert_response :success
    assert_no_tag :tag => 'script',
      :attributes => {:src => %r{^/themes/#{@theme.dir}/javascripts/theme.js}}
  end

  def test_with_theme_js
    # Simulates a theme.js
    @theme.javascripts << 'theme'
    get '/'

    assert_response :success
    assert_tag :tag => 'script',
      :attributes => {:src => %r{^/themes/#{@theme.dir}/javascripts/theme.js}}

  ensure
    @theme.javascripts.delete 'theme'
  end

  def test_with_sub_uri
    Redmine::Utils.relative_url_root = '/foo'
    @theme.javascripts << 'theme'
    get '/'

    assert_response :success
    assert_tag :tag => 'link',
      :attributes => {:href => %r{^/foo/themes/#{@theme.dir}/stylesheets/application.css}}
    assert_tag :tag => 'script',
      :attributes => {:src => %r{^/foo/themes/#{@theme.dir}/javascripts/theme.js}}

  ensure
    Redmine::Utils.relative_url_root = ''
  end
end
