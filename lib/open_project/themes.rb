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

      ##
      # Returns the currently active theme.
      # Params: options (Hash)
      #         - user: Users may define a theme in their preferences
      #                 if the user has done so, return that theme
      def current_theme(options = {})
        user_theme = Setting.user_may_override_theme? && options[:user].try(:pref)
                                                         .try(:[], :theme)
        theme(user_theme || application_theme_identifier)
      end

      def application_theme_identifier
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
