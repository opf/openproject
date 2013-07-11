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

require 'open_project/themes/theme'
require 'open_project/themes/theme_finder'
require 'open_project/themes/default_theme' # always load the default theme

module OpenProject
  module Themes
    class << self
      delegate :new_theme, to: Theme
      delegate :all, :themes, :clear_themes, to: ThemeFinder

      def theme(identifier)
        ThemeFinder.fetch(identifier) { default_theme }
      end

      def default_theme
        DefaultTheme.instance
      end

      def current_theme
        theme(current_theme_identifier)
      end

      def current_theme_identifier
        Setting.ui_theme.to_s.to_sym.presence
      end

      include Enumerable
      delegate :each, to: :themes
    end
  end
end

# add view helpers to application
require 'open_project/themes/view_helpers'

ActiveSupport.run_load_hooks(:themes)
