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
require 'singleton'
require 'active_support/descendants_tracker'

module Redmine
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
          theme.identifier = identifier if identifier
          theme
        end

        def themes
          @_themes ||= (descendants - abstract_themes).map(&:instance)
        end
        alias_method :all, :themes

        def registered_themes
          @_registered_themes ||= \
            each_with_object(Hash.new) do |theme, themes|
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
          singleton_class.send :remove_method, :new, :allocate, :instance
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

      # "Redmine::Themes::AwesomeTheme".demodulize.underscore.dasherize.to_sym => :"awesome-theme"
      def identifier
        @identifier ||= self.class.to_s.demodulize.underscore.dasherize.to_sym
      end
      attr_writer :identifier

      # "Redmine::Themes::AwesomeTheme".demodulize.titleize => "Awesome Theme"
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
          rescue Errno::ENOENT # overridden_images_path not there
            []
          end.to_set
      end

      def image_overridden?(source)
        overridden_images.include?(source)
      end

      URI_REGEXP = %r{^[-a-z]+://|^(?:cid|data):|^//}

      def path_to_image(source)
        return source if source =~ URI_REGEXP
        return source if source[0] == ?/

        if image_overridden?(source)
          "#{assets_prefix}/#{source}"
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
