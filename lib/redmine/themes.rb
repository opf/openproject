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

    def self.register(*themes)
      self.installed_themes += themes.map { |theme| Theme.from(theme) }
    end

    def self.theme(name)
      find_theme(name) || Theme.default
    end

    def self.find_theme(name)
      installed_themes.detect { |theme| theme.name.to_s == name.to_s }
    end

    extend Enumerable

    def self.each(&block)
      installed_themes.each(&block)
    end

    Theme = Struct.new(:name) do
      cattr_accessor :default_theme

      def self.from(theme)
        theme.kind_of?(Theme) ? theme : new(theme)
      end

      def self.default
        self.default_theme ||= from default_theme_name
      end

      def favicon_path
        @favicon_path ||= begin
          path = '/favicon.ico'
          path = "#{name}#{path}" unless default?
          path
        end
      end

      def main_stylesheet_path
        name
      end

      def default?
        self == self.class.default
      end

      def self.default_theme_name
        :default
      end

      include Comparable

      def <=>(other)
        name.to_s <=> other.name.to_s
      end
    end

    self.register Theme.default
  end
end

module ApplicationHelper
  def current_theme
    @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
    raise DefaultThemeNotFoundError, 'default theme was not found' unless @current_theme
    @current_theme
  end
end
