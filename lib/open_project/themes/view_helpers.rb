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

require 'open_project/themes'

module OpenProject
  module Themes
    module ViewHelpers
      # returns the theme currently configured by the settings
      # if none is configured or one cannot be found it returns the default theme
      # which means this helper always returns a OpenProject::Themes::Theme subclass
      def current_theme
        OpenProject::Themes.current_theme user: User.current
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
  # it plays nicely with inheritance and it will show up in ApplicationHelper.ancestors list
  include OpenProject::Themes::ViewHelpers
end
