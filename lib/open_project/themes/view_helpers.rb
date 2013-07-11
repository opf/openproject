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

require 'open_project/themes'

module OpenProject
  module Themes
    module ViewHelpers
      # returns the theme currently configured by the settings
      # if none is configured or one cannot be found it returns the default theme
      # which means this helper always returns a OpenProject::Themes::Theme subclass
      def current_theme
        OpenProject::Themes.current_theme
      end

      # overrides image_tag defined in ActionView::Helpers::AssetTagHelpers (Rails 4)
      # to be aware of the current theme
      #
      # it prepends the theme path to any image path the theme overrides/overwrites
      # it doesn't do it for the default theme, though
      #
      # NOTE: it takes an optional options hash since Rails 4
      #
      # ALSO NOTE: most image helpers (like favicon_link_tag) delegate to this method
      # this hopefully makes it a good point to patch the theme behaviour for images
      def image_path(source) # , options = {}
        super current_theme.path_to_image(source) # , options
      end
      alias_method :path_to_image, :image_path # aliased to avoid conflicts with an image_path named route
    end
  end
end

module ApplicationHelper
  # including a module is way better than defining methods directly in the application helper's module
  # it plays nicely with inheritence and it will show up in ApplicationHelper.ancestors list
  include OpenProject::Themes::ViewHelpers
end
