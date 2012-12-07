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
require 'active_support/core_ext/module/attribute_accessors'
require 'redmine/themes/theme'

module Redmine
  module Themes
    mattr_accessor :installed_themes
    self.installed_themes = Set.new

    def self.all
      themes
    end

    def self.themes
      installed_themes.to_a
    end

    def self.register(*themes)
      self.installed_themes += themes.collect { |theme| Theme.from(theme) }
      all
    end

    def self.theme(name)
      find_theme(name) || default_theme
    end

    def self.find_theme(name)
      theme_to_find = Theme.from(name)
      installed_themes.detect { |theme| theme == theme_to_find }
    end

    def self.new_theme(name)
      Theme.new name
    end

    def self.default_theme
      Theme.default
    end

    def self.clear
      installed_themes.clear
    end

    def self.each(&block)
      installed_themes.each(&block)
    end
    extend Enumerable

    def self.register_default_theme
      register default_theme
    end

    self.register_default_theme # called on load
  end
end

module ApplicationHelper
  def current_theme
    @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
  end
end

