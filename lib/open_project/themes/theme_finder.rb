#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
        ##
        # A list of all available themes.
        # aliased to :all
        def themes
          @_themes ||= []
        end
        alias_method :all, :themes

        ##
        # Returns a hash with theme identifiers as keys,
        # pointing to their Theme objects.
        def registered_themes
          @_registered_themes ||= \
            themes.each_with_object({}.with_indifferent_access) do |theme, themes|
              themes[theme.identifier] = theme
            end
        end
        delegate :fetch, to: :registered_themes

        ##
        # Registers a theme instance, so that it is listed
        # in `themes` and `registered_themes`.
        # Every Theme, which is subclassed from OpenProject::Themes::Theme
        # automatically registers itself using this method.
        #
        # params: theme (a OpenProject::Themes::Theme instance)
        def register_theme(theme)
          themes << theme
          clear_cache

          # register the theme's stylesheet manifest with rails' asset pipeline
          # we need to wrap the call to #stylesheet_manifest in a Proc,
          # because when this code is executed the theme instance (theme) hasn't had
          # a chance to override the method yet
          Rails.application.config.assets.precompile << -> (path) {
            return if theme.abstract?

            theme.stylesheet_manifest == path
          }
        end

        def forget_theme(theme)
          remove_asset_pipeline_proc(theme)
          themes.delete(theme)
          clear_cache
        end

        def clear_themes
          remove_all_asset_pipeline_procs
          themes.clear
          clear_cache
        end

        include Enumerable
        delegate :each, to: :themes

        private

        def remove_asset_pipeline_proc(theme)
          Rails.application.config.assets.precompile.delete_if do |item|
            item.is_a?(Proc) and extract_theme(item) == theme
          end
        end

        def remove_all_asset_pipeline_procs
          Rails.application.config.assets.precompile.delete_if do |item|
            item.is_a?(Proc) and extract_theme(item).is_a?(OpenProject::Themes::Theme)
          end
        end

        def extract_theme(proc)
          proc.binding.eval('theme if local_variables.include? :theme')
        end

        def clear_cache
          @_registered_themes = nil
        end
      end
    end
  end
end
