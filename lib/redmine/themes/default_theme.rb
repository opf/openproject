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

require 'redmine/themes/theme'

module Redmine
  module Themes
    class DefaultTheme < Redmine::Themes::Theme
      def identifier
        :default
      end

      def name
        'Default'
      end

      def assets_path
        @assets_path ||= Rails.root.join('app/assets').to_s
      end

      def stylesheet_manifest
        'default.css'
      end

      def assets_prefix
        ''
      end

      def overridden_images
        []
      end

      def default?
        true
      end

      def image_overridden?(source)
        false
      end

      def overridden_images_path
        nil
      end
    end
  end
end
