#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module AccessibilityHelper
  def you_are_here_info(condition = true, disabled = nil)
    if condition && !disabled
      "<span style = 'display: block' class = 'position-label hidden-for-sighted'>#{l(:description_current_position)}</span>".html_safe
    elsif condition && disabled
      "<span style = 'display: none' class = 'position-label hidden-for-sighted'>#{l(:description_current_position)}</span>".html_safe
    else
      ''
    end
  end

  def empty_element_tag
    @empty_element_tag ||= ApplicationController.new.render_to_string(partial: 'accessibility/empty_element_tag').html_safe
  end

  # Return true if the difference between two colors
  # matches the W3C recommendations for readability
  # See http://www.wat-c.org/tools/CCA/1.1/
  def colors_diff_ok?(color_1, color_2)
    cont, bright = find_color_diff color_1, color_2
    (cont > 500) && (bright > 125) # Acceptable diff according to w3c
  end

  def color_contrast(color)
    _, bright = find_color_diff 0x000000, color
    (bright > 128)
  end

  # Returns the locale :en for the given menu item if the user locale is
  # different but equals the English translation
  #
  # Returns nil if user locale is :en (English) or no translation is given,
  # thus, assumes English to be the default language. Returns :en iff a
  # translation exists and the translation equals the English one.
  def menu_item_locale(menu_item)
    return nil if english_locale_set?

    caption_content = menu_item.instance_variable_get(:@caption)
    locale_label = caption_content.is_a?(Symbol) ? caption_content : :"label_#{menu_item.name.to_s}"

    (!locale_exists?(locale_label) || equals_english_locale(locale_label)) ? :en : nil
  end

  private

  # Return the contrast and brightness difference between two RGB values
  def find_color_diff(c1, c2)
    r1, g1, b1 = break_color c1
    r2, g2, b2 = break_color c2
    cont_diff = (r1 - r2).abs + (g1 - g2).abs + (b1 - b2).abs # Color contrast
    bright1 = (r1 * 299 + g1 * 587 + b1 * 114) / 1000
    bright2 = (r2 * 299 + g2 * 587 + b2 * 114) / 1000
    brt_diff = (bright1 - bright2).abs # Color brightness diff
    [cont_diff, brt_diff]
  end

  # Break a color into the R, G and B components
  def break_color(rgb)
    r = (rgb & 0xff0000) >> 16
    g = (rgb & 0x00ff00) >> 8
    b = rgb & 0x0000ff
    [r, g, b]
  end

  def locale_exists?(key, locale = I18n.locale)
    I18n.t(key, locale: locale, raise: true) rescue false
  end

  def english_locale_set?
    I18n.locale == :en
  end

  def equals_english_locale(key)
    key.is_a?(Symbol) ? (I18n.t(key) == I18n.t(key, locale: :en)) : false
  end
end
