#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require File.expand_path('../../../../test_helper', __FILE__)

class ThemesTest < ActionDispatch::IntegrationTest
  include MiniTest::Assertions

  fixtures :all

  def setup
    super
    @theme = OpenProject::Themes.default_theme
    Setting.ui_theme = @theme.identifier
  end

  def teardown
    super
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
      OpenProject::Configuration['rails_relative_url_root'] = '/foo'
      @theme.javascripts << 'theme'
      get '/'

      assert_response :success
      assert_tag :tag => 'link',
        :attributes => {:src => '/foo/assets/default.js'}
      assert_tag :tag => 'script',
        :attributes => {:src => '/foo/assets/default.js'}
    ensure
      OpenProject::Configuration['rails_relative_url_root'] = ''
    end
  end
end
