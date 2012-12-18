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
require 'redmine/themes/theme'
require 'redmine/themes/default_theme' # always load the default theme

module Redmine
  module Themes
    class << self
      delegate :new_theme, :themes, :all, to: Theme

      def theme(identifier)
        Theme.fetch(identifier) { default_theme }
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

      def clear_themes
        Theme.clear
      end

      include Enumerable
      delegate :each, to: :themes
    end
  end
end

# add view helpers to application
require 'redmine/themes/view_helpers'

ActiveSupport.run_load_hooks(:themes)
