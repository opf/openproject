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

require 'redmine/themes'

module Redmine
  module Themes
    module ViewHelpers
      # returns the theme currently configured by the settings
      # if none is configured or one cannot be found it returns the default theme
      # which means this helper always returns a Redmine::Themes::Theme subclass
      def current_theme
        Redmine::Themes.current_theme
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
  include Redmine::Themes::ViewHelpers
end
