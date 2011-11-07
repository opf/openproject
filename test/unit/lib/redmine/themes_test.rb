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

class Redmine::ThemesTest < ActiveSupport::TestCase
  def setup
    Redmine::Themes.rescan
  end
  
  def test_themes
    themes = Redmine::Themes.themes
    assert_kind_of Array, themes
    assert_kind_of Redmine::Themes::Theme, themes.first
  end

  def test_rescan
    Redmine::Themes.themes.pop

    assert_difference 'Redmine::Themes.themes.size' do
      Redmine::Themes.rescan
    end
  end

  def test_theme_loaded
    theme = Redmine::Themes.themes.last

    assert_equal theme, Redmine::Themes.theme(theme.id)
  end

  def test_theme_loaded_without_rescan
    theme = Redmine::Themes.themes.last

    assert_equal theme, Redmine::Themes.theme(theme.id, :rescan => false)
  end

  def test_theme_not_loaded
    theme = Redmine::Themes.themes.pop

    assert_equal theme, Redmine::Themes.theme(theme.id)
  end

  def test_theme_not_loaded_without_rescan
    theme = Redmine::Themes.themes.pop

    assert_nil Redmine::Themes.theme(theme.id, :rescan => false)
  end
end
