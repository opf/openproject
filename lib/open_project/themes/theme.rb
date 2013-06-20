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
require 'singleton'
require 'active_support/descendants_tracker'

module OpenProject
  module Themes
    class Theme
      class SubclassResponsibility < StandardError
      end

      class << self
        include ActiveSupport::DescendantsTracker

        def inherited(base)
          super                          # call to ActiveSupport::DescendantsTracker
          base.send :include, Singleton  # make all theme classes singletons
          clear_cache                    # clear the themes cache

          # register the theme's stylesheet manifest with rails' asset pipeline
          # we need to wrap the call to #stylesheet_manifest in a Proc,
          # because when this code is executed the theme class (base) hasn't had
          # a chance to override the method yet
          Rails.application.config.assets.precompile << Proc.new {
            base.instance.stylesheet_manifest unless base.abstract?
          }
        end

        def new_theme(identifier = nil)
          theme = Class.new(self).instance
          theme.identifier = identifier
          theme
        end

        def themes
          @_themes ||= (descendants - abstract_themes).map(&:instance)
        end
        alias_method :all, :themes

        def registered_themes
          @_registered_themes ||= \
            themes.each_with_object(Hash.new) do |theme, themes|
              themes[theme.identifier] = theme
            end
        end
        delegate :fetch, to: :registered_themes

        def clear
          direct_descendants.clear && clear_cache
        end

        def clear_cache
          @_themes = @_registered_themes = nil
        end

        def abstract!
          Theme.abstract_themes << self

          # undefine methods responsible for creating instances
          singleton_class.send :remove_method, *[:new, :allocate, :instance]
        end

        def abstract?
          self.in?(Theme.abstract_themes)
        end

        def abstract_themes
          @_abstract_themes ||= Array.new
        end

        include Enumerable
        delegate :each, to: :themes
      end

      # 'OpenProject::Themes::GoofyTheme' => :'goofy-theme'
      def identifier
        @identifier ||= self.class.to_s.demodulize.underscore.dasherize.to_sym
      end
      attr_writer :identifier

      # 'OpenProject::Themes::GoofyTheme' => 'Goofy Theme'
      def name
        @name ||= self.class.to_s.demodulize.titleize
      end

      def stylesheet_manifest
        "#{identifier}.css"
      end

      def assets_prefix
        identifier.to_s
      end

      def assets_path
        raise SubclassResponsibility, "override this method to point to your theme's assets folder"
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

      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      def path_to_image(source)
        return source if source =~ URI_REGEXP
        return source if source[0] == ?/

        if image_overridden?(source)
          File.join(assets_prefix, source)
        else
          source
        end
      end

      def default?
        false
      end

      include Comparable
      delegate :'<=>', to: :'self.class'

      include Singleton
      abstract!
    end
  end
end
