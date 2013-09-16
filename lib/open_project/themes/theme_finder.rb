#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
