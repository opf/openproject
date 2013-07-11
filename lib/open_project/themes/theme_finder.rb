#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Themes
    module ThemeFinder
      class << self
        def themes
          @_themes ||= []
        end
        alias_method :all, :themes

        def registered_themes
          @_registered_themes ||= \
            themes.each_with_object({}) do |theme, themes|
              themes[theme.identifier] = theme
            end
        end
        delegate :fetch, to: :registered_themes

        def register_theme(theme)
          self.themes << theme
          clear_cache

          # register the theme's stylesheet manifest with rails' asset pipeline
          # we need to wrap the call to #stylesheet_manifest in a Proc,
          # because when this code is executed the theme instance (theme) hasn't had
          # a chance to override the method yet
          Rails.application.config.assets.precompile << Proc.new {
            theme.stylesheet_manifest unless theme.abstract?
          }
        end

        def forget_theme(theme)
          themes.delete(theme)
          clear_cache
        end

        def clear_themes
          themes.clear
          clear_cache
        end

        def clear_cache
          @_registered_themes = nil
        end

        include Enumerable
        delegate :each, to: :themes
      end
    end
  end
end
