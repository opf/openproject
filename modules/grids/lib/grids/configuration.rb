#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Grids::Configuration
  attr_accessor :grid,
                :from_scope,
                :to_scope,
                :all_scopes

  def initialize(grid, from_scope, to_scope, all_scopes)
    self.grid = grid
    self.from_scope = from_scope
    self.to_scope = to_scope
    self.all_scopes = all_scopes
  end

  class << self
    def register_grid(grid,
                      from_scope,
                      to_scope,
                      all_scopes = to_scope)
      @grid_register ||= {}

      @grid_register[grid] = new(grid, from_scope, to_scope, all_scopes)
    end

    def registered_grids
      if @registered_grid_classes && @registered_grid_classes.length == @grid_register.length
        @registered_grid_classes
      else
        @registered_grid_classes = @grid_register.keys.map(&:constantize)
      end
    end

    def all_scopes
      all.map do |config|
        if config.all_scopes.is_a?(String) || config.all_scopes.is_a?(Symbol)
          url_helpers.send(config.to_scope)
        else
          config.all_scopes.call
        end
      end.compact
    end

    def all
      @grid_register.values
    end

    def attributes_from_scope(page)
      config = all.find do |config|
        config.from_scope.call(page)
      end

      if config
        config.from_scope.call(page)
      else
        { class: ::Grids::Grid }
      end
    end

    def class_from_scope(page)
      attributes_from_scope(page)[:class]
    end

    def to_scope(klass, path_parts)
      config = @grid_register[klass.name]

      return nil unless config

      url_helpers.send(config.to_scope, path_parts)
    end

    def registered_grid?(klass)
      registered_grids.include? klass
    end

    def register_widget(identifier, grid_classes)
      @widget_register ||= {}

      @widget_register[identifier] = Array(grid_classes)
    end

    def allowed_widget?(grid, identifier)
      grid_classes = registered_widget_by_identifier[identifier]

      (grid_classes || []).include?(grid)
    end

    protected

    def registered_widget_by_identifier
      if @registered_widget_by_identifier && @registered_widget_by_identifier.length == @widget_register.length
        @registered_widget_by_identifier
      else
        @registered_widget_by_identifier = @widget_register
                                           .map { |identifier, classes| [identifier, classes.map(&:constantize)] }
                                           .to_h
      end
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
