#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Grids::Configuration
  class << self
    def register_grid(grid,
                      klass)
      grid_register[grid] = klass
      @registered_grids = nil
    end

    def registered_grids
      @registered_grids ||= grid_register.keys.map(&:constantize)
    end

    def all_scopes
      all.map(&:all_scopes).flatten.compact
    end

    def writable_scopes
      all.map(&:writable_scopes).flatten.compact
    end

    def all
      grid_register.values
    end

    def attributes_from_scope(page)
      found_config = all.find do |config|
        config.from_scope(page)
      end

      if found_config
        found_config.from_scope(page)
      else
        { class: ::Grids::Grid }
      end
    end

    def defaults(klass)
      grid_register[klass.name]&.defaults
    end

    def class_from_scope(page)
      attributes_from_scope(page)[:class]
    end

    def to_scope(klass, path_parts)
      config = grid_register[klass.name]

      return nil unless config

      url_helpers.send(config.to_scope, path_parts)
    end

    def registered_grid?(klass)
      registered_grids.include? klass
    end

    def register_widget(identifier, grid_classes)
      @widget_register ||= Hash.new { |h, k| h[k] = [] }

      @widget_register[identifier] += Array(grid_classes)

      @registered_widget_by_identifier = nil
    end

    def allowed_widget?(grid, identifier, user, project)
      grid_classes = registered_widget_by_identifier[identifier]

      (grid_classes || []).include?(grid) &&
        widget_strategy(grid, identifier)&.allowed?(user, project)
    end

    def all_widget_identifiers(grid)
      registered_widget_by_identifier.select do |_, grid_classes|
        grid_classes.include?(grid)
      end.keys
    end

    def widget_strategy(grid, identifier)
      grid_register[grid.to_s]&.widget_strategy(identifier) || Grids::Configuration::WidgetStrategy
    end

    ##
    # Determines whether the given scope is writable by the current user
    def writable_scope?(scope)
      writable_scopes.include? scope
    end

    ##
    # Determine whether the given grid is writable
    #
    # @param grid Either a grid instance, or the grid class namespace (e.g., Grids::Grid)
    # @param user the current user to check against
    def writable?(grid, user)
      grid_register[grid.class.to_s]&.writable?(grid, user)
    end

    def validations(grid, mode)
      grid_register[grid.class.to_s]&.validations(mode) || []
    end

    protected

    def grid_register
      @grid_register ||= {}
    end

    def registered_widget_by_identifier
      @registered_widget_by_identifier ||= @widget_register
                                         .transform_values { |classes| classes.map(&:constantize) }
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
