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

require 'singleton'
require 'open_project/themes/theme_finder'

module OpenProject
  module Themes
    class Theme
      class << self
        def inherited(subclass)
          # make all theme classes singletons
          subclass.send :include, Singleton

          # register the theme with the ThemeFinder
          ThemeFinder.register_theme(subclass.instance)
        end

        ##
        # Generate a new theme.
        # You may give an optional block which can
        # configure the newly created theme.
        # For example:
        # my_theme = Theme.new_theme do |theme|
        #   theme.identifier = "Fancy new theme"
        # end
        def new_theme
          Class.new(self).instance.tap do |theme|
            yield(theme) if block_given?
          end
        end

        def abstract!
          @abstract = true

          # tell ThemeFinder to forget the theme
          ThemeFinder.forget_theme(instance)

          # undefine methods responsible for creating instances
          singleton_class.send :remove_method, *[:new, :allocate, :instance]
        end

        def abstract?
          !!@abstract
        end
      end

      # 'OpenProject::Themes::GoofyTheme' => :'goofy'
      def identifier
        @identifier ||= base_name.underscore.dasherize.to_sym
      end
      attr_writer :identifier

      # 'OpenProject::Themes::GoofyTheme' => 'Goofy'
      def name
        @name ||= base_name.titleize
      end

      def stylesheet_manifest
        "#{identifier}.css"
      end

      def assets_prefix
        identifier.to_s
      end

      def assets_path
        @assets_path ||= Rails.root.join('app/assets').to_s
      end

      def overridden_images_path
        @overridden_images_path ||= File.join(assets_path, 'images', assets_prefix)
      end

      def overridden_images
        @overridden_images ||= \
          begin
            Dir.chdir(overridden_images_path) { Dir.glob('**/*') }
          rescue Errno::ENOENT # overridden_images_path missing
            []
          end.to_set
      end

      def image_overridden?(source)
        source.in?(overridden_images)
      end

      URI_REGEXP = %r{\A[-a-z]+://|\A(?:cid|data):|\A//}

      def path_to_image(source)
        return source if source =~ URI_REGEXP or source.starts_with?(?/)

        if image_overridden?(source)
          File.join(assets_prefix, source)
        else
          source
        end
      end

      include Comparable
      delegate :'<=>', :abstract?, to: :'self.class'

      include Singleton
      abstract!

      private

      def base_name
        self.class.to_s.gsub(/Theme\z/, '').demodulize
      end
    end
  end
end
