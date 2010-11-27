# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../../../test_helper'

class Redmine::ThemesTest < ActiveSupport::TestCase
  
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
