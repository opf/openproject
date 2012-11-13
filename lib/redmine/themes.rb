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

module Redmine
  module Themes
    class DefaultThemeNotFoundError < StandardError
    end

    mattr_accessor :installed_themes
    self.installed_themes = Set.new

    def self.all
      themes
    end

    def self.themes
      installed_themes
    end

    def self.register(*names)
      self.installed_themes += names.map { |name| Theme.new(name.to_s) }
    end

    def self.theme(name)
      find_theme(name) || default
    end

    # TODO: always require a default theme
    def self.default
      return default_theme

      # find_theme(default_theme_name) or
      #   raise DefaultThemeNotFoundError, 'default theme was not found'
    end

    def self.find_theme(name)
      installed_themes.detect { |theme| theme.name == name.to_s }
    end

    def self.default_theme
      @default_theme ||= Theme.new
    end

    class Theme
      attr_accessor :name

      def initialize(name = :default)
        @name = name
      end

      def favicon_path
        "#{prefix}/favicon.ico"
      end

      def main_stylesheet_path
        name
      end

      def prefix
        default? ? '' : name
      end

      def default?
        name == :default
      end
    end
  end
end

module ApplicationHelper
  def current_theme
    @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
    raise DefaultThemeNotFoundError, 'default theme was not found' unless @current_theme
    @current_theme
  end
end
