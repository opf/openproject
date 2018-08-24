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

module OpenProject
  class Design
    DEFAULTS = {
      'primary-color'                                        => "#1A67A3",
      'primary-color-dark'                                   => "#175A8E",
      'alternative-color'                                    => "#35C53F",
      'body-font-family'                                     => "'Lato', 'Lucida Grande', Helvetica, Arial, sans-serif",
      'gray'                                                 => "#EAEAEA",
      'gray-dark'                                            => "#878787",
      'gray-light'                                           => "#F8F8F8",
      'gray-lighter'                                         => "#E9E9E9",
      'light-gray'                                           => "#CCCCCC",
      'body-background'                                      => "#FFFFFF",
      'body-font-color'                                      => "#333333",
      'base-line-height'                                     => "1.5",
      'secondary-color'                                      => "#bfbfbf",
      'content-link-color'                                   => "$primary-color-dark",
      'font-color-on-primary'                                => "#FFFFFF",
      'font-color-on-primary-dark'                           => "#FFFFFF",
      'font-color-on-secondary'                              => "#FFFFFF",
      'font-color-on-alternative'                            => "#FFFFFF",
      'h1-font-size'                                         => "2rem",
      'h1-font-color'                                        => "$body-font-color",
      'h2-font-size'                                         => "1.5rem",
      'h2-font-color'                                        => "$body-font-color",
      'h3-font-size'                                         => "1.125rem",
      'h3-font-color'                                        => "$body-font-color",
      'h4-font-size'                                         => "calc($h3-font-size * 0.75)",
      'h4-font-color'                                        => "$body-font-color",
      'list-side-margin'                                     => "40px",
      'list-nested-margin'                                   => "30px",
      'header-height'                                        => "55px",
      'header-height-mobile'                                 => "55px",
      'header-bg-color'                                      => "$primary-color",
      'header-home-link-bg'                                  => '#{image-url("logo_openproject_white_big.png") no-repeat 20px 0}',
      'header-border-bottom-color'                           => "$primary-color",
      'header-border-bottom-width'                           => "0",
      'header-item-font-size'                                => "14px",
      'header-item-font-color'                               => "$font-color-on-primary",
      'header-item-font-hover-color'                         => "$font-color-on-primary-dark",
      'header-item-bg-hover-color'                           => "$primary-color-dark",
      'header-drop-down-bg-color'                            => "#FFFFFF",
      'header-drop-down-border-color'                        => "#DDDDDD",
      'header-drop-down-item-font-color'                     => "$body-font-color",
      'header-drop-down-item-font-hover-color'               => "$primary-color",
      'header-drop-down-projects-search-font-color'          => "$body-font-color",
      'header-drop-down-projects-search-bg-color'            => "#E0E0E0",
      'header-drop-down-projects-search-input-bg-color'      => "#F5F5F5",
      'header-drop-down-projects-search-input-border-color'  => "#D9D9D9",
      'header-search-field-bg-color'                         => "#FFFFFF",
      'header-search-field-font-color'                       => "#000000",
      'header-search-field-border'                           => "0",
      'main-menu-width'                                      => "230px",
      'main-menu-folded-width'                               => "0px",
      'main-menu-border-color'                               => "#EAEAEA",
      'main-menu-border-width'                               => "0px",
      'main-menu-item-height'                                => "40px",
      'main-menu-item-border-color'                          => "$primary-color",
      'main-menu-item-border-width'                          => "1px",
      'main-menu-enable-toggle-highlighting'                 => "false",
      'main-menu-bg-color'                                   => "#333739",
      'main-menu-bg-selected-background'                     => "#175A8E",
      'main-menu-bg-hover-background'                        => "#124E7C",
      'main-menu-font-color'                                 => "#FFFFFF",
      'main-menu-hover-font-color'                           => "$main-menu-font-color",
      'main-menu-resizer-color'                              => "$primary-color",
      'main-menu-selected-font-color'                        => "$main-menu-font-color",
      'main-menu-font-size'                                  => "14px",
      'main-menu-selected-indicator-color'                   => "#E0E0E0",
      'main-menu-hover-indicator-color'                      => "$primary-color-dark",
      'main-menu-selected-hover-indicator-width'             => "4px",
      'main-menu-selected-hover-border-color'                => "$main-menu-border-color",
      'main-menu-navigation-toggler-font-hover-color'        => "$main-menu-resizer-color",
      'main-menu-sidebar-font-color'                         => "$main-menu-font-color",
      'main-menu-sidebar-h3-color'                           => "$main-menu-font-color",
      'main-menu-sidebar-link-color'                         => "$main-menu-font-color",
      'main-menu-sidebar-h3-font-size'                       => "15px",
      'main-menu-fieldset-header-color'                      => "#B0B2B3",
      'toolbar-title-color'                                  => "#5F5F5F",
      'toolbar-item--bg-color'                               => "#F8F8F8",
      'toolbar-item--bg-color-pressed'                       => "$gray-lighter",
      'toolbar-item--border-color'                           => "#DDD",
      'breadcrumb-height'                                    => "40px",
      'breadcrumb-bg-color'                                  => "#F8F8F8",
      'breadcrumb-border-color'                              => "#E7E7E7",
      'breadcrumb-font-size'                                 => "12px",
      'breadcrumb-highlighted-font-size'                     => "14px",
      'breadcrumb-font-color'                                => "$body-font-color",
      'content-default-border-color'                         => "#EAEAEA",
      'content-default-border-width'                         => "1px",
      'content-link-hover-active-color'                      => "$primary-color-dark",
      'content-icon-link-color'                              => "#4b4b4b",
      'content-icon-link-hover-color'                        => "$primary-color-dark",
      'content-icon-link-pressed-color'                      => "#7A8995",
      'content-icon-color'                                   => "$content-link-color",
      'content-form-bg-color'                                => "#F8F8F8",
      'content-form-border'                                  => "1px solid $content-default-border-color",
      'content-from-input-width'                             => "300px",
      'content-form-input-border'                            => "1px solid #CACACA",
      'content-form-input-hover-border'                      => "1px solid #888888",
      'content-form-error-color'                             => "#9E2A1C",
      'content-form-separator-color'                         => "#DDDDDD",
      'content-form-danger-zone-bg-color'                    => "#CA3F3F",
      'content-form-danger-zone-font-color'                  => "#FFFFFF",
      'content-calendar-border-width'                        => "1px",
      'content-calendar-border-color'                        => "#D7D7D7",
      'content-calendar-head-cell-bg-color'                  => "#EEEEEE",
      'content-calendar-cell-border-width'                   => "1px",
      'content-calendar-cell-border-color'                   => "#D7D7D7",
      'content-calendar-cell-today-bg-color'                 => "#FFFFDD",
      'content-calendar-inactive-day-font-color'             => "#FFFFFF",
      'content-calendar-inactive-day-bg-color'               => "#4B4B4B",
      'my-page-edit-box-border-color'                        => "$primary-color-dark",
      'drop-down-unselected-font-color'                      => "$body-font-color",
      'drop-down-selected-font-color'                        => "$primary-color",
      'drop-down-hover-font-color'                           => "$drop-down-selected-font-color",
      'drop-down-selected-bg-color'                          => "#EFEFEF",
      'drop-down-hover-bg-color'                             => "$drop-down-selected-bg-color",
      'context-menu-unselected-font-color'                   => "$drop-down-unselected-font-color",
      'context-menu-hover-font-color'                        => "$drop-down-hover-font-color",
      'content-box-border'                                   => "1px solid $content-default-border-color",
      'content-box-bg-color'                                 => "#FFFFFF",
      'action-menu-bg-color'                                 => "#FFFFFF",
      'wiki-default-font-size'                               => "1rem",
      'wiki-toc-header-font-size'                            => "calc($wiki-default-font-size * 0.6)",
      'wiki-toc-ul-font-size'                                => "$wiki-default-font-size",
      'journal-attribute-font-size'                          => "11px",
      'repository-entry-filename-margin-left'                => "24px",
      'user-avatar-border-radius'                            => "50px",
      'user-avatar-width'                                    => "36px",
      'user-avatar-mini-border-radius'                       => "50px",
      'user-avatar-mini-width'                               => "20px",
      'select-element-padding'                               => "3px, 24px, 3px, 3px",
      'widget-box-content-bg-color'                          => "$body-background",
      'widget-box-block-bg-color'                            => "$body-background",
      'widget-box-block-border-color'                        => "$content-default-border-color",
      'homescreen-footer-bg-color'                           => "$gray-light",
      'homescreen-footer-icon-color'                         => "#7B827B",
      'inplace-edit--border-color'                           => "#ddd",
      'inplace-edit--dark-background'                        => "$gray-light",
      'inplace-edit--color--very-dark'                       => "#cacaca",
      'inplace-edit--color-highlight'                        => "$primary-color",
      'inplace-edit--selected-date-border-color'             => "$primary-color-dark",
      'inplace-edit--color--disabled'                        => "#4d4d4d",
      'inplace-edit--bg-color--disabled'                     => "#eee",
      'relations-save-button--disabled-color'                => "$gray-dark",
      'table-row-border-color'                               => "#E7E7E7",
      'table-row-highlighting-color'                         => "#CCE6F7",
      'table-row-relations-row-background-color'             => "rgba(220,235,244, 0.6)",
      'table-row-hierarchies-row-font-color'                 => "#6C7A89",
      'table-header-border-color'                            => "#D7D7D7",
      'table-header-shadow-color'                            => "#DDDDDD",
      'loading-indicator-bg-color'                           => "$body-background",
      'loading-indicator-bg-opacity'                         => "0.8",
      'loading-indicator-spinner-color'                      => "$primary-color",
      'button--font-color'                                   => "#222222",
      'button--background-color'                             => "$gray-light",
      'button--background-hover-color'                       => "#ededed",
      'button--border-color'                                 => "#dddddd",
      'button--active-font-color'                            => "#bbbbbb",
      'button--active-background-color'                      => "#eeeeee",
      'button--active-border-color'                          => "#cacaca",
      'button--alt-highlight-background-color'               => "$alternative-color",
      'button--alt-highlight-background-hover-color'         => "#227d28",
      'button--highlight-font-color'                         => "$font-color-on-primary",
      'button--highlight-background-color'                   => "$primary-color",
      'button--highlight-background-hover-color'             => "$primary-color-dark",
      'button--alt-highlight-font-color'                     => "$font-color-on-alternative",
      'button--text-icon-spacing'                            => "0.65em",
      'generic-table--font-size'                             => '0.875rem',
      'generic-table--header-font-size'                      => '0.875rem',
      'generic-table--header-height'                         => '45px',
      'generic-table--footer-height'                         => '34px',
      'timeline--header-border-color'                        => '#aaaaaa',
      'timeline--grid-color'                                 => '#dddddd',
      'timeline--separator'                                  => '3px solid #E7E7E7',
      'table-timeline--row-height'                           => '41px',
      'status-selector-bg-color'                             => '#F99601',
      'status-selector-bg-hover-color'                       => '#E08600'
    }.freeze

    # Regular expression for references of other variables.
    VARIABLE_NAME_RGX = /\$([\w-]+)/

    ##
    # Returns the name of the color scheme.
    # To be overridden by a plugin
    def self.name
      'OpenProject Theme'
    end

    def self.identifier
      :core_design
    end

    def self.overridden?
      identifier == :core_design
    end

    ##
    # Path the favicon
    def self.favicon_asset_path
      'favicon.ico'.freeze
    end

    ##
    # Returns a reference to all defined colors
    # To be used in the sass variable definition file
    def self.variables
      DEFAULTS
    end

    ##
    # Return the value after resolving all variables to values.
    def self.resolved_variables
      resolved_variables = DEFAULTS.dup

      DEFAULTS.each do |var_name, value|
        resolved_variables[var_name] = resolve_value(value)
      end
      resolved_variables
    end

    def self.resolve_value(variable_value)
      variable_value.gsub(VARIABLE_NAME_RGX) { resolve_value(DEFAULTS[$1]) }
    end

    ##
    # Returns the keys of variables that are customizable through the design
    def self.customizable_variables
      %w( primary-color
          primary-color-dark
          alternative-color
          header-bg-color
          header-item-font-color
          header-item-font-hover-color
          header-item-bg-hover-color
          header-border-bottom-color
          content-link-color
          main-menu-bg-color
          main-menu-font-color
          main-menu-bg-selected-background
          main-menu-selected-font-color
          main-menu-bg-hover-background
          main-menu-hover-font-color
          main-menu-border-color )
    end
  end
end
