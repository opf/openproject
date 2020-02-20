#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::CustomStyles
  class ColorThemes
    THEMES = [
      {
        name:                                                   'OpenProject',
        colors: {
          'primary-color'                                        => "#1A67A3",
          'primary-color-dark'                                   => "#175A8E",
          'alternative-color'                                    => "#35C53F",
          'content-link-color'                                   => "#175A8E",
          'header-bg-color'                                      => "#1A67A3",
          'header-item-bg-hover-color'                           => "#175A8E",
          'header-item-font-color'                               => "#FFFFFF",
          'header-item-font-hover-color'                         => "#FFFFFF",
          'header-border-bottom-color'                           => "",
          'main-menu-bg-color'                                   => "#333739",
          'main-menu-bg-selected-background'                     => "#175A8E",
          'main-menu-bg-hover-background'                        => "#124E7C",
          'main-menu-font-color'                                 => "#FFFFFF",
          'main-menu-hover-font-color'                           => "#FFFFFF",
          'main-menu-selected-font-color'                        => "#FFFFFF",
          'main-menu-border-color'                               => "#EAEAEA"
        }
      },
      {
        name:                                                   'OpenProject Light',
        colors: {
          'primary-color'                                        => "#1A67A3",
          'primary-color-dark'                                   => "#175A8E",
          'alternative-color'                                    => "#138E1B",
          'content-link-color'                                   => "#175A8E",
          'header-bg-color'                                      => "#FAFAFA",
          'header-item-bg-hover-color'                           => "#E1E1E1",
          'header-item-font-color'                               => "#313131",
          'header-item-font-hover-color'                         => "#313131",
          'header-border-bottom-color'                           => "#E1E1E1",
          'main-menu-bg-color'                                   => "#ECECEC",
          'main-menu-bg-selected-background'                     => "#A9A9A9",
          'main-menu-bg-hover-background'                        => "#FFFFFF",
          'main-menu-font-color'                                 => "#000000",
          'main-menu-hover-font-color'                           => "#000000",
          'main-menu-selected-font-color'                        => "#000000",
          'main-menu-border-color'                               => "#EAEAEA"
        },
        logo:                                                   'logo_openproject.png'
      },
      {
        name:                                                   'OpenProject Dark',
        colors: {
          'primary-color'                                        => "#3270DB",
          'primary-color-dark'                                   => "#163473",
          'alternative-color'                                    => "#349939",
          'content-link-color'                                   => "#275BB5",
          'header-bg-color'                                      => "#05002C",
          'header-item-bg-hover-color'                           => "#163473",
          'header-item-font-color'                               => "#FFFFFF",
          'header-item-font-hover-color'                         => "#FFFFFF",
          'header-border-bottom-color'                           => "",
          'main-menu-bg-color'                                   => "#0E2045",
          'main-menu-bg-selected-background'                     => "#3270DB",
          'main-menu-bg-hover-background'                        => "#163473",
          'main-menu-font-color'                                 => "#FFFFFF",
          'main-menu-hover-font-color'                           => "#FFFFFF",
          'main-menu-selected-font-color'                        => "#FFFFFF",
          'main-menu-border-color'                               => "#EAEAEA"
        }
      }
    ].freeze
  end
end
