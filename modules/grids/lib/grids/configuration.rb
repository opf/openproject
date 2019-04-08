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
  class << self
    def register_grid(grid,
                      klass)
      grid_register[grid] = klass
    end

    def registered_grids
      if @registered_grid_classes && @registered_grid_classes.length == grid_register.length
        @registered_grid_classes
      else
        @registered_grid_classes = grid_register.keys.map(&:constantize)
      end
    end

    def all_scopes
      all.map(&:all_scopes).flatten.compact
    end

    def all
      grid_register.values
    end

    def attributes_from_scope(page)
      config = all.find do |config|
        config.from_scope(page)
      end

      if config
        config.from_scope(page)
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
      @widget_register ||= {}

      @widget_register[identifier] = Array(grid_classes)
    end

    def allowed_widget?(grid, identifier)
      grid_classes = registered_widget_by_identifier[identifier]

      (grid_classes || []).include?(grid)
    end

    ##
    # Determines whether the given scope is writable by the current user
    def writable_scope?(scope)
      all_scopes.include? scope
    end

    ##
    # Determine whether the given grid is writable
    #
    # @param grid Either a grid instance, or the grid class namespace (e.g., Grids::Grid)
    # @param user the current user to check against
    def writable?(grid, user)
      grid_register[grid.class.to_s]&.writable?(grid, user)
    end

    protected

    def grid_register
      @grid_register ||= {}
    end

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

  class Registration
    class << self
      def grid_class(name_string = nil)
        if name_string
          @grid_class = name_string
        end

        @grid_class
      end

      def to_scope(path = nil)
        if path
          @to_scope = path
        end

        @to_scope
      end

      def widgets(*widgets)
        if widgets.any?
          @widgets = widgets
        end

        @widgets
      end

      def defaults(hash = nil)
        # This is called during code load, which
        # may not have the table available.
        return unless Grids::Widget.table_exists?

        if hash
          @defaults = hash
        end

        params = @defaults.dup
        params[:widgets] = (params[:widgets] || []).map do |widget|
          Grids::Widget.new(widget)
        end

        params
      end

      def from_scope(_scope)
        raise NotImplementedError
      end

      def all_scopes
        Array(url_helpers.send(@to_scope))
      end

      def visible(_user = User.current)
        ::Grids::Grid
          .where(type: grid_class)
      end

      def writable?(_grid, _user)
        true
      end

      def register!
        unless @grid_class
          raise 'Need to define the grid class first. Use grid_class to do so.'
        end
        unless @widgets
          raise 'Need to define at least one widget first. Use widgets to do so.'
        end
        unless @to_scope
          raise 'Need to define a scope. Use to_scope to do so'
        end

        Grids::Configuration.register_grid(@grid_class, self)

        widgets.each do |widget|
          Grids::Configuration.register_widget(widget, @grid_class)
        end
      end

      private

      def url_helpers
        @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
      end
    end
  end
end
